/// Normalized API error used across the app.
///
/// The raw server payload (`{ error: '...' }`) is mapped to a user-friendly
/// message here; raw server errors are never shown to users directly.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final bool isNetworkError;
  final bool isTimeout;
  final bool isUnauthorized;

  const ApiException({
    required this.message,
    this.statusCode,
    this.isNetworkError = false,
    this.isTimeout = false,
    this.isUnauthorized = false,
  });

  /// Maps an HTTP status code to a short, user-friendly summary.
  static String friendlyMessageFor(int statusCode) => switch (statusCode) {
        400 => 'The request was not valid. Please check your details.',
        401 => 'Your session has expired. Please log in again.',
        403 => 'You do not have permission to do that.',
        404 => 'The item you requested was not found.',
        409 => 'There was a conflict with the current data.',
        422 => 'The details provided could not be processed.',
        500 => 'Something went wrong on our side. Please try again.',
        _ => 'Something went wrong. Please try again.',
      };

  @override
  String toString() => message;
}
