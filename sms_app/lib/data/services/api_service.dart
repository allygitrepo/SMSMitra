import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/app_exceptions.dart';
import 'storage_service.dart';

/// Central API Service powered by Dio with automatic Auth and Error Interceptors.
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

    // Auth & Token Injection Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = StorageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          if (error.response?.statusCode == 401) {
            // Handle session expiration
            StorageService.clearSession();
          }
          return handler.next(error);
        },
      ),
    );
  }

  Dio get client => _dio;

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
      final msg = error.response?.data is Map
          ? error.response?.data['message'] ?? 'Unauthorized / Session Expired'
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
