import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/design/dt_colors.dart';
import 'package:flutter_application_1/app/design/theme.dart';
import 'package:flutter_application_1/app/shared/widgets/progress_ring.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/home_entry_card.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/today_workout_card.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/weekly_strip.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';
import 'package:flutter_application_1/features/workout/presentation/widgets/workout_colors.dart';

Widget _host(Widget child, {bool dark = false}) => MaterialApp(
      theme: buildTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

WorkoutModel _workout(String difficulty,
        {String status = 'Planned', int exercises = 0, int done = 0}) =>
    WorkoutModel.fromJson({
      'id': 'w1',
      'title': 'Láb nap',
      'scheduledDate': '2026-11-19T09:00:00',
      'difficulty': difficulty,
      'status': status,
      'exercises': [
        for (var i = 0; i < exercises; i++)
          {
            'exerciseId': 'e$i',
            'name': 'Guggolás $i',
            'sets': 3,
            'targetReps': 8,
            'targetWeightKg': 60,
            if (i < done) 'actualSets': 3,
          },
      ],
    });

Color _boxColor(WidgetTester tester, String label) {
  final box = tester.widget<Container>(find
      .ancestor(of: find.text(label), matching: find.byType(Container))
      .first);
  return (box.decoration! as BoxDecoration).color!;
}

void main() {
  group('WeeklyStrip.weekStart', () {
    test('returns Monday 00:00 of the week', () {
      expect(WeeklyStrip.weekStart(DateTime(2026, 11, 19, 23, 59)),
          DateTime(2026, 11, 16));
      expect(WeeklyStrip.weekStart(DateTime(2026, 11, 16, 0, 1)),
          DateTime(2026, 11, 16));
      expect(WeeklyStrip.weekStart(DateTime(2026, 11, 22, 12)),
          DateTime(2026, 11, 16));
    });

    test('crosses month and DST boundaries by calendar day', () {
      // 1 March 2026 is a Sunday.
      expect(WeeklyStrip.weekStart(DateTime(2026, 3, 1, 8)),
          DateTime(2026, 2, 23));
      // EU clocks go forward on Sunday 29 March 2026.
      expect(WeeklyStrip.weekStart(DateTime(2026, 3, 29, 0, 30)),
          DateTime(2026, 3, 23));
    });

    test('dayKey ignores the time of day', () {
      expect(WeeklyStrip.dayKey(DateTime(2026, 11, 19, 7)),
          WeeklyStrip.dayKey(DateTime(2026, 11, 19, 22, 30)));
    });
  });

  for (final dark in [false, true]) {
    final theme = dark ? 'dark' : 'light';
    final c = dark ? DTColors.dark : DTColors.light;

    group('TodayWorkoutCard ($theme)', () {
      final levels = {
        'easy': ('Könnyű', c.difficultyEasy),
        'moderate': ('Közepes', c.difficultyMedium),
        'hard': ('Nehéz', c.difficultyHard),
        'intense': ('Intenzív', c.difficultyIntense),
      };
      levels.forEach((json, expected) {
        testWidgets('$json chip uses the theme difficulty color',
            (tester) async {
          await tester.pumpWidget(_host(
            TodayWorkoutCard(workout: _workout(json), onTap: () {}),
            dark: dark,
          ));
          expect(find.byType(DifficultyChip), findsOneWidget);
          expect(_boxColor(tester, expected.$1),
              expected.$2.withValues(alpha: 0.15));
          expect(tester.widget<Text>(find.text(expected.$1)).style?.color,
              expected.$2);
        });
      });

      testWidgets('shows the title, meta row and opens on tap',
          (tester) async {
        var taps = 0;
        await tester.pumpWidget(_host(
          TodayWorkoutCard(workout: _workout('hard'), onTap: () => taps++),
          dark: dark,
        ));
        expect(tester.widget<Text>(find.text('Láb nap')).style?.color,
            c.textPrimary);
        expect(find.text('0 gyakorlat'), findsOneWidget);
        expect(find.text('0 sorozat'), findsOneWidget);

        await tester.tap(find.text('Láb nap'));
        expect(taps, 1);
      });
    });

    Color leftBar(WidgetTester tester) {
      final bar = tester.widget<Container>(find
          .descendant(
              of: find.byType(TodayWorkoutCard),
              matching: find.byType(Container))
          .first);
      return ((bar.decoration! as BoxDecoration).border! as Border).left.color;
    }

    testWidgets('progress ring counts completed exercises ($theme)',
        (tester) async {
      await tester.pumpWidget(_host(
        TodayWorkoutCard(
            workout: _workout('hard', exercises: 5, done: 2), onTap: () {}),
        dark: dark,
      ));
      final ring = tester.widget<ProgressRing>(find.byType(ProgressRing));
      expect((ring.done, ring.total), (2, 5));
      expect(find.text('2/5'), findsOneWidget);
      expect(find.text('Teljesítve'), findsNothing);
      expect(leftBar(tester), isNot(c.accentSuccess));
    });

    testWidgets('a completed workout turns green ($theme)', (tester) async {
      await tester.pumpWidget(_host(
        TodayWorkoutCard(
            workout: _workout('hard', status: 'Completed', exercises: 3),
            onTap: () {}),
        dark: dark,
      ));
      expect(find.text('Teljesítve'), findsOneWidget);
      final ring = tester.widget<ProgressRing>(find.byType(ProgressRing));
      expect(ring.isComplete, isTrue);
      final indicator = tester.widget<CircularProgressIndicator>(find
          .descendant(
              of: find.byType(ProgressRing),
              matching: find.byType(CircularProgressIndicator)));
      expect(indicator.color, c.accentSuccess);
      expect(leftBar(tester), c.accentSuccess);
    });

    testWidgets('no ring when the workout has no exercises ($theme)',
        (tester) async {
      await tester.pumpWidget(_host(
          TodayWorkoutCard(workout: _workout('easy'), onTap: () {}),
          dark: dark));
      expect(find.byType(ProgressRing), findsNothing);
    });

    testWidgets('RestDayCard sits on the card surface ($theme)',
        (tester) async {
      await tester.pumpWidget(_host(const RestDayCard(), dark: dark));
      final material = tester.widget<Material>(find
          .ancestor(of: find.text('Pihenőnap'), matching: find.byType(Material))
          .first);
      expect(material.color, c.cardSurface);
      expect(find.text('Erre a napra nincs ütemezett edzés.'), findsOneWidget);
    });

    testWidgets('HomeEntryCard tints with its color and taps ($theme)',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(
        HomeEntryCard(
          icon: Icons.timeline,
          color: c.accentTeal,
          title: 'Fejlődés előrejelzés',
          subtitle: 'Becsült 1RM trendje gyakorlatonként',
          onTap: () => taps++,
        ),
        dark: dark,
      ));
      expect(tester.widget<Icon>(find.byIcon(Icons.timeline)).color,
          c.accentTeal);
      final material = tester.widget<Material>(find
          .ancestor(
              of: find.text('Fejlődés előrejelzés'),
              matching: find.byType(Material))
          .first);
      expect(material.color, c.accentTeal.withValues(alpha: 0.10));

      await tester.tap(find.text('Fejlődés előrejelzés'));
      expect(taps, 1);
    });
  }

  group('WeeklyStrip', () {
    // A fixed Thursday so today is mid-week.
    final today = DateTime(2026, 11, 19, 10);
    final monday = WeeklyStrip.weekStart(today);
    DateTime day(int i) => DateTime(monday.year, monday.month, monday.day + i);

    Finder pillOf(DateTime d) => find
        .ancestor(
            of: find.text('${d.day}'), matching: find.byType(AnimatedContainer))
        .first;

    BoxDecoration pill(WidgetTester tester, DateTime d) =>
        tester.widget<AnimatedContainer>(pillOf(d)).decoration!
            as BoxDecoration;

    BoxDecoration dot(WidgetTester tester, DateTime d) =>
        tester.widget<AnimatedContainer>(find
            .descendant(
                of: pillOf(d), matching: find.byType(AnimatedContainer))
            .last).decoration! as BoxDecoration;

    Widget strip({ValueChanged<DateTime>? onPick}) => _host(WeeklyStrip(
          selected: day(0),
          now: () => today,
          workoutDays: {
            WeeklyStrip.dayKey(day(1)): false, // planned
            WeeklyStrip.dayKey(day(2)): true, // completed
          },
          onDateSelected: onPick ?? (_) {},
        ));

    testWidgets('selected day is filled, today outlined', (tester) async {
      await tester.pumpWidget(strip());
      const c = DTColors.light;
      expect(pill(tester, day(0)).color, c.accentPrimary);
      expect(pill(tester, day(1)).color, c.cardSurface);
      expect((pill(tester, today).border! as Border).top.color,
          c.accentPrimary);
      expect((pill(tester, day(1)).border! as Border).top.color,
          Colors.transparent);
    });

    testWidgets('planned workout is a ring, completed a filled dot',
        (tester) async {
      await tester.pumpWidget(strip());
      const c = DTColors.light;
      final planned = dot(tester, day(1));
      expect(planned.color, Colors.transparent);
      expect((planned.border! as Border).top.color, c.accentPrimary);
      expect(dot(tester, day(2)).color, c.accentSuccess);
      // A day without a workout keeps an invisible dot.
      expect((dot(tester, day(5)).border! as Border).top.color.a, 0);
    });

    testWidgets('reports taps and reads as a selectable day', (tester) async {
      final handle = tester.ensureSemantics();
      DateTime? picked;
      await tester.pumpWidget(strip(onPick: (d) => picked = d));
      await tester.tap(find.text('${day(1).day}'));
      expect(picked, day(1));
      expect(find.bySemanticsLabel('11.18, teljesített edzés'), findsOneWidget);
      expect(find.bySemanticsLabel('11.19, ma, nincs edzés'), findsOneWidget);
      handle.dispose();
    });
  });
}
