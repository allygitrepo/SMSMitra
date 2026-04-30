import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/sms_api_service.dart';
import '../../data/services/storage_service.dart';

class ReportsState {
  final Map<String, int> stats;
  final List<dynamic> logs;
  final bool isLoading;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? simId;

  ReportsState({
    this.stats = const {'pending': 0, 'sent': 0, 'failed': 0},
    this.logs = const [],
    this.isLoading = false,
    this.startDate,
    this.endDate,
    this.simId,
  });

  ReportsState copyWith({
    Map<String, int>? stats,
    List<dynamic>? logs,
    bool? isLoading,
    DateTime? startDate,
    DateTime? endDate,
    String? simId,
    bool clearSim = false,
  }) {
    return ReportsState(
      stats: stats ?? this.stats,
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      simId: clearSim ? null : (simId ?? this.simId),
    );
  }
}

class ReportsNotifier extends StateNotifier<ReportsState> {
  final _apiService = SmsApiService();

  ReportsNotifier() : super(ReportsState());

  Future<void> fetchReports() async {
    final user = StorageService.getUser();
    if (user == null) return;

    state = state.copyWith(isLoading: true);

    try {
      final data = await _apiService.getDetailedReports(
        userId: user.id.toString(),
        startDate: state.startDate,
        endDate: state.endDate,
        simId: state.simId,
      );

      state = state.copyWith(
        stats: Map<String, int>.from(data['stats']),
        logs: List<dynamic>.from(data['logs']),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void updateDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(startDate: start, endDate: end);
    fetchReports();
  }

  void updateSimFilter(String? simId) {
    if (simId == 'all') {
      state = state.copyWith(clearSim: true);
    } else {
      state = state.copyWith(simId: simId);
    }
    fetchReports();
  }
}

final reportsProvider = StateNotifierProvider<ReportsNotifier, ReportsState>((ref) {
  return ReportsNotifier();
});
