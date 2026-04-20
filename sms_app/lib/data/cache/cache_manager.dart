import 'cache_service.dart';
import '../models/user_model.dart';
import '../models/settings_model.dart';
import '../models/sms_log_model.dart';
import '../models/queue_request_model.dart';

class CacheManager {
  final CacheService _cache = CacheService();

  // --- User Logic ---
  UserModel? get currentUser => _cache.getUser();
  
  Future<void> saveUser(UserModel user) async {
    await _cache.setUser(user);
  }

  // --- Dashboard Logic ---
  Map<String, dynamic>? getCachedStats() => _cache.getDashboardStats();

  Future<void> saveStats(Map<String, dynamic> stats) async {
    await _cache.setDashboardStats(stats);
  }

  // --- Settings Logic ---
  SettingsModel get settings => _cache.getSettings();

  Future<void> saveSettings(SettingsModel settings) async {
    await _cache.setSettings(settings);
  }

  // --- History Logic ---
  List<SmsLogModel> getCachedHistory() => _cache.getSmsLogs();

  Future<void> saveHistory(List<SmsLogModel> logs) async {
    await _cache.cacheSmsLogs(logs);
  }

  // --- Queue Logic ---
  Future<void> queueRequest(String path, String method, Map<String, dynamic> data) async {
    await _cache.addToQueue(QueueRequestModel(
      path: path,
      method: method,
      data: data,
      createdAt: DateTime.now(),
    ));
  }

  List<QueueRequestModel> getPendingRequests() => _cache.getQueue();

  Future<void> resolveRequest(int index) async {
    await _cache.removeFromQueue(index);
  }

  // --- Global Cleanup ---
  Future<void> clearAuth() async {
    await _cache.clearSession();
  }
}
