import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_application_1/features/exercise/data/models/exercise_model.dart';
import 'package:flutter_application_1/features/training_plan/bloc/plan_editor_bloc.dart';
import 'package:flutter_application_1/features/training_plan/data/models/plan_results.dart';
import 'package:flutter_application_1/features/training_plan/data/models/training_plan_model.dart';
import 'package:flutter_application_1/features/training_plan/data/models/violation_model.dart';
import 'package:flutter_application_1/features/training_plan/data/repositories/training_plan_repository.dart';

class _MockRepo extends Mock implements TrainingPlanRepository {}

PlannedExerciseModel _ex(String id, int order, {int sets = 3}) =>
    PlannedExerciseModel(
      exerciseId: id,
      name: 'Ex $id',
      muscleGroup: 'Chest',
      sets: sets,
      repMin: 6,
      repMax: 10,
      targetRpe: 8,
      restSeconds: 120,
      order: order,
    );

TrainingPlanModel _plan({
  String status = PlanStatuses.draft,
  List<PlanDayModel>? days,
}) =>
    TrainingPlanModel(
      id: 'p1',
      trainerId: 't1',
      athleteId: 'a1',
      title: 'Terv',
      goal: 'Hypertrophy',
      weeks: 4,
      split: PlanSplits.upperLower,
      status: status,
      days: days ??
          [
            PlanDayModel(
                dayIndex: 0,
                label: 'A',
                exercises: [_ex('e1', 0), _ex('e2', 1), _ex('e3', 2)]),
            PlanDayModel(dayIndex: 1, label: 'B', exercises: [_ex('e4', 0)]),
          ],
      progression: PlanProgressionSchemes.doubleProgression,
      source: PlanGenerationSources.hybrid,
      createdAt: DateTime.utc(2026, 11, 1),
    );

List<String?> _ids(PlanEditorState s, int day) => (s as PlanEditorReady)
    .plan
    .days[day]
    .exercises
    .map((e) => e.exerciseId)
    .toList();

