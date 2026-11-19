import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/training_plan/data/models/plan_results.dart';
import 'package:flutter_application_1/features/training_plan/data/models/training_plan_model.dart';
import 'package:flutter_application_1/features/training_plan/data/models/violation_model.dart';
import 'package:flutter_application_1/features/training_plan/presentation/widgets/plan_result_view.dart';

TrainingPlanModel _plan({List<PlanDayModel> days = const []}) =>
    TrainingPlanModel(
      id: 'p1',
      trainerId: 't1',
      athleteId: 'a1',
      title: 'Hipertrófia – 4 hét',
      goal: 'Hypertrophy',
      weeks: 4,
      split: PlanSplits.upperLower,
      status: PlanStatuses.draft,
      days: days,
      progression: PlanProgressionSchemes.doubleProgression,
      source: PlanGenerationSources.hybrid,
      createdAt: DateTime.utc(2026, 11, 1),
    );

const _day = PlanDayModel(dayIndex: 0, label: 'Felső A', exercises: [
  PlannedExerciseModel(
    exerciseId: 'e1',
    name: 'Fekvenyomás',
    muscleGroup: 'Chest',
    sets: 3,
    repMin: 6,
    repMax: 10,
    targetRpe: 8,
    restSeconds: 120,
    order: 0,
  ),
]);

GenerateResultModel _result({
  List<PlanDayModel> days = const [_day],
  List<ViolationModel> errors = const [],
  List<ViolationModel> warnings = const [],
  List<CandidateSummaryModel> candidates = const [],
  bool usedPredictor = true,
}) =>
    GenerateResultModel(
      plan: _plan(days: days),
      predictedScore: 0.78,
      usedPredictor: usedPredictor,
      warnings: warnings,
      errors: errors,
      candidates: candidates,
    );

Future<void> _pump(WidgetTester tester, GenerateResultModel result,
    {VoidCallback? onRestart, VoidCallback? onOpenEditor}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: PlanResultView(
        result: result,
        onRestart: onRestart ?? () {},
        onOpenEditor: onOpenEditor ?? () {},
      ),
    ),
  ));
}

void main() {
  testWidgets('shows the plan summary, score and days', (tester) async {
    await _pump(tester, _result());
    expect(find.text('Hipertrófia – 4 hét'), findsOneWidget);
    expect(find.text('Piszkozat'), findsOneWidget);
    expect(find.text('Előrejelzett fejlődés: 0.78'), findsOneWidget);
    expect(find.text('1. nap · Felső A'), findsOneWidget);
    expect(find.text('3 × 6–10 @ RPE 8'), findsOneWidget);
    expect(find.textContaining('Alternatívák'), findsNothing);
  });

  testWidgets('without the ML model the score is labelled as CP-SAT',
      (tester) async {
    await _pump(tester, _result(usedPredictor: false));
    expect(find.text('Pontszám (CP-SAT objektum): 0.78'), findsOneWidget);
  });

  testWidgets('violations lead with Hungarian rule names', (tester) async {
    await _pump(
      tester,
      _result(
        errors: const [
          ViolationModel(
            code: ViolationCodes.volumeAboveMrv,
            severity: ViolationSeverity.error,
            message: 'Shoulders weekly volume 24 sets > MRV 22.',
          ),
        ],
        warnings: const [
          ViolationModel(
            code: ViolationCodes.duplicateInDay,
            severity: ViolationSeverity.warning,
            message: "'Squat' appears more than once on day 1.",
            dayIndex: 1,
          ),
        ],
      ),
    );
    expect(find.text('Hibák (1)'), findsOneWidget);
    expect(find.text('• Heti volumen a maximum (MRV) felett'), findsOneWidget);
    expect(find.text('Shoulders weekly volume 24 sets > MRV 22.'),
        findsOneWidget);
    expect(find.text('Figyelmeztetések (1)'), findsOneWidget);
    expect(find.text('• 2. nap — Ismétlődő gyakorlat egy napon'),
        findsOneWidget);
  });

  testWidgets('candidates are compared only when there is more than one',
      (tester) async {
    await _pump(
      tester,
      _result(candidates: const [
        CandidateSummaryModel(
            title: 'A', score: 0.78, usedPredictor: true, daysCount: 4),
        CandidateSummaryModel(
            title: 'B', score: 0.61, usedPredictor: true, daysCount: 4),
      ]),
    );
    expect(find.text('Alternatívák (2)'), findsOneWidget);
    expect(find.text('mentett'), findsOneWidget);
    expect(find.text('0.61'), findsOneWidget);
  });

  testWidgets('an empty plan explains what to try instead', (tester) async {
    await _pump(tester, _result(days: const []));
    expect(find.textContaining('nem tartalmaz edzésnapokat'), findsOneWidget);
  });

  testWidgets('buttons call back', (tester) async {
    var restarts = 0, opens = 0;
    await _pump(tester, _result(),
        onRestart: () => restarts++, onOpenEditor: () => opens++);
    await tester.tap(find.text('Újragenerálás'));
    await tester.tap(find.text('Szerkesztő'));
    expect([restarts, opens], [1, 1]);
  });
}
