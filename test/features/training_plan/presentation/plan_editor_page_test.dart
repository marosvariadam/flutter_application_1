import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_application_1/features/athlete_profile/data/models/athlete_profile_model.dart';
import 'package:flutter_application_1/features/athlete_profile/data/repositories/athlete_profile_repository.dart';
import 'package:flutter_application_1/features/exercise/data/repositories/exercise_repository.dart';
import 'package:flutter_application_1/features/training_plan/data/models/plan_results.dart';
import 'package:flutter_application_1/features/training_plan/data/models/training_plan_model.dart';
import 'package:flutter_application_1/features/training_plan/data/models/violation_model.dart';
import 'package:flutter_application_1/features/training_plan/data/repositories/training_plan_repository.dart';
import 'package:flutter_application_1/features/training_plan/presentation/plan_editor_page.dart';

class _MockPlans extends Mock implements TrainingPlanRepository {}

class _MockProfiles extends Mock implements AthleteProfileRepository {}

class _MockExercises extends Mock implements ExerciseRepository {}

PlannedExerciseModel _ex({int sets = 3}) => PlannedExerciseModel(
      exerciseId: 'e1',
      name: 'Fekvenyomás',
      muscleGroup: 'Chest',
      sets: sets,
      repMin: 6,
      repMax: 10,
      targetRpe: 8,
      restSeconds: 120,
      order: 0,
    );

TrainingPlanModel _plan({String status = PlanStatuses.draft, int sets = 3}) =>
    TrainingPlanModel(
      id: 'p1',
      trainerId: 't1',
      athleteId: 'a1',
      title: 'Felső/alsó – 4 hét',
      goal: 'Hypertrophy',
      weeks: 4,
      split: PlanSplits.upperLower,
      status: status,
      days: [
        PlanDayModel(dayIndex: 0, label: 'Felső A', exercises: [_ex(sets: sets)]),
      ],
      progression: PlanProgressionSchemes.doubleProgression,
      source: PlanGenerationSources.hybrid,
      createdAt: DateTime.utc(2026, 11, 19),
    );

const _sessionTooLong = ViolationModel(
  code: ViolationCodes.sessionTooLong,
  severity: ViolationSeverity.error,
  message: 'Day 0 estimated 95 min, limit 60 min.',
  dayIndex: 0,
  exerciseId: 'e1',
);

const _lowFrequency = ViolationModel(
  code: ViolationCodes.frequencyTooLow,
  severity: ViolationSeverity.warning,
  message: 'Chest trained 1 day(s)/week.',
);

