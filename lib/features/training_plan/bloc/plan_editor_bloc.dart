import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_application_1/core/api/api_error_messages.dart';
import 'package:flutter_application_1/features/training_plan/bloc/plan_messages.dart';

import 'package:flutter_application_1/features/training_plan/bloc/plan_editor_events.dart';
import 'package:flutter_application_1/features/training_plan/bloc/plan_editor_state.dart';
import 'package:flutter_application_1/features/training_plan/data/models/training_plan_model.dart';
import 'package:flutter_application_1/features/training_plan/data/repositories/training_plan_repository.dart';

// Re-export events and state so callers can import `plan_editor_bloc.dart`
// alone and get everything they need (matches the training_block pattern
// where events, states and bloc share one import).
export 'package:flutter_application_1/features/training_plan/bloc/plan_editor_events.dart';
export 'package:flutter_application_1/features/training_plan/bloc/plan_editor_state.dart';

class PlanEditorBloc extends Bloc<PlanEditorEvent, PlanEditorState> {
  final TrainingPlanRepository _repo;
  final Duration _debounce;

  /// Commits pending local edits to the backend after the debounce elapses.
  Timer? _commitTimer;

  /// Clears the refine highlight after its 3 s window.
  Timer? _highlightTimer;

  PlanEditorBloc(
    this._repo, {
    Duration debounce = const Duration(milliseconds: 500),
  })  : _debounce = debounce,
        super(const PlanEditorInitial()) {
    on<PlanEditorLoad>(_onLoad);
    on<PlanEditorEditExercise>(_onEdit);
    on<PlanEditorSwapExercise>(_onSwap);
    on<PlanEditorReorderExercise>(_onReorder);
    on<PlanEditorAddExercise>(_onAdd);
    on<PlanEditorRemoveExercise>(_onRemove);
    on<PlanEditorCommit>(_onCommit);
    on<PlanEditorClearHighlights>(_onClearHighlights);
    on<PlanEditorValidate>(_onValidate);
    on<PlanEditorRefine>(_onRefine);
    on<PlanEditorUndoRefine>(_onUndoRefine);
    on<PlanEditorAccept>(_onAccept);
    on<PlanEditorMaterialize>(_onMaterialize);
  }

  @override
  Future<void> close() {
    _commitTimer?.cancel();
    _highlightTimer?.cancel();
    return super.close();
  }

  // ── Handlers ──

  /// Shows the plan immediately and validates it, so violations (and the
  /// disabled Accept button) are right from the first frame after opening.
  Future<void> _onLoad(
      PlanEditorLoad e, Emitter<PlanEditorState> emit) async {
    emit(PlanEditorReady(
        plan: e.plan, profile: e.profile, isValidating: true));
    await _runValidation(emit);
  }

  void _onEdit(PlanEditorEditExercise e, Emitter<PlanEditorState> emit) {
    final s = state;
    if (s is! PlanEditorReady) return;
    final newPlan = _mutatePlan(s.plan, e.dayIndex, (day) {
      final list = List<PlannedExerciseModel>.from(day.exercises);
      if (e.exerciseIndex < 0 || e.exerciseIndex >= list.length) return day;
      list[e.exerciseIndex] = e.updated;
      return PlanDayModel(
          dayIndex: day.dayIndex, label: day.label, exercises: list);
    });
    emit(s.copyWith(plan: newPlan, clearError: true));
    _scheduleCommit();
  }

  void _onSwap(PlanEditorSwapExercise e, Emitter<PlanEditorState> emit) {
    final s = state;
    if (s is! PlanEditorReady) return;
    final newPlan = _mutatePlan(s.plan, e.dayIndex, (day) {
      final list = List<PlannedExerciseModel>.from(day.exercises);
      if (e.exerciseIndex < 0 || e.exerciseIndex >= list.length) return day;
      final current = list[e.exerciseIndex];
      list[e.exerciseIndex] = PlannedExerciseModel(
        exerciseId: e.newExercise.id,
        name: e.newExercise.name,
        muscleGroup: e.newExercise.muscleGroup,
        sets: current.sets,
        repMin: current.repMin,
        repMax: current.repMax,
        targetRpe: current.targetRpe,
        restSeconds: current.restSeconds,
        order: current.order,
        notes: current.notes,
      );
      return PlanDayModel(
          dayIndex: day.dayIndex, label: day.label, exercises: list);
    });
    emit(s.copyWith(plan: newPlan, clearError: true));
    _scheduleCommit();
  }

