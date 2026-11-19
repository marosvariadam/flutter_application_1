import 'package:flutter_application_1/features/athlete_profile/data/models/athlete_profile_model.dart';
import 'package:flutter_application_1/features/exercise/data/models/exercise_model.dart';
import 'package:flutter_application_1/features/training_plan/data/models/training_plan_model.dart';

abstract class PlanEditorEvent {
  const PlanEditorEvent();
}

/// Seeds the editor with a plan already in hand (e.g. the one returned by
/// the generate wizard). The optional profile is used for MEV/MRV lines on
/// the volume chart and for violation-prefetch rendering.
class PlanEditorLoad extends PlanEditorEvent {
  final TrainingPlanModel plan;
  final AthleteProfileModel? profile;
  const PlanEditorLoad({required this.plan, this.profile});
}

/// Local mutation of an existing exercise row. Debounced-committed to the
/// backend via a PUT so the server's validator can re-check the plan.
class PlanEditorEditExercise extends PlanEditorEvent {
  final int dayIndex;
  final int exerciseIndex;
  final PlannedExerciseModel updated;
  const PlanEditorEditExercise({
    required this.dayIndex,
    required this.exerciseIndex,
    required this.updated,
  });
}

/// Replace the exercise at (dayIndex, exerciseIndex) with a different one
/// from the library, preserving sets / rep range / RPE / rest.
class PlanEditorSwapExercise extends PlanEditorEvent {
  final int dayIndex;
  final int exerciseIndex;
  final ExerciseModel newExercise;
  const PlanEditorSwapExercise({
    required this.dayIndex,
    required this.exerciseIndex,
    required this.newExercise,
  });
}

class PlanEditorReorderExercise extends PlanEditorEvent {
  final int dayIndex;
  final int fromIndex;
  final int toIndex;
  const PlanEditorReorderExercise({
    required this.dayIndex,
    required this.fromIndex,
    required this.toIndex,
  });
}

class PlanEditorAddExercise extends PlanEditorEvent {
  final int dayIndex;
  final ExerciseModel exercise;
  const PlanEditorAddExercise({
    required this.dayIndex,
    required this.exercise,
  });
}

class PlanEditorRemoveExercise extends PlanEditorEvent {
  final int dayIndex;
  final int exerciseIndex;
  const PlanEditorRemoveExercise({
    required this.dayIndex,
    required this.exerciseIndex,
  });
}

/// Fire-event from the debounce timer. Public so the test can drive the
/// bloc deterministically.
class PlanEditorCommit extends PlanEditorEvent {
  const PlanEditorCommit();
}

/// Expire the "changed rows" highlight after the refine animation.
class PlanEditorClearHighlights extends PlanEditorEvent {
  const PlanEditorClearHighlights();
}

/// Natural-language refine via `/refine`. Previous days are snapshotted
/// so one undo pops the plan back to the pre-refine state.
class PlanEditorRefine extends PlanEditorEvent {
  final String instruction;
  const PlanEditorRefine(this.instruction);
}

class PlanEditorUndoRefine extends PlanEditorEvent {
  const PlanEditorUndoRefine();
}

/// Explicit re-validate from the UI. Debounced edits auto-trigger a
/// PUT (which re-validates server-side), so this is mostly a "retry"
/// affordance when a previous validation failed.
class PlanEditorValidate extends PlanEditorEvent {
  const PlanEditorValidate();
}

/// Accept the draft — backend transitions status to Accepted. Errors in
/// the current validation block this; the UI disables the button.
class PlanEditorAccept extends PlanEditorEvent {
  const PlanEditorAccept();
}

/// Materialize the plan into concrete Workouts starting on [startDate],
/// accepting it first if it is still a draft. Terminal transition: moves
/// the bloc to `PlanEditorMaterialized`, which the page observes to
/// navigate away.
class PlanEditorMaterialize extends PlanEditorEvent {
  final DateTime startDate;
  const PlanEditorMaterialize(this.startDate);
}
