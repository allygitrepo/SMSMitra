import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../cache/cache_service.dart';
import 'storage_service.dart';

/// A service to handle SMS operations (sending via native channel).
class SmsService {
  /// Requests permissions for SMS operations.
  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.sms,
      Permission.phone,
    ].request();

    return statuses[Permission.sms]?.isGranted == true;
  }

  /// Sends an SMS message directly using native SmsManager with SIM support.
  Future<bool> sendSms({
    required String number,
    required String message,
    String? simId,
    bool skipQuotaCheck = false,
  }) async {
    try {
      final settings = StorageService.getSettings();
      
      if (!skipQuotaCheck) {
        // Enforce Quota Check
        final stats = CacheService().getDashboardStats() ?? {};
        final sentToday = stats['sentToday'] ?? 0;
        final dailyLimit = settings.dailySmsLimit;

        if (dailyLimit != -1 && sentToday >= dailyLimit) {
          final errorMsg = 'Quota Exceeded: $sentToday/$dailyLimit limit reached';
          await StorageService.addAppLog(errorMsg, level: 'warning');
          throw Exception(errorMsg);
        }
      }

      // Use provided simId or fall back to active settings
      final subIdStr = simId ?? settings.activeSimId;
      final subId = int.tryParse(subIdStr ?? '');

      const channel = MethodChannel('com.example.sms_app/sim_info');
      final bool success = await channel.invokeMethod('sendSms', {
        'number': number,
        'message': message,
        'subscriptionId': subId,
      });

      return success;
    } catch (e) {
      if (e is Exception) rethrow;
      return false;
    }
  }
}
