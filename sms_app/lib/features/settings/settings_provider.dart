import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/models/settings_model.dart';
import '../../data/models/sim_model.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/sim_service.dart';
import '../../core/theme/theme_provider.dart';

/// Provider for managing app settings state.
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsModel>(
  (ref) {
    return SettingsNotifier(ref);
  },
);

class SettingsNotifier extends StateNotifier<SettingsModel> {
  final Ref ref;
  final _simService = SimService();

  SettingsNotifier(this.ref) : super(StorageService.getSettings());

  /// Detects SIM cards and updates settings if no active SIM is set.
  Future<List<SimModel>> detectSims() async {
    debugPrint('SettingsNotifier: Starting SIM detection...');
    try {
      final granted = await _simService.requestPermissions();
      debugPrint('SettingsNotifier: Permissions granted: $granted');
      if (!granted) {
        debugPrint('SettingsNotifier: Permissions denied. Aborting.');
        return [];
      }

      final sims = await _simService.getAvailableSims();
      debugPrint('SettingsNotifier: Detected ${sims.length} SIM cards.');
      
      if (sims.isNotEmpty && state.activeSimId == null) {
        debugPrint('SettingsNotifier: Setting default active SIM: ${sims.first.id}');
        updateActiveSim(sims.first.id);
      }
      return sims;
    } catch (e) {
      debugPrint('SettingsNotifier: Error during SIM detection: $e');
      return [];
    }
  }

  /// Updates the active SIM ID.
  void updateActiveSim(String id) {
    state = state.copyWith(activeSimId: id);
    StorageService.saveSettings(state);
  }

  /// Updates the daily SMS limit.
  void updateLimit(int limit) {
    state = state.copyWith(dailySmsLimit: limit);
    StorageService.saveSettings(state);
  }

  /// Cycles through theme modes: System -> Light -> Dark -> System.
  void cycleTheme() {
    String nextTheme;
    ThemeMode nextMode;

    switch (state.themeMode) {
      case 'system':
        nextTheme = 'light';
        nextMode = ThemeMode.light;
        break;
      case 'light':
        nextTheme = 'dark';
        nextMode = ThemeMode.dark;
        break;
      case 'dark':
      default:
        nextTheme = 'system';
        nextMode = ThemeMode.system;
        break;
    }

    state = state.copyWith(themeMode: nextTheme);
    StorageService.saveSettings(state);

    // Update the global theme provider
    ref.read(themeModeProvider.notifier).state = nextMode;
  }
}