List<int> _orders(PlanEditorState s, int day) =>
    (s as PlanEditorReady).plan.days[day].exercises.map((e) => e.order).toList();

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    registerFallbackValue(<PlanDayModel>[]);
  });

  void stubUpdate(Future<RefineResultModel> Function(Invocation) answer) {
    when(() => repo.update(
          planId: any(named: 'planId'),
          title: any(named: 'title'),
          weeks: any(named: 'weeks'),
          split: any(named: 'split'),
          days: any(named: 'days'),
        )).thenAnswer(answer);
  }

  // A very long debounce keeps the auto-commit out of these local-edit
  // tests; commit behavior is covered separately below.
  PlanEditorBloc noCommit() =>
      PlanEditorBloc(repo, debounce: const Duration(hours: 1));

  group('local edits', () {
    blocTest<PlanEditorBloc, PlanEditorState>(
      'reorder moves the row and re-stamps order 0..n-1',
      build: noCommit,
      seed: () => PlanEditorReady(plan: _plan()),
      act: (b) => b.add(const PlanEditorReorderExercise(
          dayIndex: 0, fromIndex: 0, toIndex: 3)),
      expect: () => [
        predicate<PlanEditorState>((s) =>
            _ids(s, 0).join(',') == 'e2,e3,e1' &&
            _orders(s, 0).join(',') == '0,1,2'),
      ],
    );

    blocTest<PlanEditorBloc, PlanEditorState>(
      'reorder with an out-of-range index changes nothing',
      build: noCommit,
      seed: () => PlanEditorReady(plan: _plan()),
      act: (b) => b.add(const PlanEditorReorderExercise(
          dayIndex: 0, fromIndex: 5, toIndex: 0)),
      expect: () => [
        predicate<PlanEditorState>((s) => _ids(s, 0).join(',') == 'e1,e2,e3'),
      ],
    );

    blocTest<PlanEditorBloc, PlanEditorState>(
      'add appends a default 3 × 8–12 @ RPE 8 row at the end',
      build: noCommit,
      seed: () => PlanEditorReady(plan: _plan()),
      act: (b) => b.add(const PlanEditorAddExercise(
        dayIndex: 1,
        exercise: ExerciseModel(id: 'e9', name: 'Guggolás', muscleGroup: 'Legs'),
      )),
      expect: () => [
        predicate<PlanEditorState>((s) {
          final added = (s as PlanEditorReady).plan.days[1].exercises.last;
          return added.exerciseId == 'e9' &&
              added.muscleGroup == 'Legs' &&
              added.prescription == '3 × 8–12 @ RPE 8' &&
              added.restSeconds == 90 &&
              added.order == 1;
        }),
      ],
    );

    blocTest<PlanEditorBloc, PlanEditorState>(
      'remove drops the row and re-stamps order',
      build: noCommit,
      seed: () => PlanEditorReady(plan: _plan()),
      act: (b) => b.add(
          const PlanEditorRemoveExercise(dayIndex: 0, exerciseIndex: 1)),
      expect: () => [
        predicate<PlanEditorState>((s) =>
            _ids(s, 0).join(',') == 'e1,e3' &&
            _orders(s, 0).join(',') == '0,1'),
      ],
    );

    blocTest<PlanEditorBloc, PlanEditorState>(
      'edits only touch the targeted day',
      build: noCommit,
      seed: () => PlanEditorReady(plan: _plan()),
      act: (b) => b.add(PlanEditorEditExercise(
          dayIndex: 1, exerciseIndex: 0, updated: _ex('e4', 0, sets: 5))),
      expect: () => [
        predicate<PlanEditorState>((s) {
          final r = s as PlanEditorReady;
          return r.plan.days[1].exercises.single.sets == 5 &&
              r.plan.days[0].exercises.every((e) => e.sets == 3);
        }),
      ],
    );

    blocTest<PlanEditorBloc, PlanEditorState>(
      'edits before the plan is loaded are ignored',
      build: noCommit,
      act: (b) => b.add(const PlanEditorRemoveExercise(
          dayIndex: 0, exerciseIndex: 0)),
      expect: () => const <PlanEditorState>[],
    );

    blocTest<PlanEditorBloc, PlanEditorState>(
      'several quick edits are saved with a single PUT',
      setUp: () => stubUpdate((_) async =>
          RefineResultModel(plan: _plan(), warnings: const [], errors: const [])),
      build: () =>
          PlanEditorBloc(repo, debounce: const Duration(milliseconds: 30)),
      seed: () => PlanEditorReady(plan: _plan()),
      act: (b) {
        b.add(const PlanEditorRemoveExercise(dayIndex: 0, exerciseIndex: 2));
        b.add(const PlanEditorRemoveExercise(dayIndex: 0, exerciseIndex: 1));
      },
      wait: const Duration(milliseconds: 120),
      verify: (_) => verify(() => repo.update(
            planId: 'p1',
            title: any(named: 'title'),
            weeks: any(named: 'weeks'),
            split: any(named: 'split'),
            days: any(named: 'days'),
          )).called(1),
    );
  });

  group('refine undo and highlights', () {
    final snapshotDays = _plan().days;

    blocTest<PlanEditorBloc, PlanEditorState>(
      'undo PUTs the pre-refine days and clears the snapshot',
      setUp: () => stubUpdate((_) async => RefineResultModel(
          plan: _plan(days: snapshotDays),
          warnings: const [],
          errors: const [])),
      build: noCommit,
      seed: () => PlanEditorReady(
        plan: _plan(days: [snapshotDays.first]),
        highlightedDays: const {0},
        refineUndo: RefineSnapshot(
            days: snapshotDays, title: 'Terv', weeks: 4, split: 'UpperLower'),
      ),
      act: (b) => b.add(const PlanEditorUndoRefine()),
      expect: () => [
        isA<PlanEditorReady>().having((s) => s.isSaving, 'saving', true),
        isA<PlanEditorReady>()
            .having((s) => s.isSaving, 'saving', false)
            .having((s) => s.refineUndo, 'undo', isNull)
            .having((s) => s.highlightedDays, 'highlights', isEmpty)
            .having((s) => s.plan.days.length, 'days', 2),
      ],
      verify: (_) => verify(() => repo.update(
            planId: 'p1',
            title: 'Terv',
            weeks: 4,
            split: 'UpperLower',
            days: snapshotDays,
          )).called(1),
    );

    blocTest<PlanEditorBloc, PlanEditorState>(
      'undo without a snapshot does nothing',
      build: noCommit,
      seed: () => PlanEditorReady(plan: _plan()),
      act: (b) => b.add(const PlanEditorUndoRefine()),
      expect: () => const <PlanEditorState>[],
    );

    blocTest<PlanEditorBloc, PlanEditorState>(
      'clearing highlights empties the set once',
      build: noCommit,
      seed: () =>
          PlanEditorReady(plan: _plan(), highlightedDays: const {0, 1}),
      act: (b) => b
        ..add(const PlanEditorClearHighlights())
        ..add(const PlanEditorClearHighlights()),
      expect: () => [
        isA<PlanEditorReady>()
            .having((s) => s.highlightedDays, 'highlights', isEmpty),
      ],
    );
  });

  group('errors surface as Hungarian messages', () {
    blocTest<PlanEditorBloc, PlanEditorState>(
      'commit on a materialized plan explains why',
      setUp: () => stubUpdate((_) => Future.error(const PlanConflictException(
          'Plan is already materialized; create a new draft to change it.'))),
      build: noCommit,
      seed: () => PlanEditorReady(plan: _plan()),
      act: (b) => b.add(const PlanEditorCommit()),
      expect: () => [
        isA<PlanEditorReady>().having((s) => s.isSaving, 'saving', true),
        isA<PlanEditorReady>()
            .having((s) => s.isSaving, 'saving', false)
            .having((s) => s.lastErrorMessage, 'message',
                'A terv már be van ütemezve, ezért nem módosítható.'),
      ],
    );

    blocTest<PlanEditorBloc, PlanEditorState>(
      'a dropped connection during commit mentions the network',
      setUp: () => stubUpdate((_) => Future.error(DioException(
          requestOptions: RequestOptions(path: '/api/plan/p1'),
          type: DioExceptionType.connectionError))),
      build: noCommit,
      seed: () => PlanEditorReady(plan: _plan()),
      act: (b) => b.add(const PlanEditorCommit()),
      expect: () => [
        isA<PlanEditorReady>(),
        isA<PlanEditorReady>().having((s) => s.lastErrorMessage, 'message',
            'Nincs internetkapcsolat, vagy a szerver nem érhető el.'),
      ],
    );

    blocTest<PlanEditorBloc, PlanEditorState>(
      'refine: rate limit, unavailable AI and empty instruction',
      setUp: () {
        var call = 0;
        when(() => repo.refine(
              planId: any(named: 'planId'),
              instruction: any(named: 'instruction'),
            )).thenAnswer((_) {
          call++;
          if (call == 1) return Future.error(const PlanRateLimitedException());
          if (call == 2) {
            return Future.error(const PlanLlmUnavailableException('x'));
          }
          return Future.error(
              const PlanValidationException('instruction is required.'));
        });
      },
      build: noCommit,
      seed: () => PlanEditorReady(plan: _plan()),
      act: (b) async {
        b.add(const PlanEditorRefine('a'));
        await Future<void>.delayed(Duration.zero);
        b.add(const PlanEditorRefine('b'));
        await Future<void>.delayed(Duration.zero);
        b.add(const PlanEditorRefine('c'));
      },
      expect: () => [
        isA<PlanEditorReady>().having((s) => s.isRefining, 'refining', true),
        isA<PlanEditorReady>().having((s) => s.lastErrorMessage, 'message',
            'Túl sok refine kérés — próbáld újra egy perc múlva.'),
        isA<PlanEditorReady>().having((s) => s.isRefining, 'refining', true),
        isA<PlanEditorReady>().having((s) => s.lastErrorMessage, 'message',
            'Az AI finomítás most nem érhető el. Próbáld újra később.'),
        isA<PlanEditorReady>().having((s) => s.isRefining, 'refining', true),
        isA<PlanEditorReady>()
            .having((s) => s.isRefining, 'refining', false)
            .having((s) => s.lastErrorMessage, 'message',
                'Írd le, mit változtassunk a terven.'),
      ],
    );

    blocTest<PlanEditorBloc, PlanEditorState>(
      'accept conflict is translated',
      setUp: () => when(() => repo.accept(any())).thenAnswer((_) =>
          Future.error(const PlanConflictException('Plan already materialized.'))),
      build: noCommit,
      seed: () => PlanEditorReady(plan: _plan()),
      act: (b) => b.add(const PlanEditorAccept()),
      expect: () => [
        isA<PlanEditorReady>(),
        isA<PlanEditorReady>()
            .having((s) => s.isAccepting, 'accepting', false)
            .having((s) => s.lastErrorMessage, 'message',
                'A terv már be van ütemezve, ezért nem módosítható.'),
      ],
    );

    blocTest<PlanEditorBloc, PlanEditorState>(
      'materialize before accept is explained',
      setUp: () => when(() => repo.materialize(
            planId: any(named: 'planId'),
            startDate: any(named: 'startDate'),
          )).thenAnswer((_) => Future.error(const PlanConflictException(
          'Accept the plan before materializing it.'))),
      build: noCommit,
      seed: () => PlanEditorReady(plan: _plan(status: PlanStatuses.accepted)),
      act: (b) => b.add(PlanEditorMaterialize(DateTime.utc(2026, 11, 23))),
      expect: () => [
        isA<PlanEditorReady>(),
        isA<PlanEditorReady>().having((s) => s.lastErrorMessage, 'message',
            'Előbb fogadd el a tervet, csak utána ütemezhető.'),
      ],
    );

    blocTest<PlanEditorBloc, PlanEditorState>(
      'materialize rejected for plan shape is explained',
      setUp: () => when(() => repo.materialize(
            planId: any(named: 'planId'),
            startDate: any(named: 'startDate'),
          )).thenAnswer((_) => Future.error(const PlanValidationException(
          'plan.Days.Count must be in 1..7 (got 0).'))),
      build: noCommit,
      seed: () => PlanEditorReady(plan: _plan(status: PlanStatuses.accepted)),
      act: (b) => b.add(PlanEditorMaterialize(DateTime.utc(2026, 11, 23))),
      expect: () => [
        isA<PlanEditorReady>(),
        isA<PlanEditorReady>().having((s) => s.lastErrorMessage, 'message',
            'A terv nem ütemezhető: ellenőrizd a hetek és a napok számát.'),
      ],
    );

    blocTest<PlanEditorBloc, PlanEditorState>(
      'a failed validate keeps the old violations and reports it',
      setUp: () =>
          when(() => repo.validate(any())).thenThrow(Exception('boom')),
      build: noCommit,
      seed: () => PlanEditorReady(plan: _plan()),
      act: (b) => b.add(const PlanEditorValidate()),
      expect: () => [
        isA<PlanEditorReady>(),
        isA<PlanEditorReady>().having((s) => s.lastErrorMessage, 'message',
            'Nem sikerült az ellenőrzés.'),
      ],
    );
  });

  group('scheduling a draft', () {
    final scheduled = MaterializeResultModel(
      planId: 'p1',
      workoutsCreated: 8,
      scheduledFrom: DateTime.utc(2026, 11, 23),
      scheduledTo: DateTime.utc(2026, 12, 14),
    );

    blocTest<PlanEditorBloc, PlanEditorState>(
      'accepts first, then materializes, in that order',
      setUp: () {
        when(() => repo.accept('p1')).thenAnswer(
            (_) async => _plan(status: PlanStatuses.accepted));
        when(() => repo.materialize(
              planId: any(named: 'planId'),
              startDate: any(named: 'startDate'),
            )).thenAnswer((_) async => scheduled);
      },
      build: noCommit,
      seed: () => PlanEditorReady(plan: _plan()),
      act: (b) => b.add(PlanEditorMaterialize(DateTime.utc(2026, 11, 23))),
      expect: () => [
        isA<PlanEditorReady>().having((s) => s.isAccepting, 'busy', true),
        isA<PlanEditorMaterialized>()
            .having((s) => s.plan.status, 'status', PlanStatuses.materialized)
            .having((s) => s.result.workoutsCreated, 'workouts', 8),
      ],
      verify: (_) => verifyInOrder([
        () => repo.accept('p1'),
        () => repo.materialize(
            planId: 'p1', startDate: DateTime.utc(2026, 11, 23)),
      ]),
    );

    blocTest<PlanEditorBloc, PlanEditorState>(
      'a draft with errors is not scheduled',
      build: noCommit,
      seed: () => PlanEditorReady(
        plan: _plan(),
        errors: const [
          ViolationModel(
              code: ViolationCodes.sessionTooLong,
              severity: ViolationSeverity.error,
              message: 'Day 0 estimated 95 min, limit 60 min.'),
        ],
      ),
      act: (b) => b.add(PlanEditorMaterialize(DateTime.utc(2026, 11, 23))),
      expect: () => const <PlanEditorState>[],
      verify: (_) {
        verifyNever(() => repo.accept(any()));
        verifyNever(() => repo.materialize(
            planId: any(named: 'planId'), startDate: any(named: 'startDate')));
      },
    );

    blocTest<PlanEditorBloc, PlanEditorState>(
      'if scheduling fails after acceptance, the plan shows as accepted',
      setUp: () {
        when(() => repo.accept('p1')).thenAnswer(
            (_) async => _plan(status: PlanStatuses.accepted));
        when(() => repo.materialize(
              planId: any(named: 'planId'),
              startDate: any(named: 'startDate'),
            )).thenThrow(Exception('boom'));
      },
      build: noCommit,
      seed: () => PlanEditorReady(plan: _plan()),
      act: (b) => b.add(PlanEditorMaterialize(DateTime.utc(2026, 11, 23))),
      expect: () => [
        isA<PlanEditorReady>(),
        isA<PlanEditorReady>()
            .having((s) => s.plan.status, 'status', PlanStatuses.accepted)
            .having((s) => s.isAccepting, 'busy', false)
            .having((s) => s.canMaterialize, 'retry possible', true)
            .having((s) => s.lastErrorMessage, 'message',
                'Az ütemezés nem sikerült.'),
      ],
    );
  });

  test('canAccept / canMaterialize follow status and in-flight work', () {
    final draft = PlanEditorReady(plan: _plan());
    expect(draft.canAccept, isTrue);
    expect(draft.canMaterialize, isFalse);
    expect(draft.copyWith(isSaving: true).canAccept, isFalse);
    final accepted = PlanEditorReady(plan: _plan(status: PlanStatuses.accepted));
    expect(accepted.canAccept, isFalse);
    expect(accepted.canMaterialize, isTrue);
    expect(accepted.copyWith(isRefining: true).canMaterialize, isFalse);
  });
}
