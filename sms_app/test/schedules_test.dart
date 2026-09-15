import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sms_app/data/models/scheduled_sms_model.dart';
import 'package:sms_app/features/schedules/schedules_provider.dart';
import 'package:sms_app/features/schedules/schedules_screen.dart';
import 'package:sms_app/features/schedules/widgets/schedule_sms_sheet.dart';

void main() {
  group('ScheduledSmsModel Unit Tests', () {
    final testDate = DateTime(2026, 9, 20, 15, 30);
    final createdDate = testDate.subtract(const Duration(days: 1));

    test('fromJson correctly parses API JSON payload', () {
      final json = {
        'id': 101,
        'userId': 1,
        'receiverNumber': '9876543210',
        'message': 'Happy Birthday!',
        'scheduledAt': testDate.toIso8601String(),
        'status': 'scheduled',
        'simId': 'sim_1',
        'createdAt': createdDate.toIso8601String(),
      };

      final model = ScheduledSmsModel.fromJson(json);

      expect(model.id, 101);
      expect(model.userId, 1);
      expect(model.receiverNumber, '9876543210');
      expect(model.message, 'Happy Birthday!');
      expect(model.status, 'scheduled');
      expect(model.simId, 'sim_1');
      expect(model.scheduledAt.year, 2026);
    });

    test('toJson produces expected map format', () {
      final model = ScheduledSmsModel(
        id: 102,
        userId: 1,
        receiverNumber: '9123456789',
        message: 'Reminder',
        scheduledAt: testDate,
        status: 'scheduled',
        createdAt: createdDate,
      );

      final json = model.toJson();
      expect(json['id'], 102);
      expect(json['userId'], 1);
      expect(json['receiverNumber'], '9123456789');
      expect(json['status'], 'scheduled');
      expect(json['scheduledAt'], testDate.toIso8601String());
    });

    test('copyWith updates specified fields only', () {
      final model = ScheduledSmsModel(
        id: 103,
        userId: 1,
        receiverNumber: '9123456789',
        message: 'Original Message',
        scheduledAt: testDate,
        status: 'scheduled',
        createdAt: createdDate,
      );

      final updated = model.copyWith(
        status: 'completed',
        message: 'Updated Message',
      );

      expect(updated.id, 103);
      expect(updated.status, 'completed');
      expect(updated.message, 'Updated Message');
      expect(updated.receiverNumber, '9123456789');
    });

    test('equality and hashCode work as expected', () {
      final model1 = ScheduledSmsModel(
        id: 1,
        userId: 1,
        receiverNumber: '9123456789',
        message: 'Test',
        scheduledAt: testDate,
        status: 'scheduled',
        createdAt: createdDate,
      );

      final model2 = ScheduledSmsModel(
        id: 1,
        userId: 1,
        receiverNumber: '9123456789',
        message: 'Test',
        scheduledAt: testDate,
        status: 'scheduled',
        createdAt: createdDate,
      );

      final model3 = ScheduledSmsModel(
        id: 2,
        userId: 1,
        receiverNumber: '9123456789',
        message: 'Test',
        scheduledAt: testDate,
        status: 'scheduled',
        createdAt: createdDate,
      );

      expect(model1, equals(model2));
      expect(model1.hashCode, equals(model2.hashCode));
      expect(model1, isNot(equals(model3)));
    });
  });

  group('SchedulesState Unit Tests', () {
    final now = DateTime.now();
    final item1 = ScheduledSmsModel(
      id: 1,
      userId: 1,
      receiverNumber: '9876543210',
      message: 'Msg 1',
      scheduledAt: now.add(const Duration(hours: 1)),
      status: 'scheduled',
      createdAt: now,
    );
    final item2 = ScheduledSmsModel(
      id: 2,
      userId: 1,
      receiverNumber: '9876543211',
      message: 'Msg 2',
      scheduledAt: now.subtract(const Duration(hours: 1)),
      status: 'completed',
      createdAt: now,
    );

    test('Initial state defaults', () {
      const state = SchedulesState();
      expect(state.schedules, isEmpty);
      expect(state.isLoading, false);
      expect(state.filterStatus, 'all');
      expect(state.errorMessage, isNull);
      expect(state.counts['scheduled'], 0);
      expect(state.counts['completed'], 0);
      expect(state.counts['cancelled'], 0);
    });

    test('Counts and copyWith update state properly', () {
      final state = SchedulesState(
        schedules: [item1, item2],
        counts: const {
          'scheduled': 1,
          'completed': 1,
          'cancelled': 0,
        },
        filterStatus: 'all',
      );

      expect(state.counts['scheduled'], 1);
      expect(state.counts['completed'], 1);
      expect(state.counts['cancelled'], 0);
      expect(state.schedules.length, 2);

      final filteredState = state.copyWith(filterStatus: 'scheduled');
      expect(filteredState.filterStatus, 'scheduled');
      expect(filteredState.schedules.length, 2);
    });
  });

  group('SchedulesScreen Widget Tests', () {
    testWidgets('Renders screen title, summary cards and FAB', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SchedulesScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Scheduled SMS'), findsOneWidget);
      expect(find.text('Upcoming'), findsNWidgets(2));
      expect(find.text('Completed'), findsNWidgets(2));
      expect(find.text('Cancelled'), findsNWidgets(2));
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('ScheduleSmsSheet renders input fields, date/time pickers and Schedule SMS button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ScheduleSmsSheet(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Schedule SMS'), findsWidgets);
      expect(find.text('Receiver Mobile Number'), findsOneWidget);
      expect(find.text('Message Body'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget);
      expect(find.byIcon(Icons.access_time_rounded), findsOneWidget);
    });

    testWidgets('ScheduleSmsSheet renders in edit mode with prefilled values', (WidgetTester tester) async {
      final existingSchedule = ScheduledSmsModel(
        id: 999,
        userId: 1,
        receiverNumber: '9876543210',
        message: 'Existing message to edit',
        scheduledAt: DateTime.now().add(const Duration(hours: 2)),
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ScheduleSmsSheet(scheduleToEdit: existingSchedule),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Edit Scheduled SMS'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Existing message to edit'), findsOneWidget);
    });

    testWidgets('AnimatedTimelineItem mounts and executes transition without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedTimelineItem(
              child: Text('Timeline item animated content'),
            ),
          ),
        ),
      );

      expect(find.text('Timeline item animated content'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text('Timeline item animated content'), findsOneWidget);
    });

    testWidgets('AnimatedTimelineItem plays destruction sequence without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedTimelineItem(
              isDestroying: true,
              child: Text('Destroying Item'),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
    });
  });
}
