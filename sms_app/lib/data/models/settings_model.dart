import 'package:hive_flutter/hive_flutter.dart';

part 'settings_model.g.dart';

/// Represents the application settings.
/// Stores the active SIM, daily SMS limit, and theme preference.
@HiveType(typeId: 1)
class SettingsModel extends HiveObject {
  @HiveField(0)
  final String? activeSimId;

  @HiveField(1)
  final int dailySmsLimit; // -1 for unlimited

  @HiveField(2)
  final String themeMode; // 'system', 'light', 'dark'

  @HiveField(3, defaultValue: false)
  final bool isLoggedIn;

  SettingsModel({
    this.activeSimId,
    this.dailySmsLimit = 100,
    this.themeMode = 'system',
    this.isLoggedIn = false,
  });

  /// Creates a copy of the settings with modified fields.
  SettingsModel copyWith({
    String? activeSimId,
    int? dailySmsLimit,
    String? themeMode,
    bool? isLoggedIn,
  }) {
    return SettingsModel(
      activeSimId: activeSimId ?? this.activeSimId,
      dailySmsLimit: dailySmsLimit ?? this.dailySmsLimit,
      themeMode: themeMode ?? this.themeMode,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }

  /// Helper to get the human-readable limit.
  String get limitLabel {
    if (dailySmsLimit == -1) return 'Unlimited';
    return '$dailySmsLimit/day';
  }
}
