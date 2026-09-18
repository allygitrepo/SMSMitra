import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../models/template_model.dart';
import 'api_service.dart';

class TemplateService {
  final ApiService _apiService;

  TemplateService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  Future<List<SmsTemplateModel>> getTemplates(int userId) async {
    try {
      final response = await _apiService.client.get<dynamic>(
        '${ApiConstants.templates}?userId=$userId',
      );

      final data = response.data;
      if (data is Map && data['data'] is List) {
        return (data['data'] as List)
            .map((item) => SmsTemplateModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw NetworkException(
        e.response?.data is Map
            ? (e.response?.data['message']?.toString() ?? 'Failed to load templates')
            : 'Failed to load templates',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw NetworkException('Unexpected error: $e');
    }
  }

  Future<SmsTemplateModel> createTemplate(SmsTemplateModel template) async {
    try {
      final response = await _apiService.client.post<dynamic>(
        ApiConstants.templates,
        data: template.toJson(),
      );

      final data = response.data;
      if (data is Map && data['data'] != null) {
        return SmsTemplateModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      return template;
    } on DioException catch (e) {
      throw NetworkException(
        e.response?.data is Map
            ? (e.response?.data['message']?.toString() ?? 'Failed to create template')
            : 'Failed to create template',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw NetworkException('Unexpected error: $e');
    }
  }

  Future<SmsTemplateModel> updateTemplate(SmsTemplateModel template) async {
    if (template.id == null) throw const NetworkException('Template ID is required for update');

    try {
      final response = await _apiService.client.put<dynamic>(
        '${ApiConstants.templates}/${template.id}',
        data: template.toJson(),
      );

      final data = response.data;
      if (data is Map && data['data'] != null) {
        return SmsTemplateModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      return template;
    } on DioException catch (e) {
      throw NetworkException(
        e.response?.data is Map
            ? (e.response?.data['message']?.toString() ?? 'Failed to update template')
            : 'Failed to update template',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw NetworkException('Unexpected error: $e');
    }
  }

  Future<bool> deleteTemplate(int templateId) async {
    try {
      final response = await _apiService.client.delete<dynamic>(
        '${ApiConstants.templates}/$templateId',
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw NetworkException(
        e.response?.data is Map
            ? (e.response?.data['message']?.toString() ?? 'Failed to delete template')
            : 'Failed to delete template',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw NetworkException('Unexpected error: $e');
    }
  }
}
