/// Base exception for all domain and application errors.
abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Network-related failures (timeouts, no internet connection, server error responses).
class NetworkException extends AppException {
  final int? statusCode;

  const NetworkException(
    super.message, {
    this.statusCode,
    super.code,
  });
}

/// Authentication and session failures (invalid credentials, expired JWT tokens, unauthorized).
class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

/// SMS quota and rate-limiting limits reached.
class QuotaException extends AppException {
  final int limit;
  final int sent;

  const QuotaException(
    super.message, {
    required this.limit,
    required this.sent,
    super.code,
  });
}

/// Native Android Telephony and SIM card failures.
class TelephonyException extends AppException {
  const TelephonyException(super.message, {super.code});
}

/// Input validation errors.
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code});
}
