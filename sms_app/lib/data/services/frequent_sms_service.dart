import '../../core/constants/api_constants.dart';
import '../../core/utils/logger.dart';
import '../models/frequent_sms_model.dart';
import 'api_service.dart';

class FrequentSmsService {
  final ApiService _apiService;

  FrequentSmsService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Creates a new recurring/frequent SMS rule
  Future<FrequentSmsModel> createFrequent({
    required String userId,
    String? title,
    required String receiverNumber,
    required String message,
    String? simId,
    required String frequencyType,
    required Map<String, dynamic> frequencyConfig,
    required String dispatchTime,
    DateTime? startDate,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConstants.frequent,
        data: <String, dynamic>{
          'userId': userId,
          if (title != null) 'title': title,
          'receiverNumber': receiverNumber,
          'message': message,
          if (simId != null) 'simId': simId,
          'frequencyType': frequencyType,
          'frequencyConfig': frequencyConfig,
          'dispatchTime': dispatchTime,
          if (startDate != null) 'startDate': startDate.toIso8601String(),
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        final data = response.data!['data'] as Map<String, dynamic>?;
        if (data != null) {
          return FrequentSmsModel.fromJson(data);
        }
      }
      throw Exception('Failed to create recurring SMS rule');
    } catch (e) {
      logger.e('FrequentSmsService: Create Error: $e');
      rethrow;
    }
  }

  /// Fetches recurring SMS list for a user
  Future<Map<String, dynamic>> getFrequentList({
    required String userId,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'userId': userId,
        if (status != null && status != 'all') 'status': status,
      };

      final response = await _apiService.get<Map<String, dynamic>>(
        ApiConstants.frequent,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final rawData = (response.data!['data'] as List<dynamic>?) ?? <dynamic>[];
        final rules = rawData
            .map((dynamic item) => FrequentSmsModel.fromJson(item as Map<String, dynamic>))
            .toList();

        final rawCounts = (response.data!['counts'] as Map<String, dynamic>?) ?? <String, dynamic>{};
        final counts = rawCounts.map(
          (k, v) => MapEntry(k, (v is num ? v.toInt() : int.tryParse(v.toString())) ?? 0),
        );

        return <String, dynamic>{
          'rules': rules,
          'counts': counts,
        };
      }
      return <String, dynamic>{
        'rules': <FrequentSmsModel>[],
        'counts': <String, int>{},
      };
    } catch (e) {
      logger.e('FrequentSmsService: Fetch Error: $e');
      rethrow;
    }
  }

  /// Updates an existing recurring SMS rule
  Future<FrequentSmsModel> updateFrequent({
    required int id,
    String? title,
    required String receiverNumber,
    required String message,
    String? simId,
    required String frequencyType,
    required Map<String, dynamic> frequencyConfig,
    required String dispatchTime,
    DateTime? startDate,
  }) async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        '${ApiConstants.frequent}/$id',
        data: <String, dynamic>{
          if (title != null) 'title': title,
          'receiverNumber': receiverNumber,
          'message': message,
          if (simId != null) 'simId': simId,
          'frequencyType': frequencyType,
          'frequencyConfig': frequencyConfig,
          'dispatchTime': dispatchTime,
          if (startDate != null) 'startDate': startDate.toIso8601String(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!['data'] as Map<String, dynamic>?;
        if (data != null) {
          return FrequentSmsModel.fromJson(data);
        }
      }
      throw Exception('Failed to update recurring SMS rule');
    } catch (e) {
      logger.e('FrequentSmsService: Update Error: $e');
      rethrow;
    }
  }

  /// Toggles status between active and paused
  Future<FrequentSmsModel> toggleStatus(int id) async {
    try {
      final response = await _apiService.patch<Map<String, dynamic>>(
        '${ApiConstants.frequent}/$id/toggle',
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!['data'] as Map<String, dynamic>?;
        if (data != null) {
          return FrequentSmsModel.fromJson(data);
        }
      }
      throw Exception('Failed to toggle status');
    } catch (e) {
      logger.e('FrequentSmsService: Toggle Error: $e');
      rethrow;
    }
  }

  /// Deletes a recurring SMS rule
  Future<bool> deleteFrequent(int id) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        '${ApiConstants.frequent}/$id',
      );
      return response.statusCode == 200;
    } catch (e) {
      logger.e('FrequentSmsService: Delete Error: $e');
      rethrow;
    }
  }
}
