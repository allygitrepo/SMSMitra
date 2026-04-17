import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/settings_model.dart';

/// A service to handle all local storage operations using Hive.
class StorageService {
  static const String userBoxName = 'user_box';
  static const String settingsBoxName = 'settings_box';

  /// Initializes Hive and opens necessary boxes.
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(SettingsModelAdapter());

    // Open Boxes
    await Hive.openBox<UserModel>(userBoxName);
    await Hive.openBox<SettingsModel>(settingsBoxName);
  }

  /// Saves the user data.
  static Future<void> saveUser(UserModel user) async {
    final box = Hive.box<UserModel>(userBoxName);
    await box.put('current_user', user);
  }

  /// Retrieves the saved user data.
  static UserModel? getUser() {
    final box = Hive.box<UserModel>(userBoxName);
    return box.get('current_user');
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
    final box = Hive.box<SettingsModel>(settingsBoxName);
    await box.put('app_settings', settings);
  }

  /// Retrieves the saved app settings.
  static SettingsModel getSettings() {
    final box = Hive.box<SettingsModel>(settingsBoxName);
    return box.get('app_settings') ?? SettingsModel();
  }
}
