import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_application_1/app/design/dt_colors.dart';
import 'package:flutter_application_1/app/design/theme.dart';
import 'package:flutter_application_1/app/shared/widgets/error_state.dart';
import 'package:flutter_application_1/features/home/presentation/home_page.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/home_skeleton.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/today_workout_card.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/weekly_strip.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';
import 'package:flutter_application_1/features/workout/data/repositories/workout_repository.dart';

class _MockWorkouts extends Mock implements WorkoutRepository {}

WorkoutModel _workoutOn(DateTime day) => WorkoutModel.fromJson({
      'id': 'w1',
      'title': 'Felsőtest',
      'description': 'Nyomó nap',
      'scheduledDate': DateTime(day.year, day.month, day.day, 9).toIso8601String(),
      'difficulty': 'hard',
      'exercises': <Map<String, dynamic>>[],
    });

Widget _host(WorkoutRepository repo, {bool dark = false}) => MaterialApp(
      theme: buildTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: RepositoryProvider<WorkoutRepository>.value(
        value: repo,
        child: const AthleteHomePage(),
      ),
    );

Color _decorationColor(WidgetTester tester, Finder ofText) {
  final box = tester.widget<Container>(
      find.ancestor(of: ofText, matching: find.byType(Container)).first);
  return (box.decoration! as BoxDecoration).color!;
}

void main() {
  late _MockWorkouts repo;
  final today = DateTime.now();

  setUpAll(() => registerFallbackValue(DateTime(2000)));
  setUp(() => repo = _MockWorkouts());

  testWidgets('loads this week with a skeleton, then shows today\'s workout',
      (tester) async {
    final pending = Completer<List<WorkoutModel>>();
    when(() => repo.getAthleteCalendar(any(), any()))
        .thenAnswer((_) => pending.future);

    await tester.pumpWidget(_host(repo));
    expect(find.byType(HomeSkeleton), findsOneWidget);

    final range = verify(() => repo.getAthleteCalendar(captureAny(), captureAny()))
        .captured;
    final monday = WeeklyStrip.weekStart(today);
    expect(range[0], monday);
    expect(range[1], DateTime(monday.year, monday.month, monday.day + 7));

    pending.complete([_workoutOn(today)]);
    await tester.pump();

    expect(find.byType(HomeSkeleton), findsNothing);
    expect(find.byType(TodayWorkoutCard), findsOneWidget);
    expect(find.text('Felsőtest'), findsOneWidget);
    expect(find.text('Nehéz'), findsOneWidget);
    expect(find.text('Ezen a héten'), findsOneWidget);
    expect(find.text('Fejlődésem'), findsOneWidget);
  });

  testWidgets('picking a day without a workout shows the rest-day card',
      (tester) async {
    when(() => repo.getAthleteCalendar(any(), any()))
        .thenAnswer((_) async => [_workoutOn(today)]);
    await tester.pumpWidget(_host(repo));
    await tester.pump();

    final monday = WeeklyStrip.weekStart(today);
    final other = today.weekday == DateTime.monday
        ? DateTime(monday.year, monday.month, monday.day + 1)
        : monday;
    await tester.tap(find.text(DateFormat('d').format(other)));
    await tester.pump();

    expect(find.byType(TodayWorkoutCard), findsNothing);
    expect(find.byType(RestDayCard), findsOneWidget);
    expect(find.text('Pihenőnap'), findsOneWidget);
  });

  testWidgets('a failed load shows a Hungarian error and retry reloads',
      (tester) async {
    var calls = 0;
    when(() => repo.getAthleteCalendar(any(), any())).thenAnswer((_) async {
      calls++;
      if (calls == 1) {
        throw DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionError,
        );
      }
      return <WorkoutModel>[];
    });

    await tester.pumpWidget(_host(repo));
    await tester.pump();

    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.text('Nem sikerült betölteni az edzéseidet'), findsOneWidget);
    expect(find.text('Nincs internetkapcsolat, vagy a szerver nem érhető el.'),
        findsOneWidget);

    await tester.tap(find.text('Újra'));
    await tester.pump();
    await tester.pump();

    expect(calls, 2);
    expect(find.byType(ErrorState), findsNothing);
    expect(find.byType(RestDayCard), findsOneWidget);
  });

  testWidgets('dark theme uses the dark palette', (tester) async {
    when(() => repo.getAthleteCalendar(any(), any()))
        .thenAnswer((_) async => [_workoutOn(today)]);
    await tester.pumpWidget(_host(repo, dark: true));
    await tester.pump();

    const c = DTColors.dark;
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, c.bg);
    // Selected (today's) pill and the difficulty badge.
    expect(
        _decorationColor(tester, find.text(DateFormat('d').format(today))),
        c.accentPrimary);
    expect(_decorationColor(tester, find.text('Nehéz')), c.difficultyHard);
    expect(tester.widget<Text>(find.text('Felsőtest')).style?.color,
        c.textPrimary);
  });
}
