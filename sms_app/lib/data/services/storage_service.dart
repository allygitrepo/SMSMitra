import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../cache/cache_service.dart';
import '../models/user_model.dart';
import '../models/settings_model.dart';
import '../models/app_log_model.dart';

/// A service to handle all local storage operations, powered by Hive and FlutterSecureStorage.
class StorageService {
  static final _cache = CacheService();
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _tokenKey = 'auth_jwt_token';
  static String? _inMemoryToken;

  static final _sessionExpiredController = StreamController<void>.broadcast();

  /// Broadcast stream notifying listeners when the session has expired (e.g. 401 response).
  static Stream<void> get sessionExpiredStream => _sessionExpiredController.stream;

  /// Initializes the storage service by initializing the underlying cache and loading token.
  static Future<void> init() async {
    await _cache.init();
    _inMemoryToken = await _secureStorage.read(key: _tokenKey);
  }

  /// Saves the JWT token securely.
  static Future<void> saveToken(String token) async {
    _inMemoryToken = token;
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  /// Retrieves the JWT token.
  static String? getToken() {
    return _inMemoryToken;
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

  /// Notifies listeners that session has expired and clears local credentials.
  static Future<void> notifySessionExpired() async {
    await clearSession();
    _sessionExpiredController.add(null);
  }

  /// Clears user session, cached token, and local states.
  static Future<void> clearSession() async {
    _inMemoryToken = null;
    await _secureStorage.delete(key: _tokenKey);
    await setLoggedIn(false);
    await _cache.clearSession();
  }
}

