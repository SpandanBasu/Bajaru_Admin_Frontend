/// Authentication tokens model for the admin app.
///
/// Contains both access and refresh tokens with expiry tracking.
class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Proactive refresh when within 2 minutes of expiry.
  bool get needsRefresh => DateTime.now().isAfter(
        expiresAt.subtract(const Duration(minutes: 2)),
      );

  factory AuthTokens.fromDuration({
    required String accessToken,
    required String refreshToken,
    required Duration expiresIn,
  }) {
    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: DateTime.now().add(expiresIn),
    );
  }

  factory AuthTokens.withDefaultExpiry({
    required String accessToken,
    required String refreshToken,
  }) {
    return AuthTokens.fromDuration(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: const Duration(minutes: 15),
    );
  }
}
