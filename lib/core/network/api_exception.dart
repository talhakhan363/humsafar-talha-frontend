/// Models the standard error envelope from SDS Section 18 / 11.2: every
/// API error response carries a machine-readable `code`, a human-readable
/// `message`, and an optional `details` object for field-level validation
/// errors.
///
/// This shape is spec-grounded, not guessed — it's the one thing about
/// Abdullah's API error responses that's already locked in the SDS, even
/// before his actual endpoints exist. The concrete `details` contents for
/// a given endpoint will need checking against his real responses once
/// Task 2.5 wires this up for real.
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.details,
    this.statusCode,
  });

  final String code;
  final String message;
  final Map<String, dynamic>? details;
  final int? statusCode;

  factory ApiException.fromJson(Map<String, dynamic> json, {int? statusCode}) {
    return ApiException(
      code: json['code'] as String? ?? 'unknown_error',
      message: json['message'] as String? ?? 'Something went wrong.',
      details: json['details'] as Map<String, dynamic>?,
      statusCode: statusCode,
    );
  }

  /// Used when the server didn't return the expected envelope shape at all
  /// (a raw 500, a network failure, a timeout) — keeps every call site
  /// dealing with one exception type instead of guessing what shape came
  /// back.
  factory ApiException.unexpected(String message, {int? statusCode}) {
    return ApiException(code: 'unexpected_error', message: message, statusCode: statusCode);
  }

  @override
  String toString() => 'ApiException($code, status: $statusCode): $message';
}
