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

  @HiveField(4, defaultValue: 'day')
  final String limitPeriod; // 'day', 'month'

  @HiveField(5, defaultValue: [])
  final List<String> simPriority; // List of SIM IDs in priority order

  SettingsModel({
    this.activeSimId,
    this.dailySmsLimit = 100,
    this.themeMode = 'system',
    this.isLoggedIn = false,
    this.limitPeriod = 'day',
    this.simPriority = const [],
  });

  /// Creates a copy of the settings with modified fields.
  SettingsModel copyWith({
    String? activeSimId,
    bool clearActiveSim = false,
    int? dailySmsLimit,
    String? themeMode,
    bool? isLoggedIn,
    String? limitPeriod,
    List<String>? simPriority,
  }) {
    return SettingsModel(
      activeSimId: clearActiveSim ? null : (activeSimId ?? this.activeSimId),
      dailySmsLimit: dailySmsLimit ?? this.dailySmsLimit,
      themeMode: themeMode ?? this.themeMode,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      limitPeriod: limitPeriod ?? this.limitPeriod,
      simPriority: simPriority ?? this.simPriority,
    );
  }

  /// Helper to get the human-readable limit.
  String get limitLabel {
    if (dailySmsLimit == -1) return 'Unlimited';
    final period = limitPeriod == 'day' ? 'day' : 'month';
    return '$dailySmsLimit/$period';
  }
}
