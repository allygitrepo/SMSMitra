import '../../core/constants/api_constants.dart';
import '../../core/utils/logger.dart';
import '../models/scheduled_sms_model.dart';
import 'api_service.dart';

class ScheduledSmsService {
  final ApiService _apiService;

  ScheduledSmsService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Creates a new scheduled SMS on the server
  Future<ScheduledSmsModel> createSchedule({
    required String userId,
    required String receiverNumber,
    required String message,
    String? simId,
    required DateTime scheduledAt,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConstants.schedules,
        data: <String, dynamic>{
          'userId': userId,
          'receiverNumber': receiverNumber,
          'message': message,
          if (simId != null) 'simId': simId,
          'scheduledAt': scheduledAt.toIso8601String(),
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        final data = response.data!['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ScheduledSmsModel.fromJson(data);
        }
      }
      throw Exception('Failed to schedule SMS');
    } catch (e) {
      logger.e('ScheduledSmsService: Create Error: $e');
      rethrow;
    }
  }

  /// Fetches scheduled SMS list for a user
  Future<Map<String, dynamic>> getSchedules({
    required String userId,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'userId': userId,
        if (status != null && status != 'all') 'status': status,
      };

      final response = await _apiService.get<Map<String, dynamic>>(
        ApiConstants.schedules,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final rawData = (response.data!['data'] as List<dynamic>?) ?? <dynamic>[];
        final schedules = rawData
            .map((dynamic item) => ScheduledSmsModel.fromJson(item as Map<String, dynamic>))
            .toList();

        final rawCounts = (response.data!['counts'] as Map<String, dynamic>?) ?? <String, dynamic>{};
        final counts = rawCounts.map(
          (k, v) => MapEntry(k, (v is num ? v.toInt() : int.tryParse(v.toString())) ?? 0),
        );

        return <String, dynamic>{
          'schedules': schedules,
          'counts': counts,
        };
      }
      return <String, dynamic>{
        'schedules': <ScheduledSmsModel>[],
        'counts': <String, int>{},
      };
    } catch (e) {
      logger.e('ScheduledSmsService: Fetch Error: $e');
      rethrow;
    }
  }

  /// Updates an existing pending scheduled SMS
  Future<ScheduledSmsModel> updateSchedule({
    required int id,
    required String receiverNumber,
    required String message,
    String? simId,
    required DateTime scheduledAt,
  }) async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        '${ApiConstants.schedules}/$id',
        data: <String, dynamic>{
          'receiverNumber': receiverNumber,
          'message': message,
          if (simId != null) 'simId': simId,
          'scheduledAt': scheduledAt.toIso8601String(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ScheduledSmsModel.fromJson(data);
        }
      }
      throw Exception('Failed to update scheduled SMS');
    } catch (e) {
      logger.e('ScheduledSmsService: Update Error: $e');
      rethrow;
    }
  }

  /// Cancels a scheduled SMS
  Future<bool> cancelSchedule(int scheduleId) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        '${ApiConstants.schedules}/$scheduleId',
      );
      return response.statusCode == 200;
    } catch (e) {
      logger.e('ScheduledSmsService: Cancel Error: $e');
      rethrow;
    }
  }
}
