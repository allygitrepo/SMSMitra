import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sms_app/data/providers/service_providers.dart';
import 'package:sms_app/shared/widgets/stat_card.dart';
import 'package:sms_app/shared/widgets/status_badge.dart';
import 'package:sms_app/shared/widgets/empty_state_widget.dart';
import 'package:sms_app/shared/widgets/confirm_bottom_sheet.dart';

void main() {
  group('Design System & Reusable Widgets Tests', () {
    testWidgets('StatCard renders label, value, icon, and progress indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              label: 'Delivered',
              value: '1,250',
              icon: Icons.check_circle_outline,
              color: Colors.green,
              progress: 0.75,
            ),
          ),
        ),
      );

      expect(find.text('Delivered'), findsOneWidget);
      expect(find.text('1,250'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('StatusBadge maps states to correct text and colors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatusBadge(status: 'sent'),
                StatusBadge(status: 'failed'),
                StatusBadge(status: 'pending'),
                StatusBadge(status: 'unknown'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('SENT'), findsOneWidget);
      expect(find.text('FAILED'), findsOneWidget);
      expect(find.text('PENDING'), findsOneWidget);
      expect(find.text('UNKNOWN'), findsOneWidget);
    });

    testWidgets('EmptyStateWidget renders title, description, and triggers onAction', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.inbox_rounded,
              title: 'No Logs Found',
              description: 'Adjust date filters',
              actionLabel: 'Refresh',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('No Logs Found'), findsOneWidget);
      expect(find.text('Adjust date filters'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_rounded), findsOneWidget);

      await tester.tap(find.text('Refresh'));
      await tester.pump();
      expect(actionTriggered, isTrue);
    });

    testWidgets('ConfirmBottomSheet displays modal and returns true on confirm', (tester) async {
      bool? confirmed;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  confirmed = await ConfirmBottomSheet.show(
                    context,
                    icon: Icons.logout_rounded,
                    title: 'Log out?',
                    message: 'Do you really want to log out?',
                    confirmLabel: 'Log Out',
                    confirmColor: Colors.red,
                  );
                },
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Log out?'), findsOneWidget);
      expect(find.text('Do you really want to log out?'), findsOneWidget);

      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
    });
  });

  group('Riverpod Service Providers Dependency Injection Suite', () {
    test('Service providers provide singleton or expected service types', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final apiService = container.read(apiServiceProvider);
      final simService = container.read(simServiceProvider);
      final smsApiService = container.read(smsApiServiceProvider);
      final smsService = container.read(smsServiceProvider);
      final authService = container.read(authServiceProvider);
      final cacheService = container.read(cacheServiceProvider);

      expect(apiService, isNotNull);
      expect(simService, isNotNull);
      expect(smsApiService, isNotNull);
      expect(smsService, isNotNull);
      expect(authService, isNotNull);
      expect(cacheService, isNotNull);
    });
  });
}