  void _onReorder(
      PlanEditorReorderExercise e, Emitter<PlanEditorState> emit) {
    final s = state;
    if (s is! PlanEditorReady) return;
    final newPlan = _mutatePlan(s.plan, e.dayIndex, (day) {
      final list = List<PlannedExerciseModel>.from(day.exercises);
      if (e.fromIndex < 0 ||
          e.fromIndex >= list.length ||
          e.toIndex < 0 ||
          e.toIndex > list.length) {
        return day;
      }
      final moved = list.removeAt(e.fromIndex);
      // Clamp toIndex if we removed something before it.
      final insertAt = e.toIndex > e.fromIndex ? e.toIndex - 1 : e.toIndex;
      list.insert(insertAt, moved);
      // Re-stamp order so the server's PUT sees a clean 0..n-1 sequence.
      for (var i = 0; i < list.length; i++) {
        final ex = list[i];
        list[i] = _withOrder(ex, i);
      }
      return PlanDayModel(
          dayIndex: day.dayIndex, label: day.label, exercises: list);
    });
    emit(s.copyWith(plan: newPlan, clearError: true));
    _scheduleCommit();
  }

  void _onAdd(PlanEditorAddExercise e, Emitter<PlanEditorState> emit) {
    final s = state;
    if (s is! PlanEditorReady) return;
    final newPlan = _mutatePlan(s.plan, e.dayIndex, (day) {
      final list = List<PlannedExerciseModel>.from(day.exercises)
        ..add(PlannedExerciseModel(
          exerciseId: e.exercise.id,
          name: e.exercise.name,
          muscleGroup: e.exercise.muscleGroup,
          sets: 3,
          repMin: 8,
          repMax: 12,
          targetRpe: 8,
          restSeconds: 90,
          order: day.exercises.length,
        ));
      return PlanDayModel(
          dayIndex: day.dayIndex, label: day.label, exercises: list);
    });
    emit(s.copyWith(plan: newPlan, clearError: true));
    _scheduleCommit();
  }

  void _onRemove(
      PlanEditorRemoveExercise e, Emitter<PlanEditorState> emit) {
    final s = state;
    if (s is! PlanEditorReady) return;
    final newPlan = _mutatePlan(s.plan, e.dayIndex, (day) {
      final list = List<PlannedExerciseModel>.from(day.exercises);
      if (e.exerciseIndex < 0 || e.exerciseIndex >= list.length) return day;
      list.removeAt(e.exerciseIndex);
      for (var i = 0; i < list.length; i++) {
        list[i] = _withOrder(list[i], i);
      }
      return PlanDayModel(
          dayIndex: day.dayIndex, label: day.label, exercises: list);
    });
    emit(s.copyWith(plan: newPlan, clearError: true));
    _scheduleCommit();
  }

  Future<void> _onCommit(
      PlanEditorCommit e, Emitter<PlanEditorState> emit) async {
    final s = state;
    if (s is! PlanEditorReady) return;
    emit(s.copyWith(isSaving: true, clearError: true));
    try {
      final res = await _repo.update(
        planId: s.plan.id,
        title: s.plan.title,
        weeks: s.plan.weeks,
        split: s.plan.split,
        days: s.plan.days,
      );
      // Server re-validated and returned the authoritative plan. Replace
      // local state with its answer so a stale optimistic change doesn't
      // win over a server-side correction.
      final latest = state;
      if (latest is! PlanEditorReady) return;
      emit(latest.copyWith(
        plan: res.plan,
        warnings: res.warnings,
        errors: res.errors,
        isSaving: false,
      ));
    } on PlanConflictException catch (ex) {
      _emitError(emit,
          isSaving: false,
          message: planServerMessageHu(ex.message,
              fallback: 'A terv már nem szerkeszthető.'));
    } catch (e) {
      _emitError(emit,
          isSaving: false,
          message: friendlyErrorMessage(e,
              fallback: 'Nem sikerült menteni a változtatást.'));
    }
  }

