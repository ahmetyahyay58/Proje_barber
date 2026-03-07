// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:project_barber/app/app.dart';

void main() {
  testWidgets('App opens role select after splash', (WidgetTester tester) async {
    await tester.pumpWidget(const ProjectBarberApp());

    // Splash is visible first.
    expect(find.text('Project Barber'), findsOneWidget);

    // Advance time to pass splash timer.
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    // Role selection screen should be visible.
    expect(find.text('Giriş Seçimi'), findsOneWidget);
  });
}
