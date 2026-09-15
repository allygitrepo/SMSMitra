import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_app/shared/widgets/gradient_button.dart';
import 'package:sms_app/shared/widgets/custom_text_field.dart';

void main() {
  group('Shared Widgets Unit & Widget Tests', () {
    testWidgets('GradientButton renders text and triggers callback', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GradientButton(
              text: 'Send SMS',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Send SMS'), findsOneWidget);
      await tester.tap(find.byType(GradientButton));
      expect(pressed, isTrue);
    });

    testWidgets('GradientButton displays loader when isLoading is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GradientButton(
              text: 'Send SMS',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Send SMS'), findsNothing);
    });

    testWidgets('CustomTextField renders label, hint, and icon', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              label: 'Phone Number',
              hint: '+91 9876543210',
              icon: Icons.phone,
              controller: controller,
            ),
          ),
        ),
      );

      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('+91 9876543210'), findsOneWidget);
      expect(find.byIcon(Icons.phone), findsOneWidget);
    });
  });
}
