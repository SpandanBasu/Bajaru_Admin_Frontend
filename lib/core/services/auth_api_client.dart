import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_config.dart';

/// Simple Dio client for auth endpoints (sendOtp, verifyOtp, truecallerLogin).
/// No token required — used before login.
class AuthApiClient {
  late final Dio _dio;

  AuthApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  Future<Response<Map<String, dynamic>>> post(
    String path, {
    Object? data,
  }) =>
      _dio.post<Map<String, dynamic>>(path, data: data);
}

final authApiClientProvider = Provider<AuthApiClient>((ref) {
  return AuthApiClient();
});
