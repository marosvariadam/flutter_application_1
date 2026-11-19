import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/design/dt_colors.dart';
import 'package:flutter_application_1/app/design/theme.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/home_entry_card.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/today_workout_card.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/weekly_strip.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';

Widget _host(Widget child, {bool dark = false}) => MaterialApp(
      theme: buildTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

WorkoutModel _workout(String difficulty) => WorkoutModel.fromJson({
      'id': 'w1',
      'title': 'Láb nap',
      'scheduledDate': '2026-11-19T09:00:00',
      'difficulty': difficulty,
      'exercises': <Map<String, dynamic>>[],
    });

Color _badgeColor(WidgetTester tester, String label) {
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
        testWidgets('$json badge uses the theme difficulty color',
            (tester) async {
          await tester.pumpWidget(_host(
            TodayWorkoutCard(workout: _workout(json), onTap: () {}),
            dark: dark,
          ));
          expect(_badgeColor(tester, expected.$1), expected.$2);
          expect(tester.widget<Text>(find.text(expected.$1)).style?.color,
              c.textOnAccent);
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

  testWidgets('WeeklyStrip marks workout days and reports taps',
      (tester) async {
    final monday = WeeklyStrip.weekStart(DateTime.now());
    final tuesday = DateTime(monday.year, monday.month, monday.day + 1);
    DateTime? picked;
    await tester.pumpWidget(_host(WeeklyStrip(
      selected: monday,
      workoutDateKeys: {WeeklyStrip.dayKey(tuesday)},
      onDateSelected: (d) => picked = d,
    )));

    expect(_badgeColor(tester, '${monday.day}'), DTColors.light.accentPrimary);
    expect(_badgeColor(tester, '${tuesday.day}'), DTColors.light.cardSurface);

    await tester.tap(find.text('${tuesday.day}'));
    expect(picked, tuesday);
  });
}
