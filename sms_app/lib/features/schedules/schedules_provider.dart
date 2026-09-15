import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/scheduled_sms_model.dart';
import '../../data/services/scheduled_sms_service.dart';
import '../../data/services/storage_service.dart';
import '../../data/providers/service_providers.dart';

class SchedulesState {
  final List<ScheduledSmsModel> schedules;
  final Map<String, int> counts;
  final String filterStatus;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;
  final bool isLoading;
  final bool isCreating;
  final String? errorMessage;
  final String? successMessage;

  const SchedulesState({
    this.schedules = const <ScheduledSmsModel>[],
    this.counts = const <String, int>{
      'scheduled': 0,
      'completed': 0,
      'cancelled': 0,
      'failed': 0,
    },
    this.filterStatus = 'scheduled',
    this.filterStartDate,
    this.filterEndDate,
    this.isLoading = false,
    this.isCreating = false,
    this.errorMessage,
    this.successMessage,
  });

  bool get hasDateFilter => filterStartDate != null;

  String get formattedDateFilter {
    if (filterStartDate == null) return '';
    final start = filterStartDate!;
    final end = filterEndDate;
    if (end == null || (start.year == end.year && start.month == end.month && start.day == end.day)) {
      return DateFormat('d MMM yyyy').format(start);
    }
    if (start.year == end.year) {
      return '${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM yyyy').format(end)}';
    }
    return '${DateFormat('d MMM yyyy').format(start)} - ${DateFormat('d MMM yyyy').format(end)}';
  }

  List<ScheduledSmsModel> get filteredSchedules {
    if (filterStartDate == null) return schedules;

    final startDay = DateTime(filterStartDate!.year, filterStartDate!.month, filterStartDate!.day);
    final endDay = filterEndDate != null
        ? DateTime(filterEndDate!.year, filterEndDate!.month, filterEndDate!.day, 23, 59, 59, 999)
        : DateTime(filterStartDate!.year, filterStartDate!.month, filterStartDate!.day, 23, 59, 59, 999);

    return schedules.where((s) {
      return s.scheduledAt.isAfter(startDay.subtract(const Duration(milliseconds: 1))) &&
          s.scheduledAt.isBefore(endDay.add(const Duration(milliseconds: 1)));
    }).toList();
  }

  SchedulesState copyWith({
    List<ScheduledSmsModel>? schedules,
    Map<String, int>? counts,
    String? filterStatus,
    DateTime? filterStartDate,
    DateTime? filterEndDate,
    bool clearDateFilter = false,
    bool? isLoading,
    bool? isCreating,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return SchedulesState(
      schedules: schedules ?? this.schedules,
      counts: counts ?? this.counts,
      filterStatus: filterStatus ?? this.filterStatus,
      filterStartDate: clearDateFilter ? null : (filterStartDate ?? this.filterStartDate),
      filterEndDate: clearDateFilter ? null : (filterEndDate ?? this.filterEndDate),
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class SchedulesNotifier extends StateNotifier<SchedulesState> {
  final ScheduledSmsService _service;
  final Set<int> _locallyDispatchedIds = {};
  final Set<int> _locallyCancelledIds = {};

  SchedulesNotifier({ScheduledSmsService? service})
      : _service = service ?? ScheduledSmsService(),
        super(const SchedulesState());

  Future<void> init() async {
    await fetchSchedules();
  }

  Future<void> fetchSchedules({bool silent = false}) async {
    final user = StorageService.getUser();
    if (user == null) return;

    if (!silent && state.schedules.isEmpty) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final result = await _service.getSchedules(
        userId: user.id.toString(),
        status: state.filterStatus,
      );

      var schedules = (result['schedules'] as List<ScheduledSmsModel>?) ?? <ScheduledSmsModel>[];
      final counts = (result['counts'] as Map<String, int>?) ?? <String, int>{};

      // Ensure dispatched / cancelled cards never revert back to scheduled on the client
      if (_locallyDispatchedIds.isNotEmpty || _locallyCancelledIds.isNotEmpty) {
        schedules = schedules.map((s) {
          if (s.id != null && _locallyDispatchedIds.contains(s.id)) {
            return s.copyWith(status: 'completed');
          }
          if (s.id != null && _locallyCancelledIds.contains(s.id)) {
            return s.copyWith(status: 'cancelled');
          }
          return s;
        }).toList();

        if (state.filterStatus == 'scheduled') {
          schedules = schedules.where((s) {
            if (s.id == null) return true;
            return !_locallyDispatchedIds.contains(s.id) && !_locallyCancelledIds.contains(s.id);
          }).toList();
        }
      }

      state = state.copyWith(
        schedules: schedules,
        counts: counts,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load scheduled SMS list.',
      );
    }
  }

  void markScheduleDispatched(int scheduleId) {
    _locallyDispatchedIds.add(scheduleId);

    final updatedList = state.schedules.map((s) {
      if (s.id == scheduleId) {
        return s.copyWith(status: 'completed');
      }
      return s;
    }).toList();

    final updatedCounts = Map<String, int>.from(state.counts);
    updatedCounts['scheduled'] = ((updatedCounts['scheduled'] ?? 1) - 1).clamp(0, 999999);
    updatedCounts['completed'] = (updatedCounts['completed'] ?? 0) + 1;

    state = state.copyWith(
      schedules: state.filterStatus == 'scheduled'
          ? updatedList.where((s) => s.id != scheduleId).toList()
          : updatedList,
      counts: updatedCounts,
    );
  }

  Future<bool> createSchedule({
    required String receiverNumber,
    required String message,
    String? simId,
    required DateTime scheduledAt,
  }) async {
    final user = StorageService.getUser();
    if (user == null) {
      state = state.copyWith(errorMessage: 'User session not found.');
      return false;
    }

    state = state.copyWith(isCreating: true, clearError: true, clearSuccess: true);

    try {
      final newSchedule = await _service.createSchedule(
        userId: user.id.toString(),
        receiverNumber: receiverNumber,
        message: message,
        simId: simId,
        scheduledAt: scheduledAt,
      );

      // Optimistically insert new schedule into state immediately
      final updatedList = List<ScheduledSmsModel>.from(state.schedules)..add(newSchedule);
      updatedList.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

      final updatedCounts = Map<String, int>.from(state.counts);
      updatedCounts['scheduled'] = (updatedCounts['scheduled'] ?? 0) + 1;

      state = state.copyWith(
        schedules: updatedList,
        counts: updatedCounts,
        isCreating: false,
        successMessage: 'SMS successfully scheduled!',
      );

      // Silent sync with server in background
      await fetchSchedules(silent: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isCreating: false,
        errorMessage: 'Failed to schedule SMS: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> updateSchedule({
    required int id,
    required String receiverNumber,
    required String message,
    String? simId,
    required DateTime scheduledAt,
  }) async {
    state = state.copyWith(isCreating: true, clearError: true, clearSuccess: true);

    try {
      final updated = await _service.updateSchedule(
        id: id,
        receiverNumber: receiverNumber,
        message: message,
        simId: simId,
        scheduledAt: scheduledAt,
      );

      // Optimistically update existing schedule in state
      final updatedList = state.schedules.map((s) => s.id == id ? updated : s).toList();
      updatedList.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

      state = state.copyWith(
        schedules: updatedList,
        isCreating: false,
        successMessage: 'Scheduled SMS updated successfully!',
      );

      await fetchSchedules(silent: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isCreating: false,
        errorMessage: 'Failed to update schedule: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> cancelSchedule(int scheduleId) async {
    _locallyCancelledIds.add(scheduleId);
    try {
      final success = await _service.cancelSchedule(scheduleId);
      if (success) {
        // Optimistically update cancelled state
        final updatedList = state.schedules.map((s) {
          if (s.id == scheduleId) {
            return s.copyWith(status: 'cancelled');
          }
          return s;
        }).toList();

        final updatedCounts = Map<String, int>.from(state.counts);
        updatedCounts['scheduled'] = ((updatedCounts['scheduled'] ?? 1) - 1).clamp(0, 999999);
        updatedCounts['cancelled'] = (updatedCounts['cancelled'] ?? 0) + 1;

        state = state.copyWith(
          schedules: state.filterStatus == 'scheduled'
              ? updatedList.where((s) => s.id != scheduleId).toList()
              : updatedList,
          counts: updatedCounts,
        );

        await fetchSchedules(silent: true);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to cancel schedule.');
      return false;
    }
  }

  void setFilter(String status) {
    state = state.copyWith(filterStatus: status);
    fetchSchedules();
  }

  void setDateFilter(DateTime start, [DateTime? end]) {
    state = state.copyWith(
      filterStartDate: start,
      filterEndDate: end ?? start,
    );
  }

  void clearDateFilter() {
    state = state.copyWith(clearDateFilter: true);
  }
}

final schedulesProvider = StateNotifierProvider<SchedulesNotifier, SchedulesState>((ref) {
  return SchedulesNotifier(
    service: ref.watch(scheduledSmsServiceProvider),
  );
});
