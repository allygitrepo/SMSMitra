import 'package:sms_app/data/services/storage_service.dart';
import '../../../core/utils/logger.dart';
import '../../core/constants/api_constants.dart';
import 'api_service.dart';

class WhatsAppSmsService {
  final ApiService _apiService = ApiService();

  Future<void> init() async {
    // No-op now as we use UserModel/StorageService directly
  }

  bool isLinked() {
    final user = StorageService.getUser();
    return user?.whatsappInstanceKey != null;
  }

  Future<void> setLinked(bool value) async {
    final user = StorageService.getUser();
    if (user != null && !value) {
      // Clear local WhatsApp details if unlinked
      await StorageService.saveUser(user.copyWith(
        whatsappInstanceKey: null,
        whatsappProfileImage: null,
        whatsappPhone: null,
        whatsappName: null,
      ));
    }
  }

  Future<Map<String, dynamic>> startSession(String userId) async {
    try {
      final response = await _apiService.post(
        ApiConstants.waInitiate,
        data: {'userId': userId},
      );
      final data = response.data;
      if (data != null && data['success'] == true) {
        final user = StorageService.getUser();
        if (user != null) {
          await StorageService.saveUser(user.copyWith(
            whatsappInstanceKey: data['instanceKey'],
            whatsappProfileImage: data['status'] == 'connected' ? data['profileImage'] : user.whatsappProfileImage,
            whatsappPhone: data['status'] == 'connected' ? data['phone'] : user.whatsappPhone,
            whatsappName: data['status'] == 'connected' ? data['name'] : user.whatsappName,
          ));
        }
      }
      return Map<String, dynamic>.from(data);
    } catch (e) {
      logger.e('Failed to start WhatsApp session: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getStatus(String userId) async {
    try {
      final response = await _apiService.get(
        ApiConstants.waStatus,
        queryParameters: {'userId': userId},
      );
      final data = response.data;
      if (data != null && data['success'] == true) {
        final user = StorageService.getUser();
        if (user != null) {
          if (data['status'] == 'connected') {
            await StorageService.saveUser(user.copyWith(
              whatsappInstanceKey: data['instanceKey'],
              whatsappProfileImage: data['profileImage'] ?? user.whatsappProfileImage,
              whatsappPhone: data['phone'] ?? user.whatsappPhone,
              whatsappName: data['name'] ?? user.whatsappName,
            ));
          } else if (data['status'] == 'disconnected') {
            await StorageService.saveUser(user.copyWith(
              whatsappInstanceKey: null,
              whatsappProfileImage: null,
              whatsappPhone: null,
              whatsappName: null,
            ));
          }
        }
      }
      return Map<String, dynamic>.from(data);
    } catch (e) {
      logger.e('Failed to get WhatsApp status: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> disconnect(String userId) async {
    try {
      final response = await _apiService.delete(
        ApiConstants.waDelete,
        queryParameters: {'userId': userId},
      );
      await setLinked(false);
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      logger.e('Failed to disconnect WhatsApp: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendBulkMessages({
    required List<Map<String, String>> messages,
    required String sessionId, // Maps to userId on proxy backend
    String? userId,
    String? orgCode,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.waSendBulk,
        data: {
          'userId': userId ?? sessionId,
          'messages': messages,
          'orgCode': orgCode,
        },
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      logger.e('Failed to send bulk WhatsApp messages: $e');
      rethrow;
    }
  }
}
