import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_config.dart';
import 'auth_tokens.dart';
import 'token_service.dart';

// ── Token service provider ────────────────────────────────────────────────────

final tokenServiceProvider = Provider<TokenService>((ref) {
  return TokenService(apiBaseUrl: ApiConfig.baseUrl);
});

// ── Auth token notifier ───────────────────────────────────────────────────────
//
// Exposes current access token for the API client.
// On login: [setTokens] saves both access + refresh via TokenService.
// On 401 + failed refresh: ApiClient calls [clearToken] → shows login screen.
// Build uses [getValidAccessToken] so proactive refresh runs when token expires.

class AuthTokenNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final service = ref.read(tokenServiceProvider);
    return service.getValidAccessToken();
  }

  /// Save both tokens after login (Truecaller or WhatsApp OTP).
  Future<void> setTokens(
    String accessToken,
    String refreshToken, {
    int? expiresInSeconds,
  }) async {
    final service = ref.read(tokenServiceProvider);
    final safeSeconds = (expiresInSeconds != null && expiresInSeconds > 0)
        ? expiresInSeconds
        : 15 * 60;
    final tokens = AuthTokens.fromDuration(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: Duration(seconds: safeSeconds),
    );
    await service.saveTokens(tokens);
    state = AsyncData(accessToken);
  }

  Future<void> clearToken() async {
    final service = ref.read(tokenServiceProvider);
    await service.clearTokens();
    state = const AsyncData(null);
  }
}

final authTokenProvider =
    AsyncNotifierProvider<AuthTokenNotifier, String?>(AuthTokenNotifier.new);
