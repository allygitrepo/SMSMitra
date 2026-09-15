import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/sim_model.dart';
import '../../data/models/sms_stats_model.dart';
import '../../data/services/sim_service.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/sms_api_service.dart';
import '../../data/cache/cache_manager.dart';

/// Provider that fetches available SIM cards from the device.
final simsProvider = FutureProvider<List<SimModel>>((ref) async {
  final simService = SimService();
  return await simService.getAvailableSims();
});

class SmsStatsNotifier extends StateNotifier<SmsStatsModel> {
  final _apiService = SmsApiService();
  final _cache = CacheManager();

  SmsStatsNotifier() : super(const SmsStatsModel()) {
    // Load cache immediately
    final cached = _cache.getCachedStats();
    if (cached != null) {
      state = SmsStatsModel(
        sentToday: cached['sentToday'] ?? 0,
        failedToday: cached['failedToday'] ?? 0,
      );
    }
  }

  Future<void> fetchStats() async {
    final user = StorageService.getUser();
    if (user == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final stats = await _apiService.getDailyStats(user.id!.toString());
      state = state.copyWith(
        sentToday: stats['sentToday'] ?? 0,
        failedToday: stats['failedToday'] ?? 0,
        isLoading: false,
      );
      await _cache.saveStats(stats);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to sync stats with server.',
      );
    }
  }

  void incrementSent() {
    state = state.copyWith(sentToday: state.sentToday + 1);
    _cache.saveStats({'sentToday': state.sentToday, 'failedToday': state.failedToday});
  }

  void incrementFailed() {
    state = state.copyWith(failedToday: state.failedToday + 1);
    _cache.saveStats({'sentToday': state.sentToday, 'failedToday': state.failedToday});
  }

  void setStats({required int sent, required int failed}) {
    state = state.copyWith(sentToday: sent, failedToday: failed);
    _cache.saveStats({'sentToday': sent, 'failedToday': failed});
  }
}

/// Provider for tracking daily SMS statistics reactively.
final smsStatsProvider =
    StateNotifierProvider<SmsStatsNotifier, SmsStatsModel>((ref) {
  return SmsStatsNotifier();
});
