import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_config.dart';
import '../network/auth_storage.dart';

typedef TokenProvider = Future<String?> Function();
typedef TokenRefresher = Future<bool> Function();

/// Central Dio HTTP client for admin API calls.
/// Uses TokenService for JWT, with 401 → refresh → retry logic.
class AdminApiClient {
  AdminApiClient({
    required TokenProvider tokenProvider,
    required TokenRefresher tokenRefresher,
    required void Function() onUnauthorized,
  })  : _tokenProvider = tokenProvider,
        _tokenRefresher = tokenRefresher,
        _onUnauthorized = onUnauthorized,
        _dio = Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 30),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenProvider();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onError: (DioException e, handler) async {
          // 401 = token expired/invalid (backend returns this when JWT validation fails).
          // 403 = Access Denied from PreAuthorize when token was expired (backend used to return
          // this before JwtAuthenticationFilter returned 401). Retry after refresh for both.
          final status = e.response?.statusCode;
          if (status == 401 || status == 403) {
            if (kDebugMode) {
              // ignore: avoid_print
              print('[AdminApiClient] $status → attempting token refresh...');
            }

            final refreshed = await _refreshWithQueue();

            if (refreshed) {
              final token = await _tokenProvider();
              if (token != null) {
                e.requestOptions.headers['Authorization'] = 'Bearer $token';
                try {
                  final response = await _dio.fetch(e.requestOptions);
                  return handler.resolve(response);
                } catch (_) {
                  return handler.next(e);
                }
              }
            }

            if (kDebugMode) {
              // ignore: avoid_print
              print('[AdminApiClient] Refresh failed → logging out');
            }
            _onUnauthorized();
          }

          if (kDebugMode) {
            // ignore: avoid_print
            print(
              '[AdminApiClient] ${e.requestOptions.method} ${e.requestOptions.path} '
              '→ ${e.response?.statusCode}: ${e.message}',
            );
          }
          handler.next(e);
        },
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (o) => debugPrint('[AdminApi] $o'),
      ),
    );
  }

  final TokenProvider _tokenProvider;
  final TokenRefresher _tokenRefresher;
  final void Function() _onUnauthorized;
  final Dio _dio;

  bool _isRefreshing = false;
  final List<Completer<bool>> _refreshWaiters = [];

  Future<bool> _refreshWithQueue() async {
    if (_isRefreshing) {
      final completer = Completer<bool>();
      _refreshWaiters.add(completer);
      return completer.future;
    }

    _isRefreshing = true;
    bool refreshed = false;
    try {
      refreshed = await _tokenRefresher();
      return refreshed;
    } finally {
      _isRefreshing = false;
      final waiters = List<Completer<bool>>.from(_refreshWaiters);
      _refreshWaiters.clear();
      for (final waiter in waiters) {
        if (!waiter.isCompleted) waiter.complete(refreshed);
      }
    }
  }

  Dio get dio => _dio;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: queryParameters,
    );
    return _unwrap(response.data);
  }

  Future<Map<String, dynamic>> post(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: body,
    );
    return _unwrap(response.data);
  }

  Future<Map<String, dynamic>> put(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final response = await _dio.put<Map<String, dynamic>>(
      path,
      data: body,
    );
    return _unwrap(response.data);
  }

  Future<Map<String, dynamic>> patch(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      path,
      data: body,
    );
    return _unwrap(response.data);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final response = await _dio.delete<Map<String, dynamic>>(path);
    return _unwrap(response.data);
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic>? raw) {
    if (raw == null) return {};
    if (raw['data'] is Map<String, dynamic>) {
      return raw['data'] as Map<String, dynamic>;
    }
    return raw;
  }

  Future<List<dynamic>> getList(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: queryParameters,
    );
    final raw = response.data;
    if (raw == null) return [];
    final data = raw['data'];
    if (data is List) return data;
    return [];
  }

}

// ── Provider ──────────────────────────────────────────────────────────────────

final adminApiClientProvider = Provider<AdminApiClient>((ref) {
  final tokenService = ref.watch(tokenServiceProvider);
  return AdminApiClient(
    tokenProvider: () => tokenService.getValidAccessToken(),
    tokenRefresher: () async {
      final ok = await tokenService.refreshTokens();
      if (ok) ref.invalidate(authTokenProvider);
      return ok;
    },
    onUnauthorized: () => ref.read(authTokenProvider.notifier).clearToken(),
  );
});
