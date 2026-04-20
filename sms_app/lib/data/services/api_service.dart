import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  ApiService() {
    // Add interceptors for logging or token injection
    _dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
  }

  Future<Response> get(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(endpoint, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> post(String endpoint, {dynamic data}) async {
    try {
      return await _dio.post(endpoint, data: data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> patch(String endpoint, {dynamic data}) async {
    try {
      return await _dio.patch(endpoint, data: data);
    } catch (e) {
      rethrow;
    }
  }
}
