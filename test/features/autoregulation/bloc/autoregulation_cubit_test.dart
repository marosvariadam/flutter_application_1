import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_application_1/features/autoregulation/bloc/autoregulation_cubit.dart';
import 'package:flutter_application_1/features/autoregulation/data/models/autoregulation_model.dart';
import 'package:flutter_application_1/features/autoregulation/data/repositories/autoregulation_repository.dart';

class _MockRepo extends Mock implements AutoregulationRepository {}

NextWeekAutoregulationModel _result({
  String? planId = 'p1',
  bool deload = false,
  String name = 'Bench Press',
}) =>
    NextWeekAutoregulationModel(
      planId: planId,
      deloadApplied: deload,
      suggestions: planId == null
          ? const []
          : [
              AutoregulationSuggestionModel(
                exerciseId: 'e1',
                name: name,
                muscleGroup: 'Chest',
                scheme: 'DoubleProgression',
                currentReps: '6-10',
                targetRpe: 8,
                suggestedWeightKg: 82.5,
                suggestedSets: 3,
                outcome: AutoregulationOutcomes.increase,
                reason: '',
              ),
            ],
    );

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  group('AutoregulationCubit.load', () {
    blocTest<AutoregulationCubit, AutoregulationState>(
      'emits Loading then Loaded with the suggestions',
      build: () {
        when(() => repo.nextWeek('a1')).thenAnswer((_) async => _result());
        return AutoregulationCubit(repo);
      },
      act: (c) => c.load('a1'),
      expect: () => [
        isA<AutoregulationLoading>()
            .having((s) => s.athleteId, 'athleteId', 'a1'),
        isA<AutoregulationLoaded>()
            .having((s) => s.athleteId, 'athleteId', 'a1')
            .having((s) => s.result.suggestions.length, 'suggestions', 1)
            .having((s) => s.result.deloadApplied, 'deload', false),
      ],
    );

    blocTest<AutoregulationCubit, AutoregulationState>(
      'athlete without an accepted plan is Loaded with no suggestions',
      build: () {
        when(() => repo.nextWeek('a1'))
            .thenAnswer((_) async => _result(planId: null));
        return AutoregulationCubit(repo);
      },
      act: (c) => c.load('a1'),
      expect: () => [
        isA<AutoregulationLoading>(),
        isA<AutoregulationLoaded>()
            .having((s) => s.result.hasPlan, 'hasPlan', false)
            .having((s) => s.result.suggestions, 'suggestions', isEmpty),
      ],
    );

    blocTest<AutoregulationCubit, AutoregulationState>(
      'carries the deload flag through',
      build: () {
        when(() => repo.nextWeek('a1'))
            .thenAnswer((_) async => _result(deload: true));
        return AutoregulationCubit(repo);
      },
      act: (c) => c.load('a1'),
      expect: () => [
        isA<AutoregulationLoading>(),
        isA<AutoregulationLoaded>()
            .having((s) => s.result.deloadApplied, 'deload', true),
      ],
    );

    blocTest<AutoregulationCubit, AutoregulationState>(
      'emits Forbidden on 403',
      build: () {
        when(() => repo.nextWeek('a1'))
            .thenThrow(const AutoregulationForbiddenException());
        return AutoregulationCubit(repo);
      },
      act: (c) => c.load('a1'),
      expect: () => [
        isA<AutoregulationLoading>(),
        isA<AutoregulationForbidden>()
            .having((s) => s.athleteId, 'athleteId', 'a1'),
      ],
    );

    blocTest<AutoregulationCubit, AutoregulationState>(
      'emits a not-found Error on 404',
      build: () {
        when(() => repo.nextWeek('a1'))
            .thenThrow(const AutoregulationNotFoundException());
        return AutoregulationCubit(repo);
      },
      act: (c) => c.load('a1'),
      expect: () => [
        isA<AutoregulationLoading>(),
        isA<AutoregulationError>()
            .having((s) => s.message, 'message', 'A sportoló nem található.'),
      ],
    );

    blocTest<AutoregulationCubit, AutoregulationState>(
      'emits a generic Error on anything else',
      build: () {
        when(() => repo.nextWeek('a1')).thenThrow(Exception('boom'));
        return AutoregulationCubit(repo);
      },
      act: (c) => c.load('a1'),
      expect: () => [
        isA<AutoregulationLoading>(),
        isA<AutoregulationError>().having((s) => s.message, 'message',
            'Az autoregulációs javaslatok nem tölthetők be.'),
      ],
    );

    blocTest<AutoregulationCubit, AutoregulationState>(
      'ignores a slow response for a previously selected athlete',
      build: () => AutoregulationCubit(repo),
      act: (c) async {
        final first = Completer<NextWeekAutoregulationModel>();
        final second = Completer<NextWeekAutoregulationModel>();
        when(() => repo.nextWeek('a1')).thenAnswer((_) => first.future);
        when(() => repo.nextWeek('a2')).thenAnswer((_) => second.future);

        final loadA1 = c.load('a1');
        final loadA2 = c.load('a2');
        second.complete(_result(name: 'Squat'));
        await loadA2;
        first.complete(_result(name: 'Bench Press'));
        await loadA1;
      },
      expect: () => [
        isA<AutoregulationLoading>()
            .having((s) => s.athleteId, 'athleteId', 'a1'),
        isA<AutoregulationLoading>()
            .having((s) => s.athleteId, 'athleteId', 'a2'),
        isA<AutoregulationLoaded>()
            .having((s) => s.athleteId, 'athleteId', 'a2')
            .having((s) => s.result.suggestions.single.name, 'name', 'Squat'),
      ],
    );
  });

  blocTest<AutoregulationCubit, AutoregulationState>(
    'reset returns to Initial and drops the in-flight response',
    build: () => AutoregulationCubit(repo),
    act: (c) async {
      final pending = Completer<NextWeekAutoregulationModel>();
      when(() => repo.nextWeek('a1')).thenAnswer((_) => pending.future);
      final load = c.load('a1');
      c.reset();
      pending.complete(_result());
      await load;
    },
    expect: () => [
      isA<AutoregulationLoading>(),
      isA<AutoregulationInitial>(),
    ],
  );
}
