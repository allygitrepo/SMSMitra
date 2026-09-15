import 'package:flutter_test/flutter_test.dart';
import 'package:sms_app/data/models/sms_stats_model.dart';
import 'package:sms_app/data/models/sms_log_model.dart';
import 'package:sms_app/features/reports/reports_provider.dart';

void main() {
  group('SmsStatsModel & Notifier Unit Tests', () {
    test('SmsStatsModel defaults to 0 and not loading', () {
      const stats = SmsStatsModel();
      expect(stats.sentToday, 0);
      expect(stats.failedToday, 0);
      expect(stats.isLoading, false);
      expect(stats.errorMessage, isNull);
    });

    test('SmsStatsModel copyWith correctly updates fields', () {
      const stats = SmsStatsModel();
      final updated = stats.copyWith(
        sentToday: 5,
        failedToday: 1,
        isLoading: true,
        errorMessage: 'Network error',
      );

      expect(updated.sentToday, 5);
      expect(updated.failedToday, 1);
      expect(updated.isLoading, true);
      expect(updated.errorMessage, 'Network error');
    });

    test('SmsStatsModel equality check works', () {
      const stats1 = SmsStatsModel(sentToday: 10, failedToday: 2);
      const stats2 = SmsStatsModel(sentToday: 10, failedToday: 2);
      const stats3 = SmsStatsModel(sentToday: 5, failedToday: 1);

      expect(stats1, equals(stats2));
      expect(stats1, isNot(equals(stats3)));
    });
  });

  group('ReportsState Unit Tests', () {
    test('ReportsState initial defaults', () {
      const state = ReportsState();
      expect(state.logs, isEmpty);
      expect(state.isLoading, false);
      expect(state.stats['sent'], 0);
      expect(state.errorMessage, isNull);
    });

    test('ReportsState copyWith with typed SmsLogModel list', () {
      const state = ReportsState();
      final log = SmsLogModel(
        id: '101',
        receiverNumber: '+919876543210',
        message: 'Test message',
        status: 'sent',
        simId: '1',
        createdAt: DateTime.now(),
      );

      final updated = state.copyWith(
        logs: [log],
        stats: {'sent': 1, 'failed': 0, 'pending': 0},
        isLoading: false,
      );

      expect(updated.logs.length, 1);
      expect(updated.logs.first.receiverNumber, '+919876543210');
      expect(updated.stats['sent'], 1);
    });
  });
}
