import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_app/core/routes/app_router.dart';

void main() {
  group('Navigation & Routing Unit & Widget Tests', () {
    test('AppRouter defines all standard application routes', () {
      expect(AppRouter.splash, equals('/'));
      expect(AppRouter.login, equals('/login'));
      expect(AppRouter.register, equals('/register'));
      expect(AppRouter.home, equals('/home'));
      expect(AppRouter.settings, equals('/settings'));
      expect(AppRouter.setupSim, equals('/setup-sim'));
    });

    testWidgets('NotFoundScreen renders 404 header and path information', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NotFoundScreen(path: '/invalid-unknown-url'),
        ),
      );

      expect(find.text('404 - Page Not Found'), findsOneWidget);
      expect(find.textContaining('/invalid-unknown-url'), findsOneWidget);
      expect(find.text('Return Home'), findsOneWidget);
      expect(find.byIcon(Icons.explore_off_outlined), findsOneWidget);
    });

    test('AppRouteObserver registers without error', () {
      final observer = AppRouteObserver();
      expect(observer, isNotNull);
    });
  });
}
