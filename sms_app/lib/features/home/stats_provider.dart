import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/sim_model.dart';
import '../../data/models/sms_stats_model.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/sms_api_service.dart';
import '../../data/cache/cache_manager.dart';
import '../../data/providers/service_providers.dart';

/// Provider that fetches available SIM cards from the device.
final simsProvider = FutureProvider<List<SimModel>>((ref) async {
  final simService = ref.watch(simServiceProvider);
  return await simService.getAvailableSims();
});

class SmsStatsNotifier extends StateNotifier<SmsStatsModel> {
  final SmsApiService _apiService;
  final CacheManager _cache;

  SmsStatsNotifier({
    SmsApiService? apiService,
    CacheManager? cache,
  })  : _apiService = apiService ?? SmsApiService(),
        _cache = cache ?? CacheManager(),
        super(const SmsStatsModel()) {
    // Load cache immediately
    final cached = _cache.getCachedStats();
    if (cached != null) {
      state = SmsStatsModel(
        sentToday: (cached['sentToday'] as num?)?.toInt() ?? 0,
        failedToday: (cached['failedToday'] as num?)?.toInt() ?? 0,
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
  return SmsStatsNotifier(
    apiService: ref.watch(smsApiServiceProvider),
  );
});
