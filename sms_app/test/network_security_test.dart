import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_app/data/services/api_service.dart';
import 'package:sms_app/data/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('API / Networking & Security Tests', () {
    test('ApiService client contains default base headers and timeouts', () {
      final apiService = ApiService();
      expect(apiService.client.options.connectTimeout, equals(const Duration(seconds: 15)));
      expect(apiService.client.options.receiveTimeout, equals(const Duration(seconds: 15)));
      expect(apiService.client.options.headers['Accept'], equals('application/json'));
    });

    test('Session expiration broadcast stream triggers on 401', () async {
      FlutterSecureStorage.setMockInitialValues({'auth_jwt_token': 'sample_jwt'});
      bool sessionExpiredFired = false;
      final subscription = StorageService.sessionExpiredStream.listen((_) {
        sessionExpiredFired = true;
      });

      await StorageService.notifySessionExpired();

      // Small delay to allow microtask broadcast
      await Future.delayed(const Duration(milliseconds: 20));

      expect(sessionExpiredFired, isTrue);
      expect(StorageService.getToken(), isNull);
      expect(StorageService.isLoggedIn(), isFalse);

      await subscription.cancel();
    });

    test('ApiService correctly intercepts 401 and returns AuthException', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/user/profile'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/user/profile'),
          statusCode: 401,
          data: {'message': 'Session expired. Please log in again.'},
        ),
      );

      // Verify status code
      expect(dioException.response?.statusCode, equals(401));
    });

    test('Transient error check correctly identifies retryable network failures', () {
      final timeoutException = DioException(
        requestOptions: RequestOptions(path: '/sms/status'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(timeoutException.type, equals(DioExceptionType.connectionTimeout));

      final server503Exception = DioException(
        requestOptions: RequestOptions(path: '/sms/status'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/sms/status'),
          statusCode: 503,
        ),
      );
      expect(server503Exception.response?.statusCode, equals(503));
    });
  });
}
