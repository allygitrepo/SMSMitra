import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sms_app/data/models/frequent_sms_model.dart';
import 'package:sms_app/features/frequent/frequent_provider.dart';
import 'package:sms_app/features/frequent/frequent_screen.dart';
import 'package:sms_app/features/frequent/widgets/frequent_sms_sheet.dart';

void main() {
  group('FrequentSmsModel Unit Tests', () {
    test('Correctly parses and formats Daily recurrence', () {
      final model = FrequentSmsModel(
        id: 1,
        userId: 101,
        receiverNumber: '9998887776',
        message: 'Daily message',
        frequencyType: 'daily',
        dispatchTime: '09:30',
        startDate: DateTime(2026, 9, 15),
        nextRunAt: DateTime(2026, 9, 16, 9, 30),
        createdAt: DateTime(2026, 9, 15),
      );

      expect(model.isActive, isTrue);
      expect(model.isPaused, isFalse);
      expect(model.formattedFrequency, contains('Daily'));
      expect(model.formattedFrequency, contains('09:30 AM'));
      expect(model.toJson()['frequencyType'], 'daily');
    });

    test('Correctly parses and formats Alternate Day recurrence', () {
      final model = FrequentSmsModel(
        id: 2,
        userId: 101,
        receiverNumber: '9998887776',
        message: 'Alternate day message',
        frequencyType: 'alternate',
        frequencyConfig: const <String, dynamic>{'startFrom': 'tomorrow'},
        dispatchTime: '18:00',
        startDate: DateTime(2026, 9, 15),
        nextRunAt: DateTime(2026, 9, 16, 18, 0),
        createdAt: DateTime(2026, 9, 15),
      );

      expect(model.formattedFrequency, contains('Alternate Days (from Tomorrow)'));
      expect(model.formattedFrequency, contains('06:00 PM'));
    });

    test('Correctly parses and formats Weekly recurrence', () {
      final model = FrequentSmsModel(
        id: 3,
        userId: 101,
        receiverNumber: '9998887776',
        message: 'Weekly message',
        frequencyType: 'weekly',
        frequencyConfig: const <String, dynamic>{'daysOfWeek': [1, 3, 5]},
        dispatchTime: '14:15',
        startDate: DateTime(2026, 9, 15),
        nextRunAt: DateTime(2026, 9, 17, 14, 15),
        createdAt: DateTime(2026, 9, 15),
      );

      expect(model.formattedFrequency, contains('Every Mon, Wed, Fri'));
      expect(model.formattedFrequency, contains('02:15 PM'));
    });

    test('Correctly parses and formats Monthly recurrence', () {
      final model = FrequentSmsModel(
        id: 4,
        userId: 101,
        receiverNumber: '9998887776',
        message: 'Monthly invoice',
        frequencyType: 'monthly',
        frequencyConfig: const <String, dynamic>{'daysOfMonth': [1, 15]},
        dispatchTime: '10:00',
        startDate: DateTime(2026, 9, 15),
        nextRunAt: DateTime(2026, 10, 1, 10, 0),
        createdAt: DateTime(2026, 9, 15),
      );

      expect(model.formattedFrequency, contains('Monthly on 1st, 15th'));
      expect(model.formattedFrequency, contains('10:00 AM'));
    });
  });

  group('FrequentState Unit Tests', () {
    final now = DateTime.now();
    final rule1 = FrequentSmsModel(
      id: 1,
      userId: 101,
      title: 'Daily Morning Report',
      receiverNumber: '9876543210',
      message: 'Good morning!',
      frequencyType: 'daily',
      dispatchTime: '09:00',
      startDate: now,
      nextRunAt: now.add(const Duration(hours: 4)),
      totalDispatchedCount: 10,
      status: 'active',
      createdAt: now,
    );
    final rule2 = FrequentSmsModel(
      id: 2,
      userId: 101,
      title: 'Weekly Standup',
      receiverNumber: '9876543211',
      message: 'Standup in 10 mins',
      frequencyType: 'weekly',
      frequencyConfig: const <String, dynamic>{'daysOfWeek': [1, 3]},
      dispatchTime: '10:00',
      startDate: now,
      nextRunAt: now.add(const Duration(days: 2)),
      totalDispatchedCount: 5,
      status: 'paused',
      createdAt: now,
    );

    test('Initial state defaults', () {
      const state = FrequentState();
      expect(state.rules, isEmpty);
      expect(state.isLoading, false);
      expect(state.filterStatus, 'all');
      expect(state.errorMessage, isNull);
      expect(state.counts['active'], 0);
      expect(state.counts['paused'], 0);
      expect(state.counts['totalDispatched'], 0);
    });

    test('Counts and copyWith update state properly', () {
      final state = FrequentState(
        rules: [rule1, rule2],
        counts: const {
          'active': 1,
          'paused': 1,
          'totalDispatched': 15,
        },
        filterStatus: 'all',
      );

      expect(state.counts['active'], 1);
      expect(state.counts['paused'], 1);
      expect(state.counts['totalDispatched'], 15);
      expect(state.rules.length, 2);

      final filteredState = state.copyWith(filterStatus: 'active');
      expect(filteredState.filterStatus, 'active');
      expect(filteredState.rules.length, 2);
    });
  });

  group('FrequentScreen & FrequentSmsSheet Widget Tests', () {
    testWidgets('FrequentScreen renders summary cards and filter chips', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FrequentScreen(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Active Rules'), findsOneWidget);
      expect(find.text('Paused'), findsWidgets);
      expect(find.text('Total Sent'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
    });

    testWidgets('FrequentSmsSheet renders options and frequency chips', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FrequentSmsSheet(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Frequently Sending SMS'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Alternate Day'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);
      expect(find.text('Save Recurring Rule'), findsOneWidget);
    });
  });
}
