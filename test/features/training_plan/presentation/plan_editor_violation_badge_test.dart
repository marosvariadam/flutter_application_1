import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/training_plan/data/models/violation_model.dart';
import 'package:flutter_application_1/features/training_plan/presentation/widgets/plan_editor_violation_badge.dart';

const _error = ViolationModel(
  code: ViolationCodes.stressTagConflict,
  severity: ViolationSeverity.error,
  message: "'Back Squat' loads an avoided region (knee).",
  dayIndex: 1,
  exerciseId: 'e2',
);

const _warning = ViolationModel(
  code: ViolationCodes.frequencyTooLow,
  severity: ViolationSeverity.warning,
  message: 'Chest trained 1 day(s)/week; hypertrophy benefits from 2+.',
);

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('error badge reads "Hiba" with the error icon', (tester) async {
    await tester.pumpWidget(_host(const PlanEditorViolationBadge(violation: _error)));
    expect(find.text('Hiba'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_outlined), findsNothing);
  });

  testWidgets('warning badge reads "Figyelem" with the warning icon',
      (tester) async {
    await tester
        .pumpWidget(_host(const PlanEditorViolationBadge(violation: _warning)));
    expect(find.text('Figyelem'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
  });

  testWidgets('tap opens the Hungarian rule with the backend detail',
      (tester) async {
    await tester.pumpWidget(_host(const PlanEditorViolationBadge(violation: _error)));

    await tester.tap(find.text('Hiba'));
    await tester.pumpAndSettle();

    expect(find.text('Kerülendő terhelés'), findsOneWidget);
    expect(find.text("Részletek: 'Back Squat' loads an avoided region (knee)."),
        findsOneWidget);

    await tester.tap(find.text('Bezárás'));
    await tester.pumpAndSettle();
    expect(find.text('Kerülendő terhelés'), findsNothing);
  });

  testWidgets('a custom onTap replaces the detail sheet', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(
        PlanEditorViolationBadge(violation: _warning, onTap: () => taps++)));
    await tester.tap(find.text('Figyelem'));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(find.text('Ritka izomcsoport-terhelés'), findsNothing);
  });
}
