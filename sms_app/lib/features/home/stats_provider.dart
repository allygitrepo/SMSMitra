import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sms_app/data/models/sim_model.dart';
import 'package:sms_app/data/services/sim_service.dart';
import 'package:sms_app/data/services/storage_service.dart';
import 'package:sms_app/data/services/sms_api_service.dart';
import 'package:sms_app/data/cache/cache_manager.dart';

/// Provider that fetches available SIM cards from the device.
final simsProvider = FutureProvider<List<SimModel>>((ref) async {
  final simService = SimService();
  return await simService.getAvailableSims();
});

class SmsStatsNotifier extends StateNotifier<Map<String, int>> {
  final _apiService = SmsApiService();
  final _cache = CacheManager();

  SmsStatsNotifier() : super({'sentToday': 0, 'failedToday': 0}) {
    // Load cache immediately
    final cached = _cache.getCachedStats();
    if (cached != null) {
      state = Map<String, int>.from(cached);
    }
  }

  Future<void> fetchStats() async {
    final user = StorageService.getUser();
    if (user != null) {
      final stats = await _apiService.getDailyStats(user.id!.toString());
      if (stats.isNotEmpty) {
        state = stats;
        await _cache.saveStats(stats);
      }
    }
  }

  void incrementSent() {
    state = {...state, 'sentToday': (state['sentToday'] ?? 0) + 1};
  }

  void incrementFailed() {
    state = {...state, 'failedToday': (state['failedToday'] ?? 0) + 1};
  }

  void setStats(int sent, int failed) {
    state = {'sentToday': sent, 'failedToday': failed};
  }
}

/// Provider for tracking daily SMS statistics.
final smsStatsProvider =
    StateNotifierProvider<SmsStatsNotifier, Map<String, int>>((ref) {
      return SmsStatsNotifier();
    });
