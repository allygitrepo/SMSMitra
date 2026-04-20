import '../cache/cache_service.dart';
import '../models/user_model.dart';
import '../models/settings_model.dart';

/// A service to handle all local storage operations, now powered by CacheService.
class StorageService {
  static final _cache = CacheService();

  /// Legacy init - now handled by CacheService().init()
  static Future<void> init() async {}

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
