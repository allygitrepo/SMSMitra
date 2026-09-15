import 'dart:async';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/utils/logger.dart';
import 'storage_service.dart';

/// Central API Service powered by Dio with automatic Auth, Retry, and Sanitized Logging Interceptors.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // 1. Auth & Token Injection Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = StorageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            logger.w('ApiService: 401 Unauthorized detected. Broadcasting session expiry.');
            await StorageService.notifySessionExpired();
          }
          return handler.next(error);
        },
      ),
    );

    // 2. Retry Interceptor for transient network glitches with exponential backoff
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, handler) async {
          final isGet = error.requestOptions.method.toUpperCase() == 'GET';
          final shouldRetry = isGet && _isTransientError(error);
          final currentRetry = (error.requestOptions.extra['retryCount'] as num?)?.toInt() ?? 0;

          if (shouldRetry && currentRetry < 2) {
            final nextRetry = currentRetry + 1;
            error.requestOptions.extra['retryCount'] = nextRetry;
            final delayMs = 500 * (1 << (nextRetry - 1)); // 500ms, 1000ms

            logger.i('ApiService: Retrying request ${error.requestOptions.path} (attempt $nextRetry/2 in ${delayMs}ms)...');
            await Future<void>.delayed(Duration(milliseconds: delayMs));

            try {
              final response = await _dio.fetch<dynamic>(error.requestOptions);
              return handler.resolve(response);
            } on DioException catch (retryError) {
              return handler.next(retryError);
            }
          }
          return handler.next(error);
        },
      ),
    );

    // 3. Sanitized Logging Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final sanitizedHeaders = Map<String, dynamic>.from(options.headers);
          if (sanitizedHeaders.containsKey('Authorization')) {
            sanitizedHeaders['Authorization'] = 'Bearer ***';
          }
          logger.d('HTTP [${options.method}] ${options.path} | Headers: $sanitizedHeaders');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          logger.d('HTTP Response [${response.statusCode}] ${response.requestOptions.path}');
          return handler.next(response);
        },
      ),
    );
  }

  Dio get client => _dio;

  static bool _isTransientError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return true;
    }
    final status = error.response?.statusCode;
    return status == 502 || status == 503 || status == 504;
  }

  /// Helper to wrap network execution with domain exception mapping
  Future<Response<T>> _execute<T>(Future<Response<T>> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(e.toString());
    }
  }

  Future<Response<T>> get<T>(String endpoint, {Map<String, dynamic>? queryParameters}) {
    return _execute(() => _dio.get<T>(endpoint, queryParameters: queryParameters));
  }

  Future<Response<T>> post<T>(String endpoint, {dynamic data, Map<String, dynamic>? queryParameters}) {
    return _execute(() => _dio.post<T>(endpoint, data: data, queryParameters: queryParameters));
  }

  Future<Response<T>> patch<T>(String endpoint, {dynamic data}) {
    return _execute(() => _dio.patch<T>(endpoint, data: data));
  }

  Future<Response<T>> delete<T>(String endpoint, {Map<String, dynamic>? queryParameters}) {
    return _execute(() => _dio.delete<T>(endpoint, queryParameters: queryParameters));
  }

  AppException _mapDioException(DioException error) {
    if (error.response?.statusCode == 401) {
      final data = error.response?.data;
      final String msg = data is Map
          ? (data['message']?.toString() ?? 'Unauthorized / Session Expired')
          : 'Unauthorized / Session Expired';
      return AuthException(msg);
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const NetworkException('Connection timeout. Please check your internet connection.');
    }

    if (error.response?.data is Map && error.response?.data['message'] != null) {
      return NetworkException(
        error.response!.data['message'].toString(),
        statusCode: error.response?.statusCode,
      );
    }

    return NetworkException(
      error.message ?? 'A network error occurred. Please try again.',
      statusCode: error.response?.statusCode,
    );
  }
}
