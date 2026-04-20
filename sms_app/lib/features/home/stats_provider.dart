import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sms_app/data/models/sim_model.dart';
import 'package:sms_app/data/services/sim_service.dart';
import 'package:sms_app/data/services/storage_service.dart';
import 'package:sms_app/data/services/sms_api_service.dart';

/// Provider that fetches available SIM cards from the device.
final simsProvider = FutureProvider<List<SimModel>>((ref) async {
  final simService = SimService();
  return await simService.getAvailableSims();
});

class SmsStatsNotifier extends StateNotifier<Map<String, int>> {
  final _apiService = SmsApiService();
  Timer? _timer;

  SmsStatsNotifier() : super({'sentToday': 0, 'failedToday': 0}) {
    fetchStats();
    _startPolling();
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      fetchStats();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchStats() async {
    final user = StorageService.getUser();
    if (user != null) {
      final stats = await _apiService.getDailyStats(user.id!.toString());
      state = stats;
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
