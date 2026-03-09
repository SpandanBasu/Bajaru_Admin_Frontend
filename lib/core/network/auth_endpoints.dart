import 'api_config.dart';

/// Auth-related API endpoints (shared across rider and admin apps).
class AuthEndpoints {
  AuthEndpoints._();

  static String get baseUrl => ApiConfig.baseUrl;

  static const String sendOtp = '/api/auth/whatsapp/otp';
  static const String verifyOtp = '/api/auth/whatsapp/verify';
  static const String truecallerLogin = '/api/auth/truecaller';
  static const String refreshToken = '/api/auth/refresh';
}
