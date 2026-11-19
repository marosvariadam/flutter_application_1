// The paths the screens push are registered in the app's route table and
// build their page, instead of landing on GoRouter's "page not found".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:flutter_application_1/app/app_router.dart';
import 'package:flutter_application_1/features/coach/presentation/athlete_detail_page.dart';
import 'package:flutter_application_1/features/exercise/data/models/exercise_model.dart';
import 'package:flutter_application_1/features/exercise/presentation/exercise_catalogue_page.dart';
import 'package:flutter_application_1/features/exercise/presentation/exercise_form_page.dart';
import 'package:flutter_application_1/features/profiles/presentation/profiles_page.dart';
import 'package:flutter_application_1/features/session/presentation/session_page.dart';
import 'package:flutter_application_1/features/workout/presentation/workout_calendar_page.dart';
import 'package:flutter_application_1/features/workout/presentation/workout_detail_page.dart';
import 'package:flutter_application_1/features/workout/presentation/workout_form_page.dart';
import 'package:flutter_application_1/features/workout/presentation/workout_review_page.dart';

import '../a11y/page_harness.dart';

/// Opens [location] through the app's routes. [start], when given, is
/// mounted at `/` so a test can tap the entry point on a real caller.
Future<void> _open(
  WidgetTester tester,
  String location, {
  Role role = Role.trainer,
  Widget? start,
}) =>
    pumpAppPage(
      tester,
      const SizedBox(),
      role: role,
      textScale: 1,
      initialLocation: location,
      routes: [
        if (start != null) GoRoute(path: '/', builder: (_, __) => start),
        ...buildAppRoutes(),
      ],
    );

T _page<T extends Widget>(WidgetTester tester) =>
    tester.widget<T>(find.byType(T));

GoRouter _router(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).last));

const _squat = ExerciseModel(
  id: 'e1',
  name: 'Saját guggolás',
  muscleGroup: 'Láb',
  description: 'Lassú leengedés.',
  createdByTrainerId: 't1',
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('hu');
    await loadRealFonts();
  });

  group('útvonalak', () {
    testWidgets('/workout/calendar', (tester) async {
      await _open(tester, '/workout/calendar', role: Role.athlete);
      expect(find.byType(WorkoutCalendarPage), findsOneWidget);
    });

    testWidgets('/workout/:id/edit', (tester) async {
      await _open(tester, '/workout/w-next/edit');
      expect(_page<WorkoutFormPage>(tester).workoutId, 'w-next');
      expect(find.text('Edzés szerkesztése'), findsOneWidget);
    });

    testWidgets('/exercise-catalogue böngészés és választás', (tester) async {
      await _open(tester, '/exercise-catalogue');
      expect(_page<ExerciseCataloguePage>(tester).selectionMode, isFalse);

      _router(tester).go('/exercise-catalogue?select=true');
      await settleData(tester);
      expect(_page<ExerciseCataloguePage>(tester).selectionMode, isTrue);
    });

    testWidgets('/exercise/new', (tester) async {
      await _open(tester, '/exercise/new');
      expect(_page<ExerciseFormPage>(tester).exerciseId, isNull);
      expect(find.text('Új gyakorlat'), findsOneWidget);
    });

    testWidgets('/exercise/:id/edit a gyakorlattal kitöltve', (tester) async {
      await _open(tester, '/exercise-catalogue');
      _router(tester).push('/exercise/e1/edit', extra: _squat);
      await settleData(tester);

      final form = _page<ExerciseFormPage>(tester);
      expect(form.exerciseId, 'e1');
      expect(form.initialName, 'Saját guggolás');
      expect(form.initialMuscleGroup, 'Láb');
      expect(form.initialDescription, 'Lassú leengedés.');
    });

    testWidgets('/exercise/:id/edit gyakorlat nélkül a katalógusra visz',
        (tester) async {
      await _open(tester, '/exercise/e1/edit');
      expect(find.byType(ExerciseFormPage), findsNothing);
      expect(find.byType(ExerciseCataloguePage), findsOneWidget);
    });

    testWidgets('/athlete-detail/:id/review', (tester) async {
      await _open(tester, '/athlete-detail/a1/review');
      expect(_page<WorkoutReviewPage>(tester).athleteId, 'a1');
    });
  });

  group('belépési pontok', () {
    testWidgets('Edzés fül: naptár ikon', (tester) async {
      await _open(tester, '/', role: Role.athlete, start: const SessionsPage());

      await tester.tap(find.byTooltip('Naptár'));
      await settleData(tester);
      expect(find.byType(WorkoutCalendarPage), findsOneWidget);
    });

    testWidgets('naptár: edzés kártya a részletekre visz', (tester) async {
      await _open(tester, '/workout/calendar', role: Role.athlete);

      // The fixture has a workout today ('w-today'); select today's cell.
      await tester.tap(find.text('${DateTime.now().day}').first);
      await settleData(tester);
      await tester.tap(
          find.text('Alsótest – erő és robbanékonyság fejlesztése').first);
      await settleData(tester);
      expect(_page<WorkoutDetailPage>(tester).workoutId, 'w-today');
    });

    testWidgets('atléta adatlap: visszajelzések gomb', (tester) async {
      await _open(tester, '/',
          start: const AthleteDetailPage(athleteId: 'a1'));

      await tester.ensureVisible(find.text('Visszajelzések'));
      await tester.tap(find.text('Visszajelzések'));
      await settleData(tester);
      expect(_page<WorkoutReviewPage>(tester).athleteId, 'a1');
    });

    testWidgets('edző profil: gyakorlatkönyvtár', (tester) async {
      await _open(tester, '/', start: const ProfilesPage());

      await tester.ensureVisible(find.text('Gyakorlatkönyvtár'));
      await tester.tap(find.text('Gyakorlatkönyvtár'));
      await settleData(tester);
      expect(_page<ExerciseCataloguePage>(tester).selectionMode, isFalse);
    });

    testWidgets('edzés részletei: szerkesztés gomb (edző)', (tester) async {
      await _open(tester, '/',
          start: const WorkoutDetailPage(workoutId: 'w-next'));

      await tester.tap(find.byTooltip('Szerkesztés'));
      await settleData(tester);
      expect(_page<WorkoutFormPage>(tester).workoutId, 'w-next');
    });

    testWidgets('katalógus választó visszaadja a gyakorlatot', (tester) async {
      ExerciseModel? picked;
      await _open(
        tester,
        '/',
        start: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => picked = await context
                  .push<ExerciseModel>('/exercise-catalogue?select=true'),
              child: const Text('Katalógus'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Katalógus'));
      await settleData(tester);
      await tester.tap(find.text('Fekvenyomás döntött padon').first);
      await settleData(tester);

      expect(find.byType(ExerciseCataloguePage), findsNothing);
      expect(picked?.id, 'e1');
    });
  });
}
