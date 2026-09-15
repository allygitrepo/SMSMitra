import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sms_app/data/cache/cache_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/routes/app_router.dart';
import 'core/utils/logger.dart';
import 'data/services/storage_service.dart';
import 'data/services/sms_service.dart';
import 'data/services/sms_api_service.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyA1jTuHyRdi0WUVYQ7i8QKwQYORNcWXG7Y",
      appId:
          "1:173486311571:android:301a0f7587ec31e67d2566", // Updated to android type
      messagingSenderId: "173486311571",
      projectId: "sms-mitra",
    ),
  );

  // MUST initialize storage in background to access API tokens
  await StorageService.init();

  await StorageService.addAppLog(
    "FCM Background Message Received",
    details: message.data.toString(),
  );

  debugPrint("FCM Background Message Received: ${message.data}");

  if (message.data['type'] == 'SEND_SMS') {
    final smsService = SmsService();
    final smsApi = SmsApiService();
    final logId = message.data['logId']?.toString() ?? '';
    final phoneNumber = message.data['phoneNumber']?.toString() ?? '';
    final smsBody = message.data['message']?.toString() ?? '';
    final simId = message.data['simId']?.toString();

    try {
      await smsService.sendSms(
        number: phoneNumber,
        message: smsBody,
        simId: simId, // Use the server-selected SIM
      );

      // Update status back to server
      await smsApi.updateSmsStatus(
        logId: logId,
        status: 'sent',
        simId: simId,
      );
      await StorageService.addAppLog(
        "SMS Sent (Background)",
        details:
            "To: $phoneNumber, SIM: $simId",
      );
      await CacheService().incrementSentStats();
    } catch (e) {
      await smsApi.updateSmsStatus(
        logId: logId,
        status: 'failed',
        errorMessage: e.toString(),
      );
      await StorageService.addAppLog(
        "SMS Failed (Background)",
        level: 'error',
        details: "Error: $e",
      );
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Flutter framework error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    logger.e("FlutterError caught", error: details.exception, stackTrace: details.stack);
    StorageService.addAppLog(
      "FlutterError Caught",
      level: 'error',
      details: details.exceptionAsString(),
    );
  };

  // Global PlatformDispatcher unhandled asynchronous error handling
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.e("PlatformDispatcher caught unhandled error", error: error, stackTrace: stack);
    StorageService.addAppLog(
      "Unhandled Async Error",
      level: 'error',
      details: error.toString(),
    );
    return true;
  };

  // Initialize Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyA1jTuHyRdi0WUVYQ7i8QKwQYORNcWXG7Y",
      appId:
          "1:173486311571:android:301a0f7587ec31e67d2566", // Updated to android type
      messagingSenderId: "173486311571",
      projectId: "sms-mitra",
    ),
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Handle messages when app is in FOREGROUND
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    await StorageService.addAppLog(
      "FCM Foreground Message Received",
      details: message.data.toString(),
    );
    debugPrint("FCM Foreground Message Received: ${message.data}");
    if (message.data['type'] == 'SEND_SMS') {
      final smsService = SmsService();
      final smsApi = SmsApiService();
      final logId = message.data['logId']?.toString() ?? '';
      final phoneNumber = message.data['phoneNumber']?.toString() ?? '';
      final smsBody = message.data['message']?.toString() ?? '';
      final simId = message.data['simId']?.toString();

      try {
        final success = await smsService.sendSms(
          number: phoneNumber,
          message: smsBody,
          simId: simId,
        );
        await smsApi.updateSmsStatus(
          logId: logId,
          status: success ? 'sent' : 'failed',
          simId: simId,
        );
        await StorageService.addAppLog(
          "SMS Result (Foreground)",
          level: success ? 'info' : 'warning',
          details: "Success: $success, To: $phoneNumber",
        );
        if (success) await CacheService().incrementSentStats();
      } catch (e) {
        await smsApi.updateSmsStatus(
          logId: logId,
          status: 'failed',
          errorMessage: e.toString(),
        );
        await StorageService.addAppLog(
          "SMS Error (Foreground)",
          level: 'error',
          details: e.toString(),
        );
      }
    } else if (message.data['type'] == 'STATS_UPDATE') {
      // Refresh stats on dashboard
      debugPrint("FCM Stats Update Triggered");
      // We can use the global provider container if needed, but since we are in main,
      // we usually rely on the widgets to listen.
      // However, for immediate update, we can't easily access the container here without a global key or similar.
      // Better: The dashboard itself listens to FCM or we use a global event bus.
      // Since we use Riverpod, we can use ProviderContainer if we initialize it.
    }
  });

  // Initialize local storage (Hive)
  await StorageService.init();
  await StorageService.addAppLog("Application Started");

  // Request Notification Permissions for FCM triggers
  final FirebaseMessaging messaging = FirebaseMessaging.instance;
  final NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  debugPrint('User granted permission: ${settings.authorizationStatus}');

  runApp(const ProviderScope(child: SMSMitraApp()));
}

class SMSMitraApp extends ConsumerStatefulWidget {
  const SMSMitraApp({super.key});

  @override
  ConsumerState<SMSMitraApp> createState() => _SMSMitraAppState();
}

class _SMSMitraAppState extends ConsumerState<SMSMitraApp> {
  StreamSubscription<void>? _sessionSubscription;

  @override
  void initState() {
    super.initState();
    _sessionSubscription = StorageService.sessionExpiredStream.listen((_) {
      AppRouter.router.go(AppRouter.login);
    });
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
