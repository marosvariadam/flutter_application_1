import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_application_1/features/exercise/data/models/exercise_model.dart';
import 'package:flutter_application_1/features/training_plan/bloc/plan_editor_bloc.dart';
import 'package:flutter_application_1/features/training_plan/data/models/plan_results.dart';
import 'package:flutter_application_1/features/training_plan/data/models/training_plan_model.dart';
import 'package:flutter_application_1/features/training_plan/data/models/violation_model.dart';
import 'package:flutter_application_1/features/training_plan/data/repositories/training_plan_repository.dart';

class _MockRepo extends Mock implements TrainingPlanRepository {}

TrainingPlanModel _plan({
  String id = 'p1',
  String status = PlanStatuses.draft,
  List<PlanDayModel> days = const [],
}) =>
    TrainingPlanModel(
      id: id,
      trainerId: 't1',
      athleteId: 'a1',
      title: 'Hypertrophy — 4 week',
      goal: 'Hypertrophy',
      weeks: 4,
      split: PlanSplits.upperLower,
      status: status,
      days: days,
      progression: PlanProgressionSchemes.doubleProgression,
      source: PlanGenerationSources.hybrid,
      createdAt: DateTime.utc(2026, 10, 1),
    );

PlanDayModel _day({
  int dayIndex = 0,
  String label = 'Upper A',
  List<PlannedExerciseModel> exercises = const [],
}) =>
    PlanDayModel(dayIndex: dayIndex, label: label, exercises: exercises);

PlannedExerciseModel _ex({
  String? exerciseId = 'e1',
  String name = 'Bench Press',
  String muscleGroup = 'Chest',
  int sets = 3,
  int repMin = 6,
  int repMax = 10,
  int targetRpe = 8,
  int restSeconds = 120,
  int order = 0,
}) =>
    PlannedExerciseModel(
      exerciseId: exerciseId,
      name: name,
      muscleGroup: muscleGroup,
      sets: sets,
      repMin: repMin,
      repMax: repMax,
      targetRpe: targetRpe,
      restSeconds: restSeconds,
      order: order,
    );

RefineResultModel _refineResult({
  required TrainingPlanModel plan,
  List<ViolationModel> warnings = const [],
  List<ViolationModel> errors = const [],
  List<DayDiffModel> diff = const [],
}) =>
    RefineResultModel(
      plan: plan,
      warnings: warnings,
      errors: errors,
      diff: diff,
    );

