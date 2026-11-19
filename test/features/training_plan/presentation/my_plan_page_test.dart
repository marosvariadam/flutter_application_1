import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_application_1/features/training_plan/bloc/my_plans_cubit.dart';
import 'package:flutter_application_1/features/training_plan/data/models/training_plan_model.dart';
import 'package:flutter_application_1/features/training_plan/data/repositories/training_plan_repository.dart';
import 'package:flutter_application_1/features/training_plan/presentation/my_plan_page.dart';
import 'package:flutter_application_1/features/training_plan/presentation/widgets/my_plan_section.dart';

class _MockRepo extends Mock implements TrainingPlanRepository {}

TrainingPlanModel _plan(String id, String title, DateTime createdAt) =>
    TrainingPlanModel(
      id: id,
      trainerId: 't1',
      athleteId: 'a1',
      title: title,
      goal: 'Hypertrophy',
      weeks: 4,
      split: PlanSplits.upperLower,
      status: PlanStatuses.accepted,
      progression: PlanProgressionSchemes.doubleProgression,
      source: PlanGenerationSources.hybrid,
      createdAt: createdAt,
      days: const [
        PlanDayModel(dayIndex: 0, label: 'Felső A', exercises: [
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
            notes: 'Könyök a törzs mellett.',
          ),
        ]),
        PlanDayModel(dayIndex: 1, label: 'Alsó A', exercises: []),
      ],
    );

void main() {
  late _MockRepo repo;

  setUp(() => repo = _MockRepo());

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(RepositoryProvider<TrainingPlanRepository>.value(
      value: repo,
      child: const MaterialApp(home: MyPlanPage()),
    ));
    await tester.pumpAndSettle();
  }

  group('MyPlanPage', () {
    testWidgets('shows the newest plan read-only with its explanation panel',
        (tester) async {
      when(() => repo.mine()).thenAnswer((_) async => [
            _plan('p1', 'Régi terv', DateTime.utc(2026, 9, 1)),
            _plan('p2', 'Hipertrófia – 4 hét', DateTime.utc(2026, 11, 1)),
          ]);
      await pumpPage(tester);

      expect(find.text('Hipertrófia – 4 hét'), findsOneWidget);
      expect(find.text('Felső A'), findsOneWidget);
      expect(find.text('Fekvenyomás'), findsOneWidget);
      expect(find.text('3 × 6–10 @ RPE 8'), findsOneWidget);
      expect(find.text('Pihenő: 2 perc'), findsOneWidget);
      expect(find.text('Könyök a törzs mellett.'), findsOneWidget);
      expect(find.text('Pihenőnap.'), findsOneWidget);
      expect(find.text('Magyarázat kérése'), findsOneWidget);
      // Read-only: none of the editor's controls are present.
      expect(find.byType(TextField), findsNothing);
      expect(find.byIcon(Icons.swap_horiz), findsNothing);
    });

    testWidgets('switches to an older plan from the chip row', (tester) async {
      when(() => repo.mine()).thenAnswer((_) async => [
            _plan('p1', 'Régi terv', DateTime.utc(2026, 9, 1)),
            _plan('p2', 'Új terv', DateTime.utc(2026, 11, 1)),
          ]);
      await pumpPage(tester);
      expect(find.text('Új terv'), findsOneWidget);

      await tester.tap(find.text('2026.09.01'));
      await tester.pumpAndSettle();

      expect(find.text('Régi terv'), findsOneWidget);
      expect(find.text('Új terv'), findsNothing);
    });

    testWidgets('explains when there is no accepted plan', (tester) async {
      when(() => repo.mine()).thenAnswer((_) async => []);
      await pumpPage(tester);

      expect(find.text('Még nincs elfogadott edzésterved.'), findsOneWidget);
    });

    testWidgets('offers a retry after a failed load', (tester) async {
      when(() => repo.mine()).thenThrow(Exception('boom'));
      await pumpPage(tester);
      expect(find.text('Újra'), findsOneWidget);

      when(() => repo.mine()).thenAnswer(
          (_) async => [_plan('p1', 'Új terv', DateTime.utc(2026, 11, 1))]);
      await tester.tap(find.text('Újra'));
      await tester.pumpAndSettle();
      expect(find.text('Új terv'), findsOneWidget);
    });
  });

  group('MyPlanSection', () {
    Future<void> pumpSection(WidgetTester tester) async {
      final cubit = MyPlansCubit(repo)..load();
      addTearDown(cubit.close);
      final router = GoRouter(routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => Scaffold(
            body: BlocProvider.value(
                value: cubit, child: const MyPlanSection()),
          ),
        ),
        GoRoute(
          path: '/plan/mine',
          builder: (_, __) => const Scaffold(body: Text('plan page')),
        ),
      ]);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
    }

    testWidgets('shows the current plan and opens the plan view',
        (tester) async {
      when(() => repo.mine()).thenAnswer(
          (_) async => [_plan('p1', 'Új terv', DateTime.utc(2026, 11, 1))]);
      await pumpSection(tester);

      expect(find.text('EDZÉSTERVEM'), findsOneWidget);
      expect(find.text('Új terv'), findsOneWidget);
      expect(find.text('4 hét · 2 nap / hét · Elfogadva'), findsOneWidget);

      await tester.tap(find.text('Új terv'));
      await tester.pumpAndSettle();
      expect(find.text('plan page'), findsOneWidget);
    });

    testWidgets('stays hidden without an accepted plan', (tester) async {
      when(() => repo.mine()).thenAnswer((_) async => []);
      await pumpSection(tester);

      expect(find.text('EDZÉSTERVEM'), findsNothing);
    });
  });
}