  Future<void> _onValidate(
      PlanEditorValidate e, Emitter<PlanEditorState> emit) async {
    final s = state;
    if (s is! PlanEditorReady) return;
    emit(s.copyWith(isValidating: true, clearError: true));
    await _runValidation(emit);
  }

  Future<void> _runValidation(Emitter<PlanEditorState> emit) async {
    final s = state;
    if (s is! PlanEditorReady) return;
    try {
      final res = await _repo.validate(s.plan.id);
      final latest = state;
      if (latest is! PlanEditorReady) return;
      emit(latest.copyWith(
        warnings: res.warnings,
        errors: res.errors,
        isValidating: false,
      ));
    } catch (e) {
      _emitError(emit,
          isValidating: false,
          message:
              friendlyErrorMessage(e, fallback: 'Nem sikerült az ellenőrzés.'));
    }
  }

  Future<void> _onRefine(
      PlanEditorRefine e, Emitter<PlanEditorState> emit) async {
    final s = state;
    if (s is! PlanEditorReady) return;
    final snapshot = RefineSnapshot(
      days: s.plan.days,
      title: s.plan.title,
      weeks: s.plan.weeks,
      split: s.plan.split,
    );
    emit(s.copyWith(isRefining: true, clearError: true));
    try {
      final res = await _repo.refine(
        planId: s.plan.id,
        instruction: e.instruction,
      );
      final changedDays = res.diff.map((d) => d.dayIndex).toSet();
      final latest = state;
      if (latest is! PlanEditorReady) return;
      emit(latest.copyWith(
        plan: res.plan,
        warnings: res.warnings,
        errors: res.errors,
        isRefining: false,
        highlightedDays: changedDays,
        refineUndo: snapshot,
      ));
      // Clear the pulse after the 3 s window. No-op if the bloc closes
      // or the user triggers another refine first.
      _highlightTimer?.cancel();
      _highlightTimer = Timer(const Duration(seconds: 3), () {
        if (!isClosed) add(const PlanEditorClearHighlights());
      });
    } on PlanRateLimitedException {
      _emitError(emit,
          isRefining: false,
          message:
              'Túl sok refine kérés — próbáld újra egy perc múlva.');
    } on PlanLlmUnavailableException {
      _emitError(emit,
          isRefining: false,
          message: 'Az AI finomítás most nem érhető el. Próbáld újra később.');
    } on PlanValidationException catch (ex) {
      _emitError(emit,
          isRefining: false,
          message: planServerMessageHu(ex.message,
              fallback: 'A finomítás nem sikerült.'));
    } catch (e) {
      _emitError(emit,
          isRefining: false,
          message:
              friendlyErrorMessage(e, fallback: 'A finomítás nem sikerült.'));
    }
  }

  Future<void> _onUndoRefine(
      PlanEditorUndoRefine e, Emitter<PlanEditorState> emit) async {
    final s = state;
    if (s is! PlanEditorReady || s.refineUndo == null) return;
    final snap = s.refineUndo!;
    emit(s.copyWith(isSaving: true, clearError: true));
    try {
      final res = await _repo.update(
        planId: s.plan.id,
        title: snap.title,
        weeks: snap.weeks,
        split: snap.split,
        days: snap.days,
      );
      final latest = state;
      if (latest is! PlanEditorReady) return;
      emit(latest.copyWith(
        plan: res.plan,
        warnings: res.warnings,
        errors: res.errors,
        isSaving: false,
        highlightedDays: const {},
        clearRefineUndo: true,
      ));
    } catch (e) {
      _emitError(emit,
          isSaving: false,
          message:
              friendlyErrorMessage(e, fallback: 'A visszavonás nem sikerült.'));
    }
  }

  void _onClearHighlights(
      PlanEditorClearHighlights e, Emitter<PlanEditorState> emit) {
    final s = state;
    if (s is! PlanEditorReady) return;
    if (s.highlightedDays.isEmpty) return;
    emit(s.copyWith(highlightedDays: const {}));
  }

