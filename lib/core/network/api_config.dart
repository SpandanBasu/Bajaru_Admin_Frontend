import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central API configuration for the admin app.
///
/// Reads API_BASE_URL from .env if available, otherwise falls back to default.
///
/// Use a base ending in `/api/v1` or `/api/v1/` (no path after the version),
/// e.g. `http://10.0.2.2:8080/api/v1`. [ApiPaths] entries start with `/` so Dio
/// does `baseUrl + path` → correct full URL.
abstract class ApiConfig {
  static String get baseUrl {
    final url = dotenv.env['API_BASE_URL'] ?? dotenv.env['BASE_URL'];
    if (url != null && url.isNotEmpty) return url;
    return 'http://10.0.2.2:8080/api/v1';
  }
}
