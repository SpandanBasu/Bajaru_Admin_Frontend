import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central API configuration for the admin app.
///
/// Reads API_BASE_URL from .env if available, otherwise falls back to default.
/// For Android emulator use http://10.0.2.2:8080
abstract class ApiConfig {
  static String get baseUrl {
    final url = dotenv.env['API_BASE_URL'] ?? dotenv.env['BASE_URL'];
    if (url != null && url.isNotEmpty) return url;
    return 'http://10.0.2.2:8080';
  }
}
