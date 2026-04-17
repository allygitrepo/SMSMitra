import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/services/storage_service.dart';

/// Provider for managing the current ThemeMode.
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  final settings = StorageService.getSettings();
  switch (settings.themeMode) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
    default:
      return ThemeMode.system;
  }
});
