import '../models/sim_model.dart';
import '../models/settings_model.dart';
import 'api_service.dart';
import 'storage_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/logger.dart';

class SmsApiService {
  final ApiService _apiService = ApiService();

  /// Syncs SIM hardware details and limits to the server.
  Future<void> syncSims({
    required String userId,
    required List<SimModel> sims,
    required SettingsModel settings,
  }) async {
    try {
      final List<Map<String, dynamic>> simData = sims
          .map((sim) => {
                'id': sim.id,
                'carrierName': sim.carrierName,
                'number': sim.number,
                'dailyLimit': settings.dailySmsLimit,
                'limitPeriod': settings.limitPeriod,
              })
          .toList();

      await _apiService.post<dynamic>(
        ApiConstants.syncSims,
        data: {
          'userId': userId,
          'sims': simData,
        },
      );
    } catch (e) {
      logger.e('SmsApiService: Sync Error: $e');
      await StorageService.addAppLog('SIM Sync Error: $e', level: 'error');
    }
  }

  /// Updates the status of an SMS after the carrier process completes.
  Future<void> updateSmsStatus({
    required String logId,
    required String status,
    String? errorMessage,
    String? simId,
  }) async {
    try {
      await _apiService.post<dynamic>(
        ApiConstants.updateStatus,
        data: {
          'logId': logId,
          'status': status,
          'errorMessage': errorMessage,
          'simId': simId,
        },
      );
    } catch (e) {
      logger.e('SmsApiService: Status Update Error: $e');
    }
  }

  /// Logs a manual SMS send to the server.
  Future<void> createManualLog({
    required String userId,
    required String phoneNumber,
    required String message,
    String? simId,
    required String status,
    String? errorMessage,
  }) async {
    try {
      await _apiService.post<dynamic>(
        ApiConstants.createLog,
        data: {
          'userId': userId,
          'phoneNumber': phoneNumber,
          'message': message,
          'simId': simId,
          'status': status,
          'errorMessage': errorMessage,
        },
      );
    } catch (e) {
      logger.w('SmsApiService: Manual Log Sync Error (skipped): $e');
    }
  }

  /// Fetches daily statistics from the server.
  Future<Map<String, int>> getDailyStats(String userId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '${ApiConstants.getReports}/stats',
        queryParameters: {'userId': userId},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!['data'] as Map<String, dynamic>?;
        if (data != null) {
          return {
            'sentToday': (data['sentToday'] as num?)?.toInt() ?? 0,
            'failedToday': (data['failedToday'] as num?)?.toInt() ?? 0,
          };
        }
      }
    } catch (e) {
      logger.e('SmsApiService: Stats Fetch Error: $e');
    }
    return {'sentToday': 0, 'failedToday': 0};
  }

  /// Fetches detailed reports with filters.
  Future<Map<String, dynamic>> getDetailedReports({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    String? simId,
    String? orgCode,
    String? channel,
  }) async {
    try {
      final queryParams = {
        'userId': userId,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
        if (simId != null) 'simId': simId,
        if (orgCode != null) 'orgCode': orgCode,
        if (channel != null && channel != 'all') 'channel': channel,
      };

      final response = await _apiService.get<Map<String, dynamic>>(
        '${ApiConstants.getReports}/detailed',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!['data'];
        if (data is Map<String, dynamic>) {
          return data;
        }
      }
    } catch (e) {
      logger.e('SmsApiService: Reports Fetch Error: $e');
      rethrow;
    }
    return <String, dynamic>{
      'stats': <String, dynamic>{'pending': 0, 'sent': 0, 'failed': 0},
      'logs': <dynamic>[]
    };
  }
}
