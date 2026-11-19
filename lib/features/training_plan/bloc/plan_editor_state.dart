import 'package:flutter_application_1/features/athlete_profile/data/models/athlete_profile_model.dart';
import 'package:flutter_application_1/features/training_plan/data/models/plan_results.dart';
import 'package:flutter_application_1/features/training_plan/data/models/training_plan_model.dart';
import 'package:flutter_application_1/features/training_plan/data/models/violation_model.dart';

abstract class PlanEditorState {
  const PlanEditorState();
}

class PlanEditorInitial extends PlanEditorState {
  const PlanEditorInitial();
}

/// Active editing state. Fields change incrementally via [copyWith] so the
/// bloc stays testable with value-equality on individual fields.
class PlanEditorReady extends PlanEditorState {
  final TrainingPlanModel plan;
  final AthleteProfileModel? profile;
  final List<ViolationModel> warnings;
  final List<ViolationModel> errors;

  /// True while a PUT to `/api/plan/{id}` is in flight.
  final bool isSaving;

  /// True while `/refine` is in flight.
  final bool isRefining;

  /// True while `/accept` or `/materialize` is in flight.
  final bool isAccepting;

  /// True while `/validate` runs (on open and on explicit re-checks).
  /// Accept stays disabled until the violations are known.
  final bool isValidating;

  /// Days whose rows should pulse after the latest refine (3 s window).
  /// Empty outside of refine animations.
  final Set<int> highlightedDays;

  /// Pre-refine snapshot of [plan] + violations so Undo can revert. Null
  /// when nothing to undo.
  final RefineSnapshot? refineUndo;

  /// Error toasted on the current action (PUT/refine/accept). Cleared on
  /// the next user action.
  final String? lastErrorMessage;

  const PlanEditorReady({
    required this.plan,
    this.profile,
    this.warnings = const [],
    this.errors = const [],
    this.isSaving = false,
    this.isRefining = false,
    this.isAccepting = false,
    this.isValidating = false,
    this.highlightedDays = const {},
    this.refineUndo,
    this.lastErrorMessage,
  });

  bool get _idle => !isSaving && !isRefining && !isAccepting && !isValidating;

  bool get canAccept =>
      errors.isEmpty && _idle && plan.status == PlanStatuses.draft;

  bool get canMaterialize => _idle && plan.status == PlanStatuses.accepted;

  PlanEditorReady copyWith({
    TrainingPlanModel? plan,
    AthleteProfileModel? profile,
    List<ViolationModel>? warnings,
    List<ViolationModel>? errors,
    bool? isSaving,
    bool? isRefining,
    bool? isAccepting,
    bool? isValidating,
    Set<int>? highlightedDays,
    RefineSnapshot? refineUndo,
    bool clearRefineUndo = false,
    String? lastErrorMessage,
    bool clearError = false,
  }) =>
      PlanEditorReady(
        plan: plan ?? this.plan,
        profile: profile ?? this.profile,
        warnings: warnings ?? this.warnings,
        errors: errors ?? this.errors,
        isSaving: isSaving ?? this.isSaving,
        isRefining: isRefining ?? this.isRefining,
        isAccepting: isAccepting ?? this.isAccepting,
        isValidating: isValidating ?? this.isValidating,
        highlightedDays: highlightedDays ?? this.highlightedDays,
        refineUndo:
            clearRefineUndo ? null : (refineUndo ?? this.refineUndo),
        lastErrorMessage:
            clearError ? null : (lastErrorMessage ?? this.lastErrorMessage),
      );
}

/// Snapshot of the editable plan fields taken just before a refine, so
/// the editor bloc can one-shot undo back to the pre-refine state.
class RefineSnapshot {
  final List<PlanDayModel> days;
  final String title;
  final int weeks;
  final String split;
  const RefineSnapshot({
    required this.days,
    required this.title,
    required this.weeks,
    required this.split,
  });
}

/// Terminal state after materialize. The page listens for this to navigate
/// to the trainer calendar; keeping it a separate state (rather than a Ready
/// flag) makes that one-shot transition unambiguous.
class PlanEditorMaterialized extends PlanEditorState {
  final TrainingPlanModel plan;
  final MaterializeResultModel result;
  const PlanEditorMaterialized({required this.plan, required this.result});
}
