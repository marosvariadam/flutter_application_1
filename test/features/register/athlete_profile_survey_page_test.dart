import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/register/athlete_profile_survey_page.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester
        .pumpWidget(const MaterialApp(home: AthleteProfileSurveyPage()));
  }

  testWidgets('an empty weight asks for kilograms, not for a choice',
      (tester) async {
    await pump(tester);
    expect(find.text('1 / 8'), findsOneWidget);

    await tester.tap(find.text('Következő'));
    await tester.pump();

    expect(find.text('Add meg a testsúlyodat kilogrammban (pl. 72,5).'),
        findsOneWidget);
    expect(find.text('1 / 8'), findsOneWidget);
  });

  testWidgets('a Hungarian decimal comma weight is accepted', (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), '72,5');
    await tester.tap(find.text('Következő'));
    await tester.pumpAndSettle();

    expect(find.text('2 / 8'), findsOneWidget);
    expect(find.text('Mi a célod?'), findsOneWidget);
  });

  testWidgets('choice steps still ask for a selection', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), '80');
    await tester.tap(find.text('Következő'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Következő'));
    await tester.pump();
    expect(find.text('Kérjük, válassz legalább egy lehetőséget!'),
        findsOneWidget);

    await tester.tap(find.text('Izomépítés'));
    await tester.tap(find.text('Következő'));
    await tester.pumpAndSettle();
    expect(find.text('Edzettségi szinted'), findsOneWidget);
  });
}
