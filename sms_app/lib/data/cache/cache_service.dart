import 'package:hive_flutter/hive_flutter.dart';
import 'package:sms_app/data/models/app_log_model.dart';
import '../models/user_model.dart';
import '../models/settings_model.dart';
import '../models/sms_log_model.dart';
import '../models/queue_request_model.dart';
import '../models/cached_data_model.dart';
import 'cache_keys.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  /// Initializes all Hive boxes and registers adapters
  Future<void> init() async {
    await Hive.initFlutter();

    // Register All Adapters
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(UserModelAdapter());
    if (!Hive.isAdapterRegistered(1))
      Hive.registerAdapter(SettingsModelAdapter());
    if (!Hive.isAdapterRegistered(2))
      Hive.registerAdapter(SmsLogModelAdapter());
    if (!Hive.isAdapterRegistered(3))
      Hive.registerAdapter(QueueRequestModelAdapter());
    if (!Hive.isAdapterRegistered(4))
      Hive.registerAdapter(CachedDataModelAdapter());
    if (!Hive.isAdapterRegistered(5))
      Hive.registerAdapter(AppLogModelAdapter());

    // Open All Boxes
    await Future.wait([
      Hive.openBox<UserModel>(CacheBoxes.user),
      Hive.openBox<SettingsModel>(CacheBoxes.settings),
      Hive.openBox<CachedDataModel>(CacheBoxes.dashboard),
      Hive.openBox<SmsLogModel>(CacheBoxes.history),
      Hive.openBox<QueueRequestModel>(CacheBoxes.queue),
      Hive.openBox<CachedDataModel>(CacheBoxes.sims),
      Hive.openBox<AppLogModel>(CacheBoxes.appLogs),
    ]);
  }

  // --- User Cache ---
  Future<void> setUser(UserModel user) async {
    final box = Hive.box<UserModel>(CacheBoxes.user);
    await box.put(CacheKeys.currentUser, user);
  }

  UserModel? getUser() {
    return Hive.box<UserModel>(CacheBoxes.user).get(CacheKeys.currentUser);
  }

  // --- Settings Cache ---
  Future<void> setSettings(SettingsModel settings) async {
    final box = Hive.box<SettingsModel>(CacheBoxes.settings);
    await box.put(CacheKeys.appSettings, settings);
  }

  SettingsModel getSettings() {
    return Hive.box<SettingsModel>(
          CacheBoxes.settings,
        ).get(CacheKeys.appSettings) ??
        SettingsModel();
  }

  // --- Dashboard Cache (with Expiry) ---
  Future<void> setDashboardStats(Map<String, dynamic> stats) async {
    final box = Hive.box<CachedDataModel>(CacheBoxes.dashboard);
    await box.put(
      CacheKeys.dashboardStats,
      CachedDataModel(data: stats, timestamp: DateTime.now()),
    );
  }

  Map<String, dynamic>? getDashboardStats({
    Duration expiry = const Duration(minutes: 5),
  }) {
    final cached = Hive.box<CachedDataModel>(
      CacheBoxes.dashboard,
    ).get(CacheKeys.dashboardStats);
    if (cached == null) return null;
    if (cached.isExpired(expiry)) return null;
    return Map<String, dynamic>.from(cached.data);
  }

  // --- SMS History Cache ---
  Future<void> cacheSmsLogs(List<SmsLogModel> logs) async {
    final box = Hive.box<SmsLogModel>(CacheBoxes.history);
    await box.clear();
    await box.addAll(logs);
  }

  List<SmsLogModel> getSmsLogs() {
    return Hive.box<SmsLogModel>(CacheBoxes.history).values.toList();
  }

  // --- Request Queue ---
  Future<void> addToQueue(QueueRequestModel request) async {
    final box = Hive.box<QueueRequestModel>(CacheBoxes.queue);
    await box.add(request);
  }

  List<QueueRequestModel> getQueue() {
    return Hive.box<QueueRequestModel>(CacheBoxes.queue).values.toList();
  }

  Future<void> removeFromQueue(int index) async {
    final box = Hive.box<QueueRequestModel>(CacheBoxes.queue);
    await box.deleteAt(index);
  }

  // --- App Logs ---
  Future<void> addAppLog(AppLogModel log) async {
    final box = Hive.box<AppLogModel>(CacheBoxes.appLogs);
    await box.add(log);

    // Maintain a limit of 1000 logs to avoid bloating storage
    if (box.length > 1000) {
      await box.deleteAt(0);
    }
  }

  List<AppLogModel> getAppLogs() {
    return Hive.box<AppLogModel>(
      CacheBoxes.appLogs,
    ).values.toList().reversed.toList();
  }

  Future<void> clearAppLogs() async {
    await Hive.box<AppLogModel>(CacheBoxes.appLogs).clear();
  }

  // --- Cleanup ---
  Future<void> clearSession() async {
    await Hive.box<UserModel>(CacheBoxes.user).clear();
    await Hive.box<CachedDataModel>(CacheBoxes.dashboard).clear();
    await Hive.box<SmsLogModel>(CacheBoxes.history).clear();
    // Keep settings and queue for offline continuity
  }
}
