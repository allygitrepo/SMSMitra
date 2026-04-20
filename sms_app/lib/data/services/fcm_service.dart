import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../cache/cache_service.dart';
import '../services/sms_service.dart';
import '../services/sms_api_service.dart';

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  /// Initialize Firebase and Messaging
  Future<void> init() async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyA1jTuHyRdi0WUVYQ7i8QKwQYORNcWXG7Y",
        appId: "1:173486311571:web:301a0f7587ec31e67d2566",
        messagingSenderId: "173486311571",
        projectId: "sms-mitra",
      ),
    );

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(backgroundHandler);

    // Request permissions
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen(_foregroundHandler);
  }

  /// Handles messages when app is in FOREGROUND
  static void _foregroundHandler(RemoteMessage message) {
    debugPrint("FCM Foreground Message Received: ${message.data}");
    _processMessage(message);
  }

  /// Handles messages when app is in BACKGROUND/TERMINATED
  @pragma('vm:entry-point')
  static Future<void> backgroundHandler(RemoteMessage message) async {
    try {
      debugPrint("FCM Background: Initializing...");
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyA1jTuHyRdi0WUVYQ7i8QKwQYORNcWXG7Y",
          appId: "1:173486311571:web:301a0f7587ec31e67d2566",
          messagingSenderId: "173486311571",
          projectId: "sms-mitra",
        ),
      );

      await CacheService().init();
      debugPrint("FCM Background Message Received: ${message.data}");
      await _processMessage(message);
      
    } catch (e) {
      debugPrint("FCM Background FATAL Error: $e");
      _reportFailure(message.data['logId'], "Background Init Error: $e");
    }
  }

  /// Core logic to process SMS requests
  static Future<void> _processMessage(RemoteMessage message) async {
    if (message.data['type'] == 'SEND_SMS') {
      final smsService = SmsService();
      final smsApi = SmsApiService();
      final logId = message.data['logId'];

      try {
        final success = await smsService.sendSms(
          number: message.data['phoneNumber'],
          message: message.data['message'],
          simId: message.data['simId'],
        );

        await smsApi.updateSmsStatus(
          logId: logId,
          status: success ? 'sent' : 'failed',
          simId: message.data['simId'],
        );
      } catch (e) {
        debugPrint("FCM Process Error: $e");
        _reportFailure(logId, e.toString());
      }
    }
  }

  static Future<void> _reportFailure(String? logId, String error) async {
    try {
      final smsApi = SmsApiService();
      await smsApi.updateSmsStatus(
        logId: logId ?? 'unknown',
        status: 'failed',
        errorMessage: error,
      );
    } catch (_) {}
  }
}
