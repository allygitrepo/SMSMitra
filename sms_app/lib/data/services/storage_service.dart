import '../cache/cache_service.dart';
import '../models/user_model.dart';
import '../models/settings_model.dart';
import '../models/app_log_model.dart';

/// A service to handle all local storage operations, now powered by CacheService.
class StorageService {
  static final _cache = CacheService();

  /// Initializes the storage service by initializing the underlying cache.
  static Future<void> init() async {
    await _cache.init();
  }

  /// Adds a local application log for debugging.
  static Future<void> addAppLog(String message, {String level = 'info', String? details}) async {
    await _cache.addAppLog(AppLogModel(
      message: message,
      level: level,
      timestamp: DateTime.now(),
      details: details,
    ));
  }

  /// Retrieves the local application logs.
  static List<AppLogModel> getAppLogs() {
    return _cache.getAppLogs();
  }

  /// Clears all local application logs.
  static Future<void> clearAppLogs() async {
    await _cache.clearAppLogs();
  }

  /// Saves the user data.
  static Future<void> saveUser(UserModel user) async {
    await _cache.setUser(user);
  }

  /// Retrieves the saved user data.
  static UserModel? getUser() {
    return _cache.getUser();
  }

  /// Checks if the user is registered.
  static bool isUserRegistered() {
    return getUser() != null;
  }

  /// Sets the login status.
  static Future<void> setLoggedIn(bool value) async {
    final settings = getSettings();
    await saveSettings(settings.copyWith(isLoggedIn: value));
  }

  /// Checks if the user is currently logged in.
  static bool isLoggedIn() {
    return getSettings().isLoggedIn;
  }

  /// Saves the app settings.
  static Future<void> saveSettings(SettingsModel settings) async {
    await _cache.setSettings(settings);
  }

  /// Checks if the SIM configuration is already setup.
  static bool isSimConfigured() {
    return getSettings().activeSimId != null;
  }

  /// Retrieves the saved app settings.
  static SettingsModel getSettings() {
    return _cache.getSettings();
  }
}
