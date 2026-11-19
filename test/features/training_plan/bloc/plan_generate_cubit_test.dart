import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_application_1/features/training_plan/bloc/plan_generate_cubit.dart';
import 'package:flutter_application_1/features/training_plan/data/models/plan_results.dart';
import 'package:flutter_application_1/features/training_plan/data/models/training_plan_model.dart';
import 'package:flutter_application_1/features/training_plan/data/repositories/training_plan_repository.dart';

class _MockRepo extends Mock implements TrainingPlanRepository {}

TrainingPlanModel _plan() => TrainingPlanModel.fromJson({
      'id': 'p1',
      'trainerId': 't1',
      'athleteId': 'a1',
      'title': 'Hypertrophy — 4 week',
      'goal': 'Hypertrophy',
      'weeks': 4,
      'split': 'UpperLower',
      'status': 'Draft',
      'progression': 'DoubleProgression',
      'source': 'Hybrid',
      'createdAt': '2026-10-01T12:00:00Z',
      'days': [],
    });

GenerateResultModel _result() => GenerateResultModel(
      plan: _plan(),
      predictedScore: 0.78,
      usedPredictor: true,
      warnings: const [],
      errors: const [],
      candidates: const [],
    );

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  group('PlanGenerateCubit.generate', () {
    blocTest<PlanGenerateCubit, PlanGenerateState>(
      'emits Running then Success on happy path',
      build: () {
        when(() => repo.generate(
              athleteId: any(named: 'athleteId'),
              mode: any(named: 'mode'),
              weeks: any(named: 'weeks'),
              trainingBlockId: any(named: 'trainingBlockId'),
            )).thenAnswer((_) async => _result());
        return PlanGenerateCubit(repo);
      },
      act: (c) => c.generate(
        athleteId: 'a1',
        mode: 'Hybrid',
        weeks: 4,
      ),
      expect: () => [
        isA<PlanGenerateRunning>(),
        isA<PlanGenerateSuccess>().having(
            (s) => s.result.plan.title, 'title', 'Hypertrophy — 4 week'),
      ],
    );

    blocTest<PlanGenerateCubit, PlanGenerateState>(
      'emits ValidationError when backend returns 400',
      build: () {
        when(() => repo.generate(
              athleteId: any(named: 'athleteId'),
              mode: any(named: 'mode'),
              weeks: any(named: 'weeks'),
              trainingBlockId: any(named: 'trainingBlockId'),
            )).thenThrow(
            const PlanValidationException('Athlete has no AthleteProfile'));
        return PlanGenerateCubit(repo);
      },
      act: (c) => c.generate(athleteId: 'a1', mode: 'Hybrid', weeks: 4),
      expect: () => [
        isA<PlanGenerateRunning>(),
        isA<PlanGenerateValidationError>().having(
            (s) => s.message, 'message', 'Athlete has no AthleteProfile'),
      ],
    );

    blocTest<PlanGenerateCubit, PlanGenerateState>(
      'emits RateLimited on 429',
      build: () {
        when(() => repo.generate(
              athleteId: any(named: 'athleteId'),
              mode: any(named: 'mode'),
              weeks: any(named: 'weeks'),
              trainingBlockId: any(named: 'trainingBlockId'),
            )).thenThrow(const PlanRateLimitedException());
        return PlanGenerateCubit(repo);
      },
      act: (c) => c.generate(athleteId: 'a1', mode: 'Hybrid', weeks: 4),
      expect: () => [
        isA<PlanGenerateRunning>(),
        isA<PlanGenerateRateLimited>(),
      ],
    );

    blocTest<PlanGenerateCubit, PlanGenerateState>(
      'emits LlmUnavailable on 503',
      build: () {
        when(() => repo.generate(
              athleteId: any(named: 'athleteId'),
              mode: any(named: 'mode'),
              weeks: any(named: 'weeks'),
              trainingBlockId: any(named: 'trainingBlockId'),
            )).thenThrow(const PlanLlmUnavailableException('down'));
        return PlanGenerateCubit(repo);
      },
      act: (c) => c.generate(athleteId: 'a1', mode: 'Hybrid', weeks: 4),
      expect: () => [
        isA<PlanGenerateRunning>(),
        isA<PlanGenerateLlmUnavailable>()
            .having((s) => s.message, 'message', 'down'),
      ],
    );

    blocTest<PlanGenerateCubit, PlanGenerateState>(
      'emits Forbidden on 403',
      build: () {
        when(() => repo.generate(
              athleteId: any(named: 'athleteId'),
              mode: any(named: 'mode'),
              weeks: any(named: 'weeks'),
              trainingBlockId: any(named: 'trainingBlockId'),
            )).thenThrow(const PlanForbiddenException());
        return PlanGenerateCubit(repo);
      },
      act: (c) => c.generate(athleteId: 'a1', mode: 'Hybrid', weeks: 4),
      expect: () => [
        isA<PlanGenerateRunning>(),
        isA<PlanGenerateForbidden>(),
      ],
    );

    blocTest<PlanGenerateCubit, PlanGenerateState>(
      'emits generic Error on anything else',
      build: () {
        when(() => repo.generate(
              athleteId: any(named: 'athleteId'),
              mode: any(named: 'mode'),
              weeks: any(named: 'weeks'),
              trainingBlockId: any(named: 'trainingBlockId'),
            )).thenThrow(Exception('boom'));
        return PlanGenerateCubit(repo);
      },
      act: (c) => c.generate(athleteId: 'a1', mode: 'Hybrid', weeks: 4),
      expect: () => [
        isA<PlanGenerateRunning>(),
        isA<PlanGenerateError>(),
      ],
    );
  });

  blocTest<PlanGenerateCubit, PlanGenerateState>(
    'reset returns to Initial',
    build: () => PlanGenerateCubit(repo),
    seed: () => PlanGenerateSuccess(_result()),
    act: (c) => c.reset(),
    expect: () => [isA<PlanGenerateInitial>()],
  );
}
