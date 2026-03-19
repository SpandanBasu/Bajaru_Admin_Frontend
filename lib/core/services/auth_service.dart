import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:truecaller_sdk/truecaller_sdk.dart';
import 'package:uuid/uuid.dart';

import '../exceptions/app_api_exception.dart';
import '../models/admin_profile.dart';
import '../network/auth_endpoints.dart';
import 'auth_api_client.dart';

// ── Truecaller login result ────────────────────────────────────────────────────

class TruecallerLoginResult {
  final bool success;
  final String? authorizationCode;
  final String? errorMessage;

  const TruecallerLoginResult._({
    required this.success,
    this.authorizationCode,
    this.errorMessage,
  });

  factory TruecallerLoginResult.success(String code) =>
      TruecallerLoginResult._(success: true, authorizationCode: code);

  factory TruecallerLoginResult.failure(String? msg) =>
      TruecallerLoginResult._(success: false, errorMessage: msg);

  factory TruecallerLoginResult.notAvailable() =>
      const TruecallerLoginResult._(success: false);
}

// ── Auth service ──────────────────────────────────────────────────────────────

class AuthService {
  final AuthApiClient _client;

  AuthService(this._client);

  bool _isTruecallerAvailable = false;
  String? _oauthState;
  String? _codeVerifier;
  StreamSubscription<TcSdkCallback>? _tcStreamSubscription;

  bool get isTruecallerAvailable => _isTruecallerAvailable;

  // ── POST /api/auth/sms/otp ──────────────────────────────────────────────────

  Future<void> sendOtp(String phoneNumber) async {
    try {
      final res = await _client.post(
        AuthEndpoints.sendOtp,
        data: {'phoneNumber': phoneNumber},
      );
      if (res.data?['success'] == false) {
        throw AppApiException(
          res.data?['message'] as String? ?? 'Failed to send OTP.',
        );
      }
    } on DioException catch (e) {
      throw _toEx(e);
    } catch (e) {
      throw AppApiException('Failed to send OTP: $e');
    }
  }

  // ── POST /api/auth/sms/verify ───────────────────────────────────────────────

  Future<({
    String accessToken,
    String refreshToken,
    int expiresIn,
    AdminProfile profile,
  })> verifyOtp(
    String phoneNumber,
    String otp,
  ) async {
    try {
      final res = await _client.post(
        AuthEndpoints.verifyOtp,
        data: {
          'phoneNumber': phoneNumber,
          'otp': otp,
          'role': 'ADMIN',
        },
      );
      return _parseAuthResponse(res.data);
    } on DioException catch (e) {
      throw _toEx(e);
    } on AppApiException {
      rethrow;
    } catch (e) {
      throw AppApiException('Failed to parse login response: $e');
    }
  }

  // ── Truecaller — Initialize ──────────────────────────────────────────────────

  Future<void> initializeTruecallerForLogin() async {
    try {
      TcSdk.initializeSDK(sdkOption: TcSdkOptions.OPTION_VERIFY_ONLY_TC_USERS);
      _isTruecallerAvailable = await TcSdk.isOAuthFlowUsable;
      debugPrint('AuthService: Truecaller available = $_isTruecallerAvailable');
    } catch (e) {
      debugPrint('AuthService: Truecaller init error – $e');
      _isTruecallerAvailable = false;
    }
  }

  // ── Truecaller — Trigger OAuth one-tap ─────────────────────────────────────────