void main() {
  late _MockRepo repo;
  late TrainingPlanModel seed;

  setUp(() {
    repo = _MockRepo();
    seed = _plan(days: [
      _day(dayIndex: 0, label: 'Upper A', exercises: [_ex()]),
      _day(dayIndex: 1, label: 'Lower A', exercises: [
        _ex(exerciseId: 'e2', name: 'Back Squat', muscleGroup: 'Legs')
      ]),
    ]);
    // Fallbacks for named arguments used in `any(named:)`.
    registerFallbackValue(<PlanDayModel>[]);
  });

  group('PlanEditorBloc', () {
    blocTest<PlanEditorBloc, PlanEditorState>(
      'load shows the plan, then validates it before Accept is allowed',
      setUp: () => when(() => repo.validate('p1')).thenAnswer((_) async =>
          ValidationResultModel(warnings: const [], errors: const [
            ViolationModel(
              code: ViolationCodes.sessionTooLong,
              severity: ViolationSeverity.error,
              message: 'Day 0 estimated 95 min, limit 60 min.',
              dayIndex: 0,
            ),
          ])),
      build: () => PlanEditorBloc(repo, debounce: Duration.zero),
      act: (b) => b.add(PlanEditorLoad(plan: seed)),
      expect: () => [
        isA<PlanEditorReady>()
            .having((s) => s.plan.id, 'id', 'p1')
            .having((s) => s.plan.days.length, 'days', 2)
            .having((s) => s.isValidating, 'validating', true)
            .having((s) => s.canAccept, 'canAccept', false),
        isA<PlanEditorReady>()
            .having((s) => s.isValidating, 'validating', false)
            .having((s) => s.errors.single.code, 'error',
                ViolationCodes.sessionTooLong)
            .having((s) => s.canAccept, 'canAccept', false),
      ],
    );

    blocTest<PlanEditorBloc, PlanEditorState>(
      'a failed validation on open still lets the trainer edit',
      setUp: () => when(() => repo.validate('p1')).thenThrow(Exception('x')),
      build: () => PlanEditorBloc(repo, debounce: Duration.zero),
      act: (b) => b.add(PlanEditorLoad(plan: seed)),
      expect: () => [
        isA<PlanEditorReady>().having((s) => s.isValidating, 'v', true),
        isA<PlanEditorReady>()
            .having((s) => s.isValidating, 'validating', false)
            .having((s) => s.lastErrorMessage, 'message',
                'Nem sikerült az ellenőrzés.'),
      ],
    );

    blocTest<PlanEditorBloc, PlanEditorState>(
      'edit → auto commit → server response updates plan + violations',
      setUp: () {
        when(() => repo.update(
              planId: any(named: 'planId'),
              title: any(named: 'title'),
              weeks: any(named: 'weeks'),
              split: any(named: 'split'),
              days: any(named: 'days'),
            )).thenAnswer((_) async => _refineResult(
              plan: seed,
              warnings: [
                const ViolationModel(
                  code: ViolationCodes.frequencyTooLow,
                  severity: ViolationSeverity.warning,
                  message: 'Chest trained < 2×/week',
                ),
              ],
            ));
      },
      build: () => PlanEditorBloc(repo, debounce: Duration.zero),
      seed: () => PlanEditorReady(plan: seed),
      act: (b) => b.add(const PlanEditorEditExercise(
        dayIndex: 0,
        exerciseIndex: 0,
        updated: PlannedExerciseModel(
          exerciseId: 'e1',
          name: 'Bench Press',
          muscleGroup: 'Chest',
          sets: 4,
          repMin: 6,
          repMax: 10,
          targetRpe: 8,
          restSeconds: 120,
          order: 0,
        ),
      )),
      wait: const Duration(milliseconds: 20),
      expect: () => [
        // 1) optimistic local edit
        isA<PlanEditorReady>().having(
          (s) => s.plan.days[0].exercises[0].sets,
          'sets',
          4,
        ),
        // 2) commit starts
        isA<PlanEditorReady>().having((s) => s.isSaving, 'isSaving', true),
        // 3) commit returns with server's re-validated plan + warnings
        isA<PlanEditorReady>()
            .having((s) => s.isSaving, 'isSaving', false)
            .having((s) => s.warnings.length, 'warnings', 1)
            .having((s) => s.warnings.first.code, 'code',
                ViolationCodes.frequencyTooLow),
      ],
      verify: (_) => verify(() => repo.update(
            planId: 'p1',
            title: any(named: 'title'),
            weeks: any(named: 'weeks'),
            split: any(named: 'split'),
            days: any(named: 'days'),
          )).called(1),
    );

    blocTest<PlanEditorBloc, PlanEditorState>(
      'validate pulls warnings + errors from the backend',
      setUp: () {
        when(() => repo.validate(any())).thenAnswer((_) async =>
            ValidationResultModel(
              warnings: [
                const ViolationModel(
                  code: ViolationCodes.patternImbalance,
                  severity: ViolationSeverity.warning,
                  message: 'Push:Pull off',
                )
              ],
              errors: [
                const ViolationModel(
                  code: ViolationCodes.volumeAboveMrv,
                  severity: ViolationSeverity.error,
                  message: 'Shoulders > MRV',
                )
              ],
            ));
      },
      build: () => PlanEditorBloc(repo, debounce: Duration.zero),
      seed: () => PlanEditorReady(plan: seed),
      act: (b) => b.add(const PlanEditorValidate()),
      expect: () => [
        // clearError emission (same values, cleared lastErrorMessage)
        isA<PlanEditorReady>(),
        isA<PlanEditorReady>()
            .having((s) => s.warnings.length, 'warnings', 1)
            .having((s) => s.errors.length, 'errors', 1)
            .having((s) => s.errors.first.code, 'code',
                ViolationCodes.volumeAboveMrv),
      ],
    );

    blocTest<PlanEditorBloc, PlanEditorState>(
      'refine updates plan, highlights changed days, and stores an undo snapshot',
      setUp: () {
        final refined = _plan(days: [
          _day(dayIndex: 0, label: 'Upper A', exercises: [
            _ex(sets: 4),
            _ex(exerciseId: 'e3', name: 'Overhead Press', muscleGroup: 'Shoulders')
          ]),
          _day(dayIndex: 1, label: 'Lower A', exercises: [
            _ex(exerciseId: 'e2', name: 'Back Squat', muscleGroup: 'Legs')
          ]),
        ]);
        when(() => repo.refine(
              planId: any(named: 'planId'),
              instruction: any(named: 'instruction'),
            )).thenAnswer((_) async => _refineResult(
              plan: refined,
              diff: const [
                DayDiffModel(dayIndex: 0, added: ['e3:3x8-12@8'], removed: []),
              ],
            ));
      },
      build: () => PlanEditorBloc(repo, debounce: Duration.zero),
      seed: () => PlanEditorReady(plan: seed),
      act: (b) => b.add(const PlanEditorRefine('More shoulder work')),
      expect: () => [
        // 1) refining starts
        isA<PlanEditorReady>()
            .having((s) => s.isRefining, 'isRefining', true),
        // 2) refine returns — new plan, highlight on day 0, undo snapshot set
        isA<PlanEditorReady>()
            .having((s) => s.isRefining, 'isRefining', false)
            .having((s) => s.plan.days[0].exercises.length, 'day0', 2)
            .having((s) => s.highlightedDays, 'highlights', {0})
            .having((s) => s.refineUndo, 'undo', isNotNull),
      ],
    );

    blocTest<PlanEditorBloc, PlanEditorState>(
      'accept marks the plan as Accepted',
      setUp: () {
        when(() => repo.accept(any())).thenAnswer((_) async =>
            _plan(status: PlanStatuses.accepted, days: seed.days));
      },
      build: () => PlanEditorBloc(repo, debounce: Duration.zero),
      seed: () => PlanEditorReady(plan: seed),
      act: (b) => b.add(const PlanEditorAccept()),
      expect: () => [
        isA<PlanEditorReady>()
            .having((s) => s.isAccepting, 'isAccepting', true),
        isA<PlanEditorReady>()
            .having((s) => s.isAccepting, 'isAccepting', false)
            .having((s) => s.plan.status, 'status', PlanStatuses.accepted),
      ],
    );

    blocTest<PlanEditorBloc, PlanEditorState>(
      'accept is a no-op when errors block it',
      build: () => PlanEditorBloc(repo, debounce: Duration.zero),
      seed: () => PlanEditorReady(
        plan: seed,
        errors: const [
          ViolationModel(
            code: ViolationCodes.volumeAboveMrv,
            severity: ViolationSeverity.error,
            message: 'Shoulders > MRV',
          ),
        ],
      ),
      act: (b) => b.add(const PlanEditorAccept()),
      expect: () => const <PlanEditorState>[],
      verify: (_) => verifyNever(() => repo.accept(any())),
    );

    blocTest<PlanEditorBloc, PlanEditorState>(
      'materialize transitions to PlanEditorMaterialized',
      setUp: () {
        when(() => repo.materialize(
              planId: any(named: 'planId'),
              startDate: any(named: 'startDate'),
            )).thenAnswer((_) async => MaterializeResultModel(
              planId: 'p1',
              workoutsCreated: 16,
              scheduledFrom: DateTime.utc(2026, 11, 20),
              scheduledTo: DateTime.utc(2026, 12, 18),
            ));
      },
      build: () => PlanEditorBloc(repo, debounce: Duration.zero),
      seed: () => PlanEditorReady(
        plan: _plan(status: PlanStatuses.accepted, days: seed.days),
      ),
      act: (b) => b.add(PlanEditorMaterialize(DateTime.utc(2026, 11, 20))),
      expect: () => [
        isA<PlanEditorReady>()
            .having((s) => s.isAccepting, 'isAccepting', true),
        isA<PlanEditorMaterialized>()
            .having((s) => s.result.workoutsCreated, 'count', 16),
      ],
    );

    blocTest<PlanEditorBloc, PlanEditorState>(
      'swap preserves prescription and schedules a commit',
      setUp: () {
        when(() => repo.update(
              planId: any(named: 'planId'),
              title: any(named: 'title'),
              weeks: any(named: 'weeks'),
              split: any(named: 'split'),
              days: any(named: 'days'),
            )).thenAnswer((_) async => _refineResult(plan: seed));
      },
      build: () => PlanEditorBloc(repo, debounce: Duration.zero),
      seed: () => PlanEditorReady(plan: seed),
      act: (b) => b.add(PlanEditorSwapExercise(
        dayIndex: 0,
        exerciseIndex: 0,
        newExercise: const ExerciseModel(
          id: 'e9',
          name: 'Incline DB Press',
          muscleGroup: 'Chest',
        ),
      )),
      wait: const Duration(milliseconds: 20),
      expect: () => [
        isA<PlanEditorReady>().having(
          (s) => s.plan.days[0].exercises[0].exerciseId,
          'swap applied',
          'e9',
        ),
        isA<PlanEditorReady>().having((s) => s.isSaving, 'isSaving', true),
        isA<PlanEditorReady>().having((s) => s.isSaving, 'isSaving', false),
      ],
    );
  });
}