  Future<void> _onAccept(
      PlanEditorAccept e, Emitter<PlanEditorState> emit) async {
    final s = state;
    if (s is! PlanEditorReady) return;
    if (!s.canAccept) return;
    emit(s.copyWith(isAccepting: true, clearError: true));
    try {
      final accepted = await _repo.accept(s.plan.id);
      final latest = state;
      if (latest is! PlanEditorReady) return;
      emit(latest.copyWith(plan: accepted, isAccepting: false));
    } on PlanConflictException catch (ex) {
      _emitError(emit,
          isAccepting: false,
          message: planServerMessageHu(ex.message,
              fallback: 'A terv már nem fogadható el.'));
    } catch (e) {
      _emitError(emit,
          isAccepting: false,
          message:
              friendlyErrorMessage(e, fallback: 'Az elfogadás nem sikerült.'));
    }
  }

  /// Schedules the plan. A draft is accepted first, in the same handler:
  /// separate Accept + Materialize events would run concurrently and the
  /// materialize request could reach the server before the acceptance.
  Future<void> _onMaterialize(
      PlanEditorMaterialize e, Emitter<PlanEditorState> emit) async {
    final s = state;
    if (s is! PlanEditorReady) return;
    final isDraft = s.plan.status == PlanStatuses.draft;
    if (isDraft ? !s.canAccept : !s.canMaterialize) return;
    emit(s.copyWith(isAccepting: true, clearError: true));
    var plan = s.plan;
    try {
      if (isDraft) plan = await _repo.accept(plan.id);
      final res = await _repo.materialize(
        planId: plan.id,
        startDate: e.startDate,
      );
      emit(PlanEditorMaterialized(
        plan: plan.copyWith(status: PlanStatuses.materialized),
        result: res,
      ));
    } on PlanConflictException catch (ex) {
      _emitError(emit,
          plan: plan,
          isAccepting: false,
          message: planServerMessageHu(ex.message,
              fallback: 'A terv már nem ütemezhető.'));
    } on PlanValidationException catch (ex) {
      _emitError(emit,
          plan: plan,
          isAccepting: false,
          message: planServerMessageHu(ex.message,
              fallback: 'Az ütemezés nem sikerült.'));
    } catch (e) {
      _emitError(emit,
          plan: plan,
          isAccepting: false,
          message:
              friendlyErrorMessage(e, fallback: 'Az ütemezés nem sikerült.'));
    }
  }

  // ── Helpers ──

  /// Emits a Ready copy with [message] in `lastErrorMessage` and the
  /// relevant in-flight flag toggled off. No-op if the state has moved
  /// out of Ready between the request start and its failure callback.
  void _emitError(
    Emitter<PlanEditorState> emit, {
    required String message,
    TrainingPlanModel? plan,
    bool? isSaving,
    bool? isRefining,
    bool? isAccepting,
    bool? isValidating,
  }) {
    final latest = state;
    if (latest is! PlanEditorReady) return;
    emit(latest.copyWith(
      plan: plan,
      isSaving: isSaving,
      isRefining: isRefining,
      isAccepting: isAccepting,
      isValidating: isValidating,
      lastErrorMessage: message,
    ));
  }

  void _scheduleCommit() {
    _commitTimer?.cancel();
    _commitTimer = Timer(_debounce, () {
      if (!isClosed) add(const PlanEditorCommit());
    });
  }

  TrainingPlanModel _mutatePlan(
    TrainingPlanModel plan,
    int dayIndex,
    PlanDayModel Function(PlanDayModel) mutate,
  ) {
    final days = plan.days
        .map((d) => d.dayIndex == dayIndex ? mutate(d) : d)
        .toList();
    return plan.copyWith(days: days);
  }

  PlannedExerciseModel _withOrder(PlannedExerciseModel ex, int order) =>
      PlannedExerciseModel(
        exerciseId: ex.exerciseId,
        name: ex.name,
        muscleGroup: ex.muscleGroup,
        sets: ex.sets,
        repMin: ex.repMin,
        repMax: ex.repMax,
        targetRpe: ex.targetRpe,
        restSeconds: ex.restSeconds,
        order: order,
        notes: ex.notes,
      );
}
