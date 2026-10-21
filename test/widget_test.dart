import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/app.dart';

void main() {
  testWidgets('App boots to the login page', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.text('Üdvözlünk vissza!'), findsOneWidget);
    expect(find.text('Jelentkezz be a folytatáshoz'), findsOneWidget);
    expect(find.text('Bejelentkezés'), findsOneWidget);
    expect(find.text('Regisztráció'), findsOneWidget);
  });

  testWidgets('Login form surfaces validation errors on empty submit',
      (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

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

  testWidgets('Password visibility toggle flips the icon',
      (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pump();
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
  });
}
