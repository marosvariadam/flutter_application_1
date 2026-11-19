import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_application_1/features/training_plan/bloc/plan_explanation_cubit.dart';
import 'package:flutter_application_1/features/training_plan/data/models/plan_results.dart';
import 'package:flutter_application_1/features/training_plan/data/repositories/training_plan_repository.dart';

class _MockRepo extends Mock implements TrainingPlanRepository {}

const _explanation = PlanExplanationModel(
  planId: 'p1',
  language: 'hu',
  explanation: 'A terv **hetente négyszer** edz felső és alsó testet.',
);

void main() {
  late _MockRepo repo;

  setUp(() => repo = _MockRepo());

  void stub(Future<PlanExplanationModel> Function() answer) {
    when(() => repo.explanation(
          planId: any(named: 'planId'),
          language: any(named: 'language'),
        )).thenAnswer((_) => answer());
  }

  test('starts idle without calling the backend', () {
    final cubit = PlanExplanationCubit(repo);
    expect(cubit.state, isA<PlanExplanationIdle>());
    verifyNever(() => repo.explanation(
        planId: any(named: 'planId'), language: any(named: 'language')));
    cubit.close();
  });

  blocTest<PlanExplanationCubit, PlanExplanationState>(
    'requests a Hungarian explanation and emits it',
    setUp: () => stub(() async => _explanation),
    build: () => PlanExplanationCubit(repo),
    act: (c) => c.load('p1'),
    expect: () => [
      isA<PlanExplanationLoading>(),
      isA<PlanExplanationLoaded>().having(
          (s) => s.explanation.explanation, 'text', _explanation.explanation),
    ],
    verify: (_) =>
        verify(() => repo.explanation(planId: 'p1', language: 'hu')).called(1),
  );

  blocTest<PlanExplanationCubit, PlanExplanationState>(
    'emits RateLimited on 429',
    setUp: () => stub(() => Future.error(const PlanRateLimitedException())),
    build: () => PlanExplanationCubit(repo),
    act: (c) => c.load('p1'),
    expect: () =>
        [isA<PlanExplanationLoading>(), isA<PlanExplanationRateLimited>()],
  );

  blocTest<PlanExplanationCubit, PlanExplanationState>(
    'emits Unavailable when the LLM is down',
    setUp: () =>
        stub(() => Future.error(const PlanLlmUnavailableException('down'))),
    build: () => PlanExplanationCubit(repo),
    act: (c) => c.load('p1'),
    expect: () =>
        [isA<PlanExplanationLoading>(), isA<PlanExplanationUnavailable>()],
  );

  blocTest<PlanExplanationCubit, PlanExplanationState>(
    'emits Forbidden on 403',
    setUp: () => stub(() => Future.error(const PlanForbiddenException())),
    build: () => PlanExplanationCubit(repo),
    act: (c) => c.load('p1'),
    expect: () =>
        [isA<PlanExplanationLoading>(), isA<PlanExplanationForbidden>()],
  );

  blocTest<PlanExplanationCubit, PlanExplanationState>(
    'emits a not-found Error on 404',
    setUp: () => stub(() => Future.error(const PlanNotFoundException())),
    build: () => PlanExplanationCubit(repo),
    act: (c) => c.load('p1'),
    expect: () => [
      isA<PlanExplanationLoading>(),
      isA<PlanExplanationError>()
          .having((s) => s.message, 'message', 'A terv nem található.'),
    ],
  );

  blocTest<PlanExplanationCubit, PlanExplanationState>(
    'emits a generic Error on anything else',
    setUp: () => stub(() => Future.error(Exception('boom'))),
    build: () => PlanExplanationCubit(repo),
    act: (c) => c.load('p1'),
    expect: () => [isA<PlanExplanationLoading>(), isA<PlanExplanationError>()],
  );

  blocTest<PlanExplanationCubit, PlanExplanationState>(
    'ignores a second tap while the first request is running',
    build: () => PlanExplanationCubit(repo),
    act: (c) async {
      final pending = Completer<PlanExplanationModel>();
      stub(() => pending.future);
      final first = c.load('p1');
      await c.load('p1');
      pending.complete(_explanation);
      await first;
    },
    expect: () =>
        [isA<PlanExplanationLoading>(), isA<PlanExplanationLoaded>()],
    verify: (_) => verify(() => repo.explanation(
        planId: any(named: 'planId'),
        language: any(named: 'language'))).called(1),
  );
}