void main() {
  late _MockPlans plans;
  late _MockProfiles profiles;

  setUpAll(() async {
    await initializeDateFormatting('hu');
    registerFallbackValue(<PlanDayModel>[]);
    registerFallbackValue(DateTime.utc(2026));
  });

  setUp(() {
    plans = _MockPlans();
    profiles = _MockProfiles();
    when(() => profiles.getForAthlete('a1')).thenAnswer((_) async =>
        const AthleteProfileModel(
          athleteId: 'a1',
          goal: AthleteProfileGoals.hypertrophy,
          experienceLevel: AthleteProfileExperienceLevels.intermediate,
          daysPerWeek: 1,
          sessionMinutes: 60,
        ));
    when(() => plans.validate('p1')).thenAnswer((_) async =>
        const ValidationResultModel(warnings: [], errors: []));
  });

  Future<void> pump(WidgetTester tester, TrainingPlanModel? plan) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => PlanEditorPage(plan: plan)),
      GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('edzői kezdőlap'))),
    ]);
    await tester.pumpWidget(MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TrainingPlanRepository>.value(value: plans),
        RepositoryProvider<AthleteProfileRepository>.value(value: profiles),
        RepositoryProvider<ExerciseRepository>.value(value: _MockExercises()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
  }

  // ElevatedButton.icon builds a private subclass, so match by supertype.
  ButtonStyleButton acceptButton(WidgetTester tester) =>
      tester.widget<ButtonStyleButton>(find
          .ancestor(
              of: find.text('Elfogad + Ütemez'),
              matching: find.byWidgetPredicate((w) => w is ButtonStyleButton))
          .first);

  testWidgets('without plan data it explains how to open the editor',
      (tester) async {
    await pump(tester, null);
    expect(find.text('A terv nem nyitható meg'), findsOneWidget);
    expect(find.text('Vissza'), findsOneWidget);
    verifyNever(() => plans.validate(any()));
  });

  testWidgets('violations found on open block Accept and mark the row',
      (tester) async {
    when(() => plans.validate('p1')).thenAnswer((_) async =>
        const ValidationResultModel(
            warnings: [_lowFrequency], errors: [_sessionTooLong]));
    await pump(tester, _plan());

    expect(find.text('1 Hiba'), findsOneWidget);
    expect(find.text('1 Figyelem'), findsOneWidget);
    expect(acceptButton(tester).onPressed, isNull);
    expect(find.text('Hibákat kell javítani az elfogadás előtt.'),
        findsOneWidget);

    // Row badge → Hungarian rule name with the backend detail.
    await tester.tap(find.text('Hiba'));
    await tester.pumpAndSettle();
    expect(find.text('Túl hosszú edzés'), findsOneWidget);
    expect(find.text('Részletek: Day 0 estimated 95 min, limit 60 min.'),
        findsOneWidget);
  });

  testWidgets('shows chart, explanation and refine bar for a clean plan',
      (tester) async {
    await pump(tester, _plan());
    expect(find.text('Heti volumen'), findsOneWidget);
    expect(find.text('MEV alatt'), findsOneWidget);
    expect(find.text('Magyarázat kérése'), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);
    expect(acceptButton(tester).onPressed, isNotNull);
  });

  testWidgets('editing a field saves it after the debounce', (tester) async {
    when(() => plans.update(
          planId: any(named: 'planId'),
          title: any(named: 'title'),
          weeks: any(named: 'weeks'),
          split: any(named: 'split'),
          days: any(named: 'days'),
        )).thenAnswer((_) async => RefineResultModel(
        plan: _plan(sets: 4), warnings: const [], errors: const []));
    await pump(tester, _plan());

    await tester.enterText(find.widgetWithText(TextField, '3'), '4');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    final days = verify(() => plans.update(
          planId: 'p1',
          title: any(named: 'title'),
          weeks: any(named: 'weeks'),
          split: any(named: 'split'),
          days: captureAny(named: 'days'),
        )).captured.single as List<PlanDayModel>;
    expect(days.single.exercises.single.sets, 4);
  });

  testWidgets('refine can be undone', (tester) async {
    when(() => plans.refine(
          planId: any(named: 'planId'),
          instruction: any(named: 'instruction'),
        )).thenAnswer((_) async => RefineResultModel(
          plan: _plan(sets: 5),
          warnings: const [],
          errors: const [],
          diff: const [DayDiffModel(dayIndex: 0, added: ['x'], removed: ['y'])],
        ));
    when(() => plans.update(
          planId: any(named: 'planId'),
          title: any(named: 'title'),
          weeks: any(named: 'weeks'),
          split: any(named: 'split'),
          days: any(named: 'days'),
        )).thenAnswer((_) async => RefineResultModel(
        plan: _plan(), warnings: const [], errors: const []));
    await pump(tester, _plan());

    await tester.enterText(
        find.widgetWithText(TextField, '').last, 'több vállgyakorlat');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    verify(() => plans.refine(planId: 'p1', instruction: 'több vállgyakorlat'))
        .called(1);
    expect(find.text('A legutóbbi finomítás visszavonható.'), findsOneWidget);
    expect(find.widgetWithText(TextField, '5'), findsOneWidget);

    await tester.tap(find.text('Visszavonás'));
    await tester.pumpAndSettle();
    expect(find.text('A legutóbbi finomítás visszavonható.'), findsNothing);
    expect(find.widgetWithText(TextField, '3'), findsOneWidget);

    // Let the 3 s refine highlight timer run out.
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('accept + schedule runs in order and opens the calendar',
      (tester) async {
    when(() => plans.accept('p1'))
        .thenAnswer((_) async => _plan(status: PlanStatuses.accepted));
    when(() => plans.materialize(
          planId: any(named: 'planId'),
          startDate: any(named: 'startDate'),
        )).thenAnswer((_) async => MaterializeResultModel(
          planId: 'p1',
          workoutsCreated: 4,
          scheduledFrom: DateTime.utc(2026, 11, 23),
          scheduledTo: DateTime.utc(2026, 12, 14),
        ));
    await pump(tester, _plan());

    await tester.tap(find.text('Elfogad + Ütemez').first);
    await tester.pumpAndSettle();
    expect(find.text('Elfogadás és ütemezés'), findsOneWidget);

    await tester.tap(find.text('Elfogad + Ütemez').last);
    await tester.pumpAndSettle();

    verifyInOrder([
      () => plans.accept('p1'),
      () => plans.materialize(planId: 'p1', startDate: any(named: 'startDate')),
    ]);
    expect(find.text('edzői kezdőlap'), findsOneWidget);
    expect(find.text('Ütemezve: 4 edzés létrehozva.'), findsOneWidget);
  });
}
