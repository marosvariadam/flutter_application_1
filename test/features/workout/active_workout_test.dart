import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_application_1/app/design/dt_colors.dart';
import 'package:flutter_application_1/app/design/theme.dart';
import 'package:flutter_application_1/features/workout/bloc/workout_bloc.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';
import 'package:flutter_application_1/features/workout/presentation/widgets/active_workout.dart';
import 'package:flutter_application_1/features/workout/presentation/widgets/set_row.dart';
import 'package:flutter_application_1/features/workout/presentation/widgets/workout_colors.dart';

class _MockWorkoutBloc extends MockBloc<WorkoutEvent, WorkoutState>
    implements WorkoutBloc {}

class _FakeEvent extends Fake implements WorkoutEvent {}

WorkoutModel _workout({int exercises = 2, int sets = 3}) =>
    WorkoutModel.fromJson({
      'id': 'w1',
      'title': 'Láb nap',
      'scheduledDate': '2026-11-19T09:00:00',
      'difficulty': 'hard',
      'status': 'InProgress',
      'exercises': [
        for (var i = 0; i < exercises; i++)
          {
            'exerciseId': 'e$i',
            'name': 'Gyakorlat $i',
            'index': i,
            'sets': sets,
            'targetReps': 8,
            'targetWeightKg': 82.5,
          },
      ],
    });

