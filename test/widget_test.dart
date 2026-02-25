import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/app.dart';

void main() {
  testWidgets('Login page renders key elements', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.text('Üdvözlünk vissza!'), findsOneWidget);
    expect(find.text('Bejelentkezés'), findsOneWidget);
    expect(find.text('Regisztráció'), findsOneWidget);
    expect(find.text('Elfelejtett jelszó?'), findsOneWidget);
  });

  testWidgets('Login form shows validation errors on empty submit',
      (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    // Tap login without filling in the form
    await tester.tap(find.text('Bejelentkezés'));
    await tester.pump();

    expect(find.text('Kérjük add meg az email címed'), findsOneWidget);
    expect(find.text('Kérjük add meg a jelszavad'), findsOneWidget);
  });

  testWidgets('Login form validates email format', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email cím'),
      'not-an-email',
    );
    await tester.tap(find.text('Bejelentkezés'));
    await tester.pump();

    expect(find.text('Érvénytelen email cím'), findsOneWidget);
  });

  testWidgets('Password visibility toggle works', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    // Initially the password is hidden (visibility icon shown)
    expect(find.byIcon(Icons.visibility), findsOneWidget);

    // Tap the toggle
    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pump();

    // Now the password is visible (visibility_off icon shown)
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
  });
}
