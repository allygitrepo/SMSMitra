import 'package:sms_app/core/utils/logger.dart';

import '../models/sim_model.dart';
import '../models/settings_model.dart';
import '../models/organization_model.dart';
import '../models/template_model.dart';
import 'api_service.dart';
import '../../core/constants/api_constants.dart';
import 'package:dio/dio.dart';

class SmsApiService {
  final ApiService _apiService = ApiService();

  /// Syncs SIM hardware details and limits to the server.
  Future<void> syncSims(
      {required String userId,
      required List<SimModel> sims,
      required SettingsModel settings}) async {
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

      await _apiService.post(
        ApiConstants.syncSims,
        data: {
          'userId': userId,
          'sims': simData,
        },
      );
    } catch (e) {
      print('SmsApiService: Sync Error: $e');
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
      await _apiService.post(
        ApiConstants.updateStatus,
        data: {
          'logId': logId,
          'status': status,
          'errorMessage': errorMessage,
          'simId': simId,
        },
      );
    } catch (e) {
      print('SmsApiService: Status Update Error: $e');
    }
  }

  /// Logs a manual SMS send to the server.
  Future<void> createManualLog({
    required String userId,
    required String phoneNumber,
    required String message,
    String? simId,
    required String status,
    String? orgCode,
  }) async {
    try {
      await _apiService.post(
        ApiConstants.createLog,
        data: {
          'userId': userId,
          'phoneNumber': phoneNumber,
          'message': message,
          'simId': simId,
          'status': status,
          'orgCode': orgCode,
        },
      );
    } catch (e) {
      print('SmsApiService: Manual Log Error: $e');
    }
  }

  /// Fetches daily statistics from the server.
  Future<Map<String, int>> getDailyStats(String userId) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.getReports}/stats',
        queryParameters: {'userId': userId},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        return {
          'sentToday': data['sentToday'] ?? 0,
          'failedToday': data['failedToday'] ?? 0,
        };
      }
    } catch (e) {
      print('SmsApiService: Stats Fetch Error: $e');
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

      final response = await _apiService.get(
        '${ApiConstants.getReports}/detailed',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data['data'];
      }
    } catch (e) {
      print('SmsApiService: Reports Fetch Error: $e');
    }
    return {
      'stats': {'pending': 0, 'sent': 0, 'failed': 0},
      'logs': []
    };
  }

  // Organizations
  Future<List<OrganizationModel>> getOrganizations(String userId) async {
    try {
      final response = await _apiService
          .get(ApiConstants.organizations, queryParameters: {'userId': userId});
      if (response.statusCode == 200) {
        final List data = response.data['data'];
        return data.map((e) => OrganizationModel.fromJson(e)).toList();
      }
    } catch (e) {
      print('SmsApiService: Organizations Fetch Error: $e');
    }
    return [];
  }

  Future<void> createOrganization(Map<String, dynamic> data) async {
    try {
      logger.i('Creating organization: ${data['orgName']}');
      final Map<String, dynamic> map = {
        'userId': data['userId'],
        'orgName': data['orgName'],
        'email': data['email'],
        'address': data['address'],
      };

      if (data['logoFile'] != null) {
        map['logo'] = await MultipartFile.fromFile(data['logoFile'].path);
      }

      final formData = FormData.fromMap(map);
      await _apiService.post(ApiConstants.organizations, data: formData);
      logger.i('Organization created successfully');
    } catch (e) {
      logger.e('SmsApiService: Create Organization Error: $e');
      rethrow;
    }
  }

  // Templates
  Future<List<SmsTemplateModel>> getTemplates(String userId) async {
    try {
      final response = await _apiService
          .get(ApiConstants.templates, queryParameters: {'userId': userId});
      if (response.statusCode == 200) {
        final List data = response.data['data'];
        return data.map((e) => SmsTemplateModel.fromJson(e)).toList();
      }
    } catch (e) {
      logger.e('SmsApiService: Templates Fetch Error: $e');
    }
    return [];
  }

  Future<void> createTemplate(SmsTemplateModel template) async {
    try {
      logger.i('Creating template: ${template.templateName}');
      await _apiService.post(ApiConstants.templates, data: template.toJson());
      logger.i('Template created successfully');
    } catch (e) {
      logger.e('SmsApiService: Create Template Error: $e');
      rethrow;
    }
  }

  // File Parsing
  Future<List<Map<String, dynamic>>> parseBulkFile(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response =
          await _apiService.post(ApiConstants.parseFile, data: formData);
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
    } catch (e) {
      print('SmsApiService: Parse File Error: $e');
    }
    return [];
  }
}
