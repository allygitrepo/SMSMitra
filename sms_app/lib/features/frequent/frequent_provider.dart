import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/frequent_sms_model.dart';
import '../../data/services/frequent_sms_service.dart';
import '../../data/services/storage_service.dart';
import '../../data/providers/service_providers.dart';

class FrequentState {
  final List<FrequentSmsModel> rules;
  final Map<String, int> counts;
  final String filterStatus;
  final bool isLoading;
  final bool isCreating;
  final String? errorMessage;
  final String? successMessage;

  const FrequentState({
    this.rules = const <FrequentSmsModel>[],
    this.counts = const <String, int>{
      'active': 0,
      'paused': 0,
      'totalDispatched': 0,
    },
    this.filterStatus = 'all',
    this.isLoading = false,
    this.isCreating = false,
    this.errorMessage,
    this.successMessage,
  });

  FrequentState copyWith({
    List<FrequentSmsModel>? rules,
    Map<String, int>? counts,
    String? filterStatus,
    bool? isLoading,
    bool? isCreating,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return FrequentState(
      rules: rules ?? this.rules,
      counts: counts ?? this.counts,
      filterStatus: filterStatus ?? this.filterStatus,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class FrequentNotifier extends StateNotifier<FrequentState> {
  final FrequentSmsService _service;

  FrequentNotifier({FrequentSmsService? service})
      : _service = service ?? FrequentSmsService(),
        super(const FrequentState());

  Future<void> init() async {
    await fetchRules();
  }

  Future<void> fetchRules({bool silent = false}) async {
    final user = StorageService.getUser();
    if (user == null) return;

    if (!silent && state.rules.isEmpty) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final result = await _service.getFrequentList(
        userId: user.id.toString(),
        status: state.filterStatus,
      );

      final rules = (result['rules'] as List<FrequentSmsModel>?) ?? <FrequentSmsModel>[];
      final counts = (result['counts'] as Map<String, int>?) ?? <String, int>{};

      state = state.copyWith(
        rules: rules,
        counts: counts,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load recurring SMS rules.',
      );
    }
  }

  Future<bool> createRule({
    String? title,
    required String receiverNumber,
    required String message,
    String? simId,
    required String frequencyType,
    required Map<String, dynamic> frequencyConfig,
    required String dispatchTime,
    DateTime? startDate,
  }) async {
    final user = StorageService.getUser();
    if (user == null) {
      state = state.copyWith(errorMessage: 'User session not found.');
      return false;
    }

    state = state.copyWith(isCreating: true, clearError: true, clearSuccess: true);

    try {
      final newRule = await _service.createFrequent(
        userId: user.id.toString(),
        title: title,
        receiverNumber: receiverNumber,
        message: message,
        simId: simId,
        frequencyType: frequencyType,
        frequencyConfig: frequencyConfig,
        dispatchTime: dispatchTime,
        startDate: startDate,
      );

      // Optimistically insert new rule into state
      final updatedList = List<FrequentSmsModel>.from(state.rules)..add(newRule);
      updatedList.sort((a, b) => a.nextRunAt.compareTo(b.nextRunAt));

      final updatedCounts = Map<String, int>.from(state.counts);
      updatedCounts['active'] = (updatedCounts['active'] ?? 0) + 1;

      state = state.copyWith(
        rules: updatedList,
        counts: updatedCounts,
        isCreating: false,
        successMessage: 'Recurring SMS rule created successfully!',
      );

      await fetchRules(silent: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isCreating: false,
        errorMessage: 'Failed to create recurring rule: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> updateRule({
    required int id,
    String? title,
    required String receiverNumber,
    required String message,
    String? simId,
    required String frequencyType,
    required Map<String, dynamic> frequencyConfig,
    required String dispatchTime,
    DateTime? startDate,
  }) async {
    state = state.copyWith(isCreating: true, clearError: true, clearSuccess: true);

    try {
      final updated = await _service.updateFrequent(
        id: id,
        title: title,
        receiverNumber: receiverNumber,
        message: message,
        simId: simId,
        frequencyType: frequencyType,
        frequencyConfig: frequencyConfig,
        dispatchTime: dispatchTime,
        startDate: startDate,
      );

      final updatedList = state.rules.map((r) => r.id == id ? updated : r).toList();
      updatedList.sort((a, b) => a.nextRunAt.compareTo(b.nextRunAt));

      state = state.copyWith(
        rules: updatedList,
        isCreating: false,
        successMessage: 'Recurring SMS rule updated successfully!',
      );

      await fetchRules(silent: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isCreating: false,
        errorMessage: 'Failed to update rule: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> toggleStatus(int id) async {
    // Optimistic toggle
    final previousList = state.rules;
    final updatedList = state.rules.map((r) {
      if (r.id == id) {
        final newStatus = r.status == 'active' ? 'paused' : 'active';
        return r.copyWith(status: newStatus);
      }
      return r;
    }).toList();

    final activeCount = updatedList.where((r) => r.status == 'active').length;
    final pausedCount = updatedList.where((r) => r.status == 'paused').length;
    final updatedCounts = Map<String, int>.from(state.counts);
    updatedCounts['active'] = activeCount;
    updatedCounts['paused'] = pausedCount;

    state = state.copyWith(
      rules: state.filterStatus == 'active'
          ? updatedList.where((r) => r.status == 'active').toList()
          : (state.filterStatus == 'paused'
              ? updatedList.where((r) => r.status == 'paused').toList()
              : updatedList),
      counts: updatedCounts,
    );

    try {
      final updated = await _service.toggleStatus(id);
      final syncedList = state.rules.map((r) => r.id == id ? updated : r).toList();
      state = state.copyWith(rules: syncedList);
      return true;
    } catch (e) {
      // Revert on failure
      state = state.copyWith(rules: previousList);
      return false;
    }
  }

  Future<bool> deleteRule(int id) async {
    try {
      final success = await _service.deleteFrequent(id);
      if (success) {
        final updatedList = state.rules.where((r) => r.id != id).toList();
        final updatedCounts = Map<String, int>.from(state.counts);
        final deletedItem = state.rules.where((r) => r.id == id).firstOrNull;
        if (deletedItem != null) {
          if (deletedItem.status == 'active') {
            updatedCounts['active'] = ((updatedCounts['active'] ?? 1) - 1).clamp(0, 999999);
          } else if (deletedItem.status == 'paused') {
            updatedCounts['paused'] = ((updatedCounts['paused'] ?? 1) - 1).clamp(0, 999999);
          }
        }

        state = state.copyWith(
          rules: updatedList,
          counts: updatedCounts,
        );

        await fetchRules(silent: true);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete recurring rule.');
      return false;
    }
  }

  void setFilter(String status) {
    state = state.copyWith(filterStatus: status);
    fetchRules();
  }
}

final frequentProvider = StateNotifierProvider<FrequentNotifier, FrequentState>((ref) {
  return FrequentNotifier(
    service: ref.watch(frequentSmsServiceProvider),
  );
});
