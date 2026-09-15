import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_app/core/errors/app_exceptions.dart';
import 'package:sms_app/shared/widgets/error_handler.dart';

void main() {
  group('ErrorHandler Tests', () {
    test('Handles QuotaException accurately', () {
      const exception = QuotaException(
        'Daily SMS limit reached for SIM 1 (100/100)',
        limit: 100,
        sent: 100,
      );

      final message = ErrorHandler.getUserFriendlyMessage(exception);
      expect(message, equals('Daily SMS limit reached for SIM 1 (100/100)'));
    });

    test('Handles TelephonyException accurately', () {
      const exception = TelephonyException('No active SIM card detected');

      final message = ErrorHandler.getUserFriendlyMessage(exception);
      expect(message, equals('No active SIM card detected'));
    });

    test('Handles AuthException accurately', () {
      const exception = AuthException('Invalid email or password');

      final message = ErrorHandler.getUserFriendlyMessage(exception);
      expect(message, equals('Invalid email or password'));
      expect(ErrorHandler.isAuthError(exception), isTrue);
    });

    test('Handles NetworkException accurately', () {
      const exception = NetworkException(
        'Unable to connect to server. Please check your internet connection.',
        statusCode: 503,
      );

      final message = ErrorHandler.getUserFriendlyMessage(exception);
      expect(
        message,
        equals('Unable to connect to server. Please check your internet connection.'),
      );
      expect(ErrorHandler.isNetworkError(exception), isTrue);
    });

    test('Handles ValidationException accurately', () {
      const exception = ValidationException('Mobile number must be 10 digits');

      final message = ErrorHandler.getUserFriendlyMessage(exception);
      expect(message, equals('Mobile number must be 10 digits'));
    });

    test('Handles null error gracefully', () {
      final message = ErrorHandler.getUserFriendlyMessage(null);
      expect(message, equals('An unknown error occurred.'));
    });

    test('Handles raw String error', () {
      final message = ErrorHandler.getUserFriendlyMessage('Custom error string');
      expect(message, equals('Custom error string'));
    });

    test('Handles Dio connection timeout', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );

      final message = ErrorHandler.getUserFriendlyMessage(dioException);
      expect(message, contains('Connection timeout'));
      expect(ErrorHandler.isNetworkError(dioException), isTrue);
    });

    test('Handles Dio connection error', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionError,
      );

      final message = ErrorHandler.getUserFriendlyMessage(dioException);
      expect(message, contains('Unable to connect to server'));
      expect(ErrorHandler.isNetworkError(dioException), isTrue);
    });

    test('Handles Dio badResponse with backend JSON message', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 400,
          data: {'message': 'Device limit reached for this account'},
        ),
      );

      final message = ErrorHandler.getUserFriendlyMessage(dioException);
      expect(message, equals('Device limit reached for this account'));
    });

    test('Handles Dio badResponse HTTP 401 without message body', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
        ),
      );

      final message = ErrorHandler.getUserFriendlyMessage(dioException);
      expect(message, contains('Session expired'));
      expect(ErrorHandler.isAuthError(dioException), isTrue);
    });

    test('Handles Dio badResponse HTTP 403', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 403,
        ),
      );

      final message = ErrorHandler.getUserFriendlyMessage(dioException);
      expect(message, contains("permission"));
    });

    test('Handles Dio badResponse HTTP 500', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 500,
        ),
      );

      final message = ErrorHandler.getUserFriendlyMessage(dioException);
      expect(message, contains('Server error'));
    });
  });
}
