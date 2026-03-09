/// Exception thrown when API calls fail.
class AppApiException implements Exception {
  final String message;
  const AppApiException(this.message);

  @override
  String toString() => message;
}
