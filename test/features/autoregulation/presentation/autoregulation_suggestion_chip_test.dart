import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_application_1/features/autoregulation/bloc/autoregulation_cubit.dart';
import 'package:flutter_application_1/features/autoregulation/data/models/autoregulation_model.dart';
import 'package:flutter_application_1/features/autoregulation/presentation/widgets/autoregulation_banner.dart';
import 'package:flutter_application_1/features/autoregulation/presentation/widgets/autoregulation_suggestion_chip.dart';

class _MockCubit extends MockCubit<AutoregulationState>
    implements AutoregulationCubit {}

AutoregulationLoaded _loaded({bool deload = false}) => AutoregulationLoaded(
      'a1',
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
            targetRpe: 7,
            suggestedWeightKg: 82.5,
            suggestedSets: 3,
            outcome: AutoregulationOutcomes.increase,
            reason: '',
            lastLogged: LastLoggedSessionModel(
              date: DateTime.utc(2026, 11, 12),
              sets: 3,
              reps: 10,
              weightKg: 80,
              rpe: 7,
            ),
          ),
        ],
      ),
    );

Widget _host(AutoregulationCubit cubit, Widget child) => MaterialApp(
      home: Scaffold(
        body: BlocProvider<AutoregulationCubit>.value(
          value: cubit,
          child: Center(child: child),
        ),
      ),
    );

void main() {
  late _MockCubit cubit;

  setUp(() {
    cubit = _MockCubit();
  });

  testWidgets('shows the suggestion and applies it on tap', (tester) async {
    when(() => cubit.state).thenReturn(_loaded());
    AutoregulationSuggestionModel? applied;

    await tester.pumpWidget(_host(
      cubit,
      AutoregulationSuggestionChip(
        exerciseId: 'e1',
        exerciseName: 'Bench Press',
        isApplied: (_) => false,
        onApply: (s) => applied = s,
      ),
    ));

    expect(find.text('+2.5 kg — minden szett RPE 7'), findsOneWidget);
    await tester.tap(find.text('+2.5 kg — minden szett RPE 7'));
    expect(applied?.suggestedWeightKg, 82.5);
  });

  testWidgets('applied suggestion shows a check and ignores taps',
      (tester) async {
    when(() => cubit.state).thenReturn(_loaded());
    var taps = 0;

    await tester.pumpWidget(_host(
      cubit,
      AutoregulationSuggestionChip(
        exerciseId: 'e1',
        exerciseName: 'Bench Press',
        isApplied: (_) => true,
        onApply: (_) => taps++,
      ),
    ));

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    await tester.tap(find.text('+2.5 kg — minden szett RPE 7'));
    expect(taps, 0);
  });

  testWidgets('renders nothing for an exercise outside the plan',
      (tester) async {
    when(() => cubit.state).thenReturn(_loaded());

    await tester.pumpWidget(_host(
      cubit,
      AutoregulationSuggestionChip(
        exerciseId: 'other',
        exerciseName: 'Deadlift',
        isApplied: (_) => false,
        onApply: (_) {},
      ),
    ));

    expect(find.textContaining('minden szett'), findsNothing);
  });

  testWidgets('banner shows the deload suggestion when the rule fired',
      (tester) async {
    when(() => cubit.state).thenReturn(_loaded(deload: true));
    await tester.pumpWidget(_host(cubit, const AutoregulationBanner()));
    expect(find.text('Deload hét javasolt'), findsOneWidget);
  });

  testWidgets('banner stays hidden without a deload', (tester) async {
    when(() => cubit.state).thenReturn(_loaded());
    await tester.pumpWidget(_host(cubit, const AutoregulationBanner()));
    expect(find.text('Deload hét javasolt'), findsNothing);
  });

  testWidgets('banner offers a retry after a load error', (tester) async {
    when(() => cubit.state)
        .thenReturn(const AutoregulationError('a1', 'Hiba történt.'));
    when(() => cubit.load(any())).thenAnswer((_) async {});

    await tester.pumpWidget(_host(cubit, const AutoregulationBanner()));
    expect(find.text('Hiba történt.'), findsOneWidget);

    await tester.tap(find.text('Újra'));
    verify(() => cubit.load('a1')).called(1);
  });
}
