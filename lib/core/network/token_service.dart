import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../api/api_paths.dart';
import 'auth_tokens.dart';

// ── Storage keys (admin-specific) ─────────────────────────────────────────────

const _accessKey = 'admin_access_token';
const _refreshKey = 'admin_refresh_token';
const _expiryKey = 'admin_token_expiry';

// ── Token service ─────────────────────────────────────────────────────────────

/// Manages authentication tokens for the admin app.
///
/// - Stores access + refresh tokens after login
/// - Refreshes tokens when expired or about to expire
/// - Uses raw HTTP for refresh (avoids circular dependency with Dio/ApiClient)
class TokenService {
  final FlutterSecureStorage _storage;
  final String _apiBaseUrl;

  AuthTokens? _cachedTokens;
  Future<bool>? _refreshInFlight;

  TokenService({
    FlutterSecureStorage? storage,
    required String apiBaseUrl,
  })  : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        ),
        _apiBaseUrl = apiBaseUrl;

  // ── Save / load ─────────────────────────────────────────────────────────────

  Future<void> saveTokens(AuthTokens tokens) async {
    await Future.wait([
      _storage.write(key: _accessKey, value: tokens.accessToken),
      _storage.write(key: _refreshKey, value: tokens.refreshToken),
      _storage.write(
        key: _expiryKey,
        value: tokens.expiresAt.millisecondsSinceEpoch.toString(),
      ),
    ]);
    _cachedTokens = tokens;
    debugPrint('TokenService: Saved tokens (expires: ${tokens.expiresAt})');
  }

  Future<AuthTokens?> getTokens() async {
    if (_cachedTokens != null) return _cachedTokens;

    final access = await _storage.read(key: _accessKey);
    final refresh = await _storage.read(key: _refreshKey);
    final expiryStr = await _storage.read(key: _expiryKey);

    if (access == null || refresh == null || expiryStr == null) return null;

    final expiresAt = DateTime.fromMillisecondsSinceEpoch(int.parse(expiryStr));
    _cachedTokens = AuthTokens(
      accessToken: access,
      refreshToken: refresh,
      expiresAt: expiresAt,
    );
    return _cachedTokens;
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessKey),
      _storage.delete(key: _refreshKey),
      _storage.delete(key: _expiryKey),
    ]);
    _cachedTokens = null;
    debugPrint('TokenService: Cleared all tokens');
  }

  // ── Valid access token (with proactive refresh) ─────────────────────────────

  Future<String?> getValidAccessToken() async {
    final tokens = await getTokens();
    if (tokens == null) return null;

    if (tokens.isExpired || tokens.needsRefresh) {
      debugPrint(
        'TokenService: Token ${tokens.isExpired ? "expired" : "expiring soon"}, refreshing...',
      );
      final refreshed = await refreshTokens();
      if (!refreshed) return null;
      return _cachedTokens?.accessToken;
    }

    return tokens.accessToken;
  }

  // ── Refresh (raw HTTP) ──────────────────────────────────────────────────────

  Future<bool> refreshTokens() async {
    if (_refreshInFlight != null) {
      return _refreshInFlight!;
    }

    final inFlight = _refreshTokensInternal();
    _refreshInFlight = inFlight;
    try {
      return await inFlight;
    } finally {
      _refreshInFlight = null;
    }
  }

  Future<bool> _refreshTokensInternal() async {
    final tokens = await getTokens();
    if (tokens == null) {
      debugPrint('TokenService: No tokens to refresh');
      return false;
    }

    try {
      final uri = Uri.parse('$_apiBaseUrl${ApiPaths.refreshToken}');
      debugPrint('TokenService: POST $uri (X-Refresh-Token)');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Refresh-Token': tokens.refreshToken,
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final accessToken =
            (body['accessToken'] as String?) ?? (body['token'] as String?) ?? '';
        final refreshToken = body['refreshToken'] as String? ?? '';
        if (accessToken.isEmpty || refreshToken.isEmpty) {
          debugPrint('TokenService: Refresh payload missing token values');
          return false;
        }
        final expiresInSeconds = (body['expiresIn'] as num?)?.toInt() ?? 15 * 60;

        final newTokens = AuthTokens.fromDuration(
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresIn: Duration(seconds: expiresInSeconds),
        );
        await saveTokens(newTokens);
        debugPrint('TokenService: Tokens refreshed successfully');
        return true;
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint(
          'TokenService: Refresh rejected (${response.statusCode}). Clearing session.',
        );
        await clearTokens();
      } else {
        debugPrint('TokenService: Refresh failed - HTTP ${response.statusCode}');
      }
      return false;
    } catch (e) {
      debugPrint('TokenService: Refresh error - $e');
      return false;
    }
  }
}
