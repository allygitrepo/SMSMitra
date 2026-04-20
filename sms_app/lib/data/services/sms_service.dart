import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
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
  }) async {
    try {
      final settings = StorageService.getSettings();
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
      return false;
    }
  }
}
