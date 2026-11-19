import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_application_1/features/autoregulation/data/models/autoregulation_model.dart';
import 'package:flutter_application_1/features/autoregulation/data/repositories/autoregulation_repository.dart';
import 'package:flutter_application_1/features/coach/presentation/workout_builder_page.dart';
import 'package:flutter_application_1/features/exercise/data/models/exercise_model.dart';
import 'package:flutter_application_1/features/exercise/data/repositories/exercise_repository.dart';
import 'package:flutter_application_1/features/trainer/data/models/trainer_request_model.dart';
import 'package:flutter_application_1/features/trainer/data/repositories/roster_repository.dart';
import 'package:flutter_application_1/features/workout/data/repositories/workout_repository.dart';

class _MockRoster extends Mock implements RosterRepository {}

class _MockExercises extends Mock implements ExerciseRepository {}

class _MockWorkouts extends Mock implements WorkoutRepository {}

class _MockAutoreg extends Mock implements AutoregulationRepository {}

const _bench = ExerciseModel(
  id: 'e1',
  name: 'Bench Press',
  muscleGroup: 'Chest',
  equipment: 'Barbell',
);

NextWeekAutoregulationModel _suggestions({bool deload = false}) =>
    NextWeekAutoregulationModel(
      planId: 'p1',
      deloadApplied: deload,
      suggestions: [
        AutoregulationSuggestionModel(
          exerciseId: 'e1',
          name: 'Bench Press',
          muscleGroup: 'Chest',
          scheme: 'DoubleProgression',
          currentReps: '6-10',
          targetRpe: 8,
          suggestedWeightKg: deload ? 72.5 : 82.5,
          suggestedSets: deload ? 2 : 3,
          outcome: deload
              ? AutoregulationOutcomes.deload
              : AutoregulationOutcomes.increase,
          reason: '',
          lastLogged: LastLoggedSessionModel(
            date: DateTime.utc(2026, 11, 12),
            sets: 3,
            reps: 10,
            weightKg: 80,
            rpe: 7.5,
          ),
        ),
      ],
    );

void main() {
  late _MockRoster roster;
  late _MockExercises exercises;
  late _MockWorkouts workouts;
  late _MockAutoreg autoreg;

  setUp(() {
    roster = _MockRoster();
    exercises = _MockExercises();
    workouts = _MockWorkouts();
    autoreg = _MockAutoreg();

    when(() => roster.getAthletes(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        )).thenAnswer((_) async => const PaginatedAthletes(
          items: [
            AthleteModel(
                id: 'a1', firstName: 'Anna', lastName: 'Kiss', email: 'a@x.hu'),
          ],
          total: 1,
          page: 1,
          pageSize: 20,
        ));
    when(() => exercises.getExercises(
          search: any(named: 'search'),
          muscleGroup: any(named: 'muscleGroup'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        )).thenAnswer((_) async => const PaginatedExercises(items: [_bench]));
    when(() => exercises.getExercisesForAthlete(
          any(),
          search: any(named: 'search'),
          muscleGroup: any(named: 'muscleGroup'),
        )).thenAnswer((_) async => [_bench]);
    when(() => workouts.getTrainerReview(any())).thenAnswer((_) async => []);
  });

  Future<void> pumpBuilderWithBench(WidgetTester tester) async {
    // Tall phone-like surface so the lazily built list (banner, cards, add
    // button) is laid out without scrolling.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MultiRepositoryProvider(
      providers: [
        RepositoryProvider<RosterRepository>.value(value: roster),
        RepositoryProvider<ExerciseRepository>.value(value: exercises),
        RepositoryProvider<WorkoutRepository>.value(value: workouts),
        RepositoryProvider<AutoregulationRepository>.value(value: autoreg),
      ],
      child: const MaterialApp(
        home: WorkoutBuilderPage(preselectedAthleteId: 'a1'),
      ),
    ));
    await tester.pumpAndSettle();

    // Add Bench Press through the shared exercise picker sheet.
    await tester.ensureVisible(find.text('Gyakorlat hozzáadása'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gyakorlat hozzáadása'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();
  }

  testWidgets('tapping the chip writes the suggested load into every set',
      (tester) async {
    when(() => autoreg.nextWeek('a1')).thenAnswer((_) async => _suggestions());
    await pumpBuilderWithBench(tester);

    final chip = find.text('+2.5 kg — minden szett RPE 8');
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '82.5'), findsNothing);

    await tester.tap(chip);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, '82.5'), findsNWidgets(3));
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('Deload hét javasolt'), findsNothing);
  });

  testWidgets('deload shows the banner and trims sets when applied',
      (tester) async {
    when(() => autoreg.nextWeek('a1'))
        .thenAnswer((_) async => _suggestions(deload: true));
    await pumpBuilderWithBench(tester);

    expect(find.text('Deload hét javasolt'), findsOneWidget);
    final chip = find.text('Deload: 72.5 kg · 2 szett');
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();

    await tester.tap(chip);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, '72.5'), findsNWidgets(2));
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('no accepted plan means no chip and no banner', (tester) async {
    when(() => autoreg.nextWeek('a1')).thenAnswer((_) async =>
        const NextWeekAutoregulationModel(planId: null, suggestions: []));
    await pumpBuilderWithBench(tester);

    expect(find.textContaining('minden szett'), findsNothing);
    expect(find.text('Deload hét javasolt'), findsNothing);
  });
}