void main() {
  group('SetSteps', () {
    test('weight moves by 2.5 kg from the planned value, never below 0', () {
      expect(SetSteps.stepWeight(null, 82.5, 1), 85);
      expect(SetSteps.stepWeight(null, 82.5, -1), 80);
      expect(SetSteps.stepWeight(60, 82.5, 1), 62.5);
      expect(SetSteps.stepWeight(1, 82.5, -1), 0);
    });

    test('reps move by one, never below 0', () {
      expect(SetSteps.stepReps(null, 8, 1), 9);
      expect(SetSteps.stepReps(5, 8, -1), 4);
      expect(SetSteps.stepReps(0, 8, -1), 0);
    });

    test('formatWeight drops trailing zeros', () {
      expect(SetSteps.formatWeight(60), '60');
      expect(SetSteps.formatWeight(62.5), '62.5');
      expect(SetSteps.formatWeight(61.25), '61.25');
    });

    test('SetEntry accepts a decimal comma', () {
      final e = SetEntry()..weightCtrl.text = '62,5';
      expect(e.weight, 62.5);
      e.dispose();
    });
  });

  test('WorkoutModel.completedExercises counts fully logged exercises', () {
    final w = WorkoutModel.fromJson({
      'id': 'w',
      'title': 't',
      'scheduledDate': '2026-11-19T09:00:00',
      'exercises': [
        {'name': 'a', 'sets': 3, 'actualSets': 3},
        {'name': 'b', 'sets': 3, 'actualSets': 2},
        {'name': 'c', 'sets': 3},
        {'name': 'd', 'sets': 0, 'actualSets': 0},
      ],
    });
    expect(w.completedExercises, 1);
  });

  group('workout colors', () {
    for (final c in [DTColors.light, DTColors.dark]) {
      test('difficulty and status map to theme tokens', () {
        expect(WorkoutDifficulty.easy.color(c), c.difficultyEasy);
        expect(WorkoutDifficulty.moderate.color(c), c.difficultyMedium);
        expect(WorkoutDifficulty.hard.color(c), c.difficultyHard);
        expect(WorkoutDifficulty.intense.color(c), c.difficultyIntense);
        expect(WorkoutStatus.planned.color(c), c.accentPrimary);
        expect(WorkoutStatus.inProgress.color(c), c.accentOrange);
        expect(WorkoutStatus.completed.color(c), c.accentSuccess);
      });
    }
  });

  group('active workout', () {
    late _MockWorkoutBloc bloc;
    late List<MethodCall> platform;

    setUpAll(() => registerFallbackValue(_FakeEvent()));

    setUp(() {
      bloc = _MockWorkoutBloc();
      whenListen(bloc, const Stream<WorkoutState>.empty(),
          initialState: WorkoutInitial());
      platform = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        platform.add(call);
        return null;
      });
    });

    tearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    Future<void> pump(WidgetTester tester, WorkoutModel w,
        {bool dark = false, double height = 2400}) async {
      tester.view.physicalSize = Size(390, height) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(BlocProvider<WorkoutBloc>.value(
        value: bloc,
        child: MaterialApp(
          theme: buildTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          home: Scaffold(body: ActiveWorkoutBody(workout: w)),
        ),
      ));
    }

    Finder field(int row, String what) => find
        .descendant(
            of: find.byType(SetRow).at(row),
            matching: find.bySemanticsLabel(RegExp('^$what')))
        .first;

    TextField textField(WidgetTester tester, int row, int which) =>
        tester.widget<TextField>(find
            .descendant(
                of: find.byType(SetRow).at(row),
                matching: find.byType(TextField))
            .at(which));

    testWidgets('steppers are labelled 44 px buttons that step from the plan',
        (tester) async {
      await pump(tester, _workout(exercises: 1));
      final plus = find.byTooltip('Súly növelése (2,5 kg)').first;
      expect(tester.getSize(plus).height, greaterThanOrEqualTo(44));
      expect(find.byTooltip('Ismétlés csökkentése (1)'), findsWidgets);

      await tester.tap(plus);
      await tester.pump();
      expect(textField(tester, 0, 0).controller!.text, '85');

      await tester.tap(find.byTooltip('Ismétlés növelése (1)').first);
      await tester.pump();
      expect(textField(tester, 0, 1).controller!.text, '9');
      expect(platform.map((c) => c.arguments),
          contains('HapticFeedbackType.selectionClick'));
      expect(field(0, 'Súly'), findsOneWidget);
    });

    testWidgets('fields use a numeric keyboard', (tester) async {
      await pump(tester, _workout(exercises: 1));
      expect(textField(tester, 0, 0).keyboardType,
          const TextInputType.numberWithOptions(decimal: true));
      expect(textField(tester, 0, 1).keyboardType,
          const TextInputType.numberWithOptions(decimal: false));
      expect(textField(tester, 0, 1).textInputAction, TextInputAction.done);
    });

    testWidgets(
        'checking a set logs it, ticks the phone and pre-fills the next set',
        (tester) async {
      await pump(tester, _workout(exercises: 1));
      await tester.enterText(find.byType(TextField).at(0), '90');
      await tester.enterText(find.byType(TextField).at(1), '6');

      await tester.tap(find.byTooltip('Sorozat kész').first);
      await tester.pump();

      final logged = verify(() => bloc.add(captureAny())).captured.single
          as LogExercise;
      expect(logged.actualSets, 1);
      expect(logged.actualWeightKg, 90);
      expect(logged.actualReps, 6);
      expect(platform.map((c) => c.arguments),
          contains('HapticFeedbackType.mediumImpact'));

      // Done row collapses; the next set carries the values over.
      expect(find.text('90 kg × 6'), findsOneWidget);
      expect(textField(tester, 1, 0).controller!.text, '90');
      expect(textField(tester, 1, 1).controller!.text, '6');
    });

    testWidgets('"Kész" on the reps keyboard checks the set off',
        (tester) async {
      await pump(tester, _workout(exercises: 1));
      await tester.showKeyboard(find.byType(TextField).at(1));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      final logged = verify(() => bloc.add(captureAny())).captured.single
          as LogExercise;
      expect(logged.actualSets, 1);
      expect(logged.actualReps, 8); // planned value
    });

    testWidgets('the next set to do is outlined (dark)', (tester) async {
      await pump(tester, _workout(exercises: 1), dark: true);
      BoxDecoration deco(int row) => tester
          .widget<AnimatedContainer>(find
              .descendant(
                  of: find.byType(SetRow).at(row),
                  matching: find.byType(AnimatedContainer))
              .first)
          .decoration! as BoxDecoration;
      expect((deco(0).border! as Border).top.color, DTColors.dark.accentPrimary);
      expect((deco(1).border! as Border).top.color, Colors.transparent);

      await tester.tap(find.byTooltip('Sorozat kész').first);
      await tester.pump();
      expect((deco(1).border! as Border).top.color, DTColors.dark.accentPrimary);
    });

    testWidgets('finishing an exercise scrolls to the next one',
        (tester) async {
      await pump(tester, _workout(exercises: 4, sets: 2), height: 700);
      final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
      expect(scroll.position.pixels, 0);
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byTooltip('Sorozat kész').first);
        await tester.pumpAndSettle();
      }
      expect(scroll.position.pixels, greaterThan(0));
    });
  });
}
