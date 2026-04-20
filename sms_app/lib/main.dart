import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/routes/app_router.dart';
import 'data/services/storage_service.dart';
import 'data/services/sms_service.dart';
import 'data/services/sms_api_service.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyA1jTuHyRdi0WUVYQ7i8QKwQYORNcWXG7Y",
      appId: "1:173486311571:web:301a0f7587ec31e67d2566",
      messagingSenderId: "173486311571",
      projectId: "sms-mitra",
    ),
  );
  
  // MUST initialize storage in background to access API tokens
  await StorageService.init();
  
  debugPrint("FCM Background Message Received: ${message.data}");

  if (message.data['type'] == 'SEND_SMS') {
    final smsService = SmsService();
    final smsApi = SmsApiService();
    final logId = message.data['logId'];

    try {
      await smsService.sendSms(
        number: message.data['phoneNumber'],
        message: message.data['message'],
        simId: message.data['simId'], // Use the server-selected SIM
      );

      // Update status back to server
      await smsApi.updateSmsStatus(
        logId: logId,
        status: 'sent',
        simId: message.data['simId'],
      );
    } catch (e) {
      await smsApi.updateSmsStatus(
        logId: logId,
        status: 'failed',
        errorMessage: e.toString(),
      );
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyA1jTuHyRdi0WUVYQ7i8QKwQYORNcWXG7Y",
      appId:
          "1:173486311571:web:301a0f7587ec31e67d2566", // Using placeholder for android ID, you should update with your actual app package ID
      messagingSenderId: "173486311571",
      projectId: "sms-mitra",
    ),
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Handle messages when app is in FOREGROUND
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    debugPrint("FCM Foreground Message Received: ${message.data}");
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
        await smsApi.updateSmsStatus(logId: logId, status: 'failed', errorMessage: e.toString());
      }
    }
  });

  // Initialize local storage (Hive)
  await StorageService.init();

  // Request Notification Permissions for FCM triggers
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  debugPrint('User granted permission: ${settings.authorizationStatus}');

  runApp(const ProviderScope(child: SMSMitraApp()));
}

class SMSMitraApp extends ConsumerWidget {
  const SMSMitraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'SMSMitra',

      // Theme Configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: mode,

      // Router Configuration
      routerConfig: AppRouter.router,
    );
  }
}
