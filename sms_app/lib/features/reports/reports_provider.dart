import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/organization_model.dart';
import '../../data/services/sms_api_service.dart';
import '../../data/services/storage_service.dart';

class ReportsState {
  final Map<String, int> stats;
  final List<dynamic> logs;
  final List<OrganizationModel> organizations;
  final bool isLoading;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? simId;
  final String? orgCode;
  final String? channel;

  ReportsState({
    this.stats = const {'pending': 0, 'sent': 0, 'failed': 0},
    this.logs = const [],
    this.organizations = const [],
    this.isLoading = false,
    this.startDate,
    this.endDate,
    this.simId,
    this.orgCode,
    this.channel,
  });

  ReportsState copyWith({
    Map<String, int>? stats,
    List<dynamic>? logs,
    List<OrganizationModel>? organizations,
    bool? isLoading,
    DateTime? startDate,
    DateTime? endDate,
    String? simId,
    String? orgCode,
    String? channel,
    bool clearSim = false,
    bool clearOrg = false,
    bool clearChannel = false,
  }) {
    return ReportsState(
      stats: stats ?? this.stats,
      logs: logs ?? this.logs,
      organizations: organizations ?? this.organizations,
      isLoading: isLoading ?? this.isLoading,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      simId: clearSim ? null : (simId ?? this.simId),
      orgCode: clearOrg ? null : (orgCode ?? this.orgCode),
      channel: clearChannel ? null : (channel ?? this.channel),
    );
  }
}

class ReportsNotifier extends StateNotifier<ReportsState> {
  final _apiService = SmsApiService();

  ReportsNotifier() : super(ReportsState());

  Future<void> init() async {
    await fetchOrganizations();
    await fetchReports();
  }

  Future<void> fetchOrganizations() async {
    final user = StorageService.getUser();
    if (user == null) return;
    try {
      final orgs = await _apiService.getOrganizations(user.id.toString());
      state = state.copyWith(organizations: orgs);
    } catch (_) {}
  }

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
        orgCode: state.orgCode,
        channel: state.channel,
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

  void updateOrgFilter(String? orgCode) {
    if (orgCode == 'all') {
      state = state.copyWith(clearOrg: true);
    } else {
      state = state.copyWith(orgCode: orgCode);
    }
    fetchReports();
  }

  void updateChannelFilter(String? channel) {
    if (channel == 'all') {
      state = state.copyWith(clearChannel: true);
    } else {
      state = state.copyWith(channel: channel);
    }
    fetchReports();
  }
}

final reportsProvider = StateNotifierProvider<ReportsNotifier, ReportsState>((ref) {
  return ReportsNotifier();
});
