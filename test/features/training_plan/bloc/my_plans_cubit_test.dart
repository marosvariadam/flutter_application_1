import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_application_1/features/training_plan/bloc/my_plans_cubit.dart';
import 'package:flutter_application_1/features/training_plan/data/models/training_plan_model.dart';
import 'package:flutter_application_1/features/training_plan/data/repositories/training_plan_repository.dart';

class _MockRepo extends Mock implements TrainingPlanRepository {}

TrainingPlanModel _plan(String id, DateTime createdAt,
        {String status = PlanStatuses.accepted}) =>
    TrainingPlanModel(
      id: id,
      trainerId: 't1',
      athleteId: 'a1',
      title: 'Plan $id',
      goal: 'Hypertrophy',
      weeks: 4,
      split: PlanSplits.upperLower,
      status: status,
      days: const [],
      progression: PlanProgressionSchemes.doubleProgression,
      source: PlanGenerationSources.hybrid,
      createdAt: createdAt,
    );

void main() {
  late _MockRepo repo;

  setUp(() => repo = _MockRepo());

  blocTest<MyPlansCubit, MyPlansState>(
    'emits Loaded with the newest plan first',
    setUp: () => when(() => repo.mine()).thenAnswer((_) async => [
          _plan('old', DateTime.utc(2026, 9, 1)),
          _plan('new', DateTime.utc(2026, 11, 1)),
        ]),
    build: () => MyPlansCubit(repo),
    act: (c) => c.load(),
    expect: () => [
      isA<MyPlansLoading>(),
      isA<MyPlansLoaded>()
          .having((s) => s.plans.map((p) => p.id).toList(), 'order',
              ['new', 'old'])
          .having((s) => s.current.id, 'current', 'new'),
    ],
  );

  blocTest<MyPlansCubit, MyPlansState>(
    'current skips archived plans',
    setUp: () => when(() => repo.mine()).thenAnswer((_) async => [
          _plan('archived', DateTime.utc(2026, 11, 1),
              status: PlanStatuses.archived),
          _plan('active', DateTime.utc(2026, 10, 1),
              status: PlanStatuses.materialized),
        ]),
    build: () => MyPlansCubit(repo),
    act: (c) => c.load(),
    expect: () => [
      isA<MyPlansLoading>(),
      isA<MyPlansLoaded>().having((s) => s.current.id, 'current', 'active'),
    ],
  );

  blocTest<MyPlansCubit, MyPlansState>(
    'emits Empty when the athlete has no accepted plan',
    setUp: () => when(() => repo.mine()).thenAnswer((_) async => []),
    build: () => MyPlansCubit(repo),
    act: (c) => c.load(),
    expect: () => [isA<MyPlansLoading>(), isA<MyPlansEmpty>()],
  );

  blocTest<MyPlansCubit, MyPlansState>(
    'emits Error when the request fails',
    setUp: () => when(() => repo.mine()).thenThrow(Exception('boom')),
    build: () => MyPlansCubit(repo),
    act: (c) => c.load(),
    expect: () => [isA<MyPlansLoading>(), isA<MyPlansError>()],
  );

  blocTest<MyPlansCubit, MyPlansState>(
    'refreshing a shown plan skips the Loading state',
    setUp: () => when(() => repo.mine())
        .thenAnswer((_) async => [_plan('p2', DateTime.utc(2026, 11, 2))]),
    build: () => MyPlansCubit(repo),
    seed: () => MyPlansLoaded([_plan('p1', DateTime.utc(2026, 11, 1))]),
    act: (c) => c.load(),
    expect: () => [
      isA<MyPlansLoaded>().having((s) => s.current.id, 'current', 'p2'),
    ],
  );
}