  Future<TruecallerLoginResult> loginWithTruecaller() async {
    if (!_isTruecallerAvailable) return TruecallerLoginResult.notAvailable();

    try {
      _oauthState = const Uuid().v4();
      TcSdk.setOAuthState(_oauthState!);

      TcSdk.setOAuthScopes([
        'offline_access',
        'openid',
        'phone',
        'profile',
        'email',
        'address',
      ]);

      _codeVerifier = await TcSdk.generateRandomCodeVerifier;
      final codeChallenge = await TcSdk.generateCodeChallenge(_codeVerifier!);
      TcSdk.setCodeChallenge(codeChallenge);

      final completer = Completer<TruecallerLoginResult>();

      await _tcStreamSubscription?.cancel();
      _tcStreamSubscription = TcSdk.streamCallbackData.listen(
        (tcSdkCallback) {
          if (completer.isCompleted) return;
          switch (tcSdkCallback.result) {
            case TcSdkCallbackResult.success:
              final oauthData = tcSdkCallback.tcOAuthData;
              if (oauthData != null) {
                if (oauthData.state != _oauthState) {
                  completer.complete(
                    TruecallerLoginResult.failure('State mismatch – possible CSRF'),
                  );
                  return;
                }
                completer.complete(
                  TruecallerLoginResult.success(oauthData.authorizationCode),
                );
              } else {
                completer.complete(
                  TruecallerLoginResult.failure('No OAuth data received'),
                );
              }
            case TcSdkCallbackResult.failure:
              final err = tcSdkCallback.error;
              debugPrint('AuthService: Truecaller failure – ${err?.code}: ${err?.message}');
              completer.complete(TruecallerLoginResult.failure(err?.message));
            case TcSdkCallbackResult.verification:
              completer.complete(TruecallerLoginResult.notAvailable());
            default:
              completer.complete(TruecallerLoginResult.notAvailable());
          }
        },
        onError: (e) {
          if (!completer.isCompleted) {
            completer.complete(TruecallerLoginResult.failure(e.toString()));
          }
        },
      );

      TcSdk.getAuthorizationCode;

      return await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () => TruecallerLoginResult.failure('Authorization timed out'),
      );
    } catch (e) {
      debugPrint('AuthService: Truecaller login error – $e');
      return TruecallerLoginResult.failure(e.toString());
    }
  }

  // ── Truecaller — Exchange auth code with backend ─────────────────────────────

  Future<({
    String accessToken,
    String refreshToken,
    int expiresIn,
    AdminProfile profile,
  })> verifyTruecallerCode(
    String authorizationCode,
  ) async {
    if (_codeVerifier == null) {
      throw const AppApiException('Auth session expired. Please try again.');
    }
    try {
      final res = await _client.post(
        AuthEndpoints.truecallerLogin,
        data: {
          'code': authorizationCode,
          'codeVerifier': _codeVerifier,
          'role': 'ADMIN',
        },
      );
      return _parseAuthResponse(res.data);
    } on DioException catch (e) {
      throw _toEx(e);
    } on AppApiException {
      rethrow;
    } catch (e) {
      throw AppApiException('Failed to parse Truecaller response: $e');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  ({
    String accessToken,
    String refreshToken,
    int expiresIn,
    AdminProfile profile,
  }) _parseAuthResponse(dynamic data) {
    final auth = data as Map<String, dynamic>?;
    if (auth == null || auth['accessToken'] == null) {
      throw const AppApiException('Invalid response from server.');
    }
    final userMap = auth['user'] as Map<String, dynamic>;
    return (
      accessToken: auth['accessToken'] as String,
      refreshToken: auth['refreshToken'] as String? ?? '',
      expiresIn: (auth['expiresIn'] as num?)?.toInt() ?? 15 * 60,
      profile: AdminProfile.fromJson(userMap),
    );
  }

  static AppApiException _toEx(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const AppApiException('Request timed out. Check your connection.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return const AppApiException('Cannot reach server. Check your network.');
    }
    final status = e.response?.statusCode;
    final body = e.response?.data as Map<String, dynamic>?;
    if (status == 401) return const AppApiException('Invalid OTP or session expired.');
    if (status == 400) {
      return AppApiException(body?['message'] as String? ?? 'Invalid request.');
    }
    return AppApiException(
      body?['message'] as String? ?? 'Unexpected error (${status ?? 'unknown'}).',
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(authApiClientProvider));
});
