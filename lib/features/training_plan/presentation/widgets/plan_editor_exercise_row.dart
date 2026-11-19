import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/exercise/data/models/exercise_model.dart';
import 'package:flutter_application_1/features/exercise/data/repositories/exercise_repository.dart';
import 'package:flutter_application_1/features/exercise/presentation/widgets/exercise_picker.dart';
import 'package:flutter_application_1/features/training_plan/bloc/plan_editor_bloc.dart';
import 'package:flutter_application_1/features/training_plan/data/models/training_plan_model.dart';
import 'package:flutter_application_1/features/training_plan/data/models/violation_model.dart';
import 'package:flutter_application_1/features/training_plan/presentation/widgets/plan_editor_violation_badge.dart';

/// Editable row for one planned exercise. Fields: sets, rep min/max,
/// target RPE, rest seconds. Swap opens the shared `ExercisePicker`
/// pre-filtered to the same movement pattern (via the exercise row's
/// `movementPattern` when known).
class PlanEditorExerciseRow extends StatefulWidget {
  final int dayIndex;
  final int exerciseIndex;
  final PlannedExerciseModel exercise;
  final List<ViolationModel> rowViolations;

  /// Null = no movement-pattern filter applied to the swap picker. Passed
  /// in from the page because `PlannedExerciseModel` doesn't carry the
  /// pattern itself — only the referenced `ExerciseModel` does.
  final String? movementPattern;

  /// Pulse the row background for ~3 s after refine so the trainer can
  /// see which rows the LLM touched.
  final bool highlighted;

  const PlanEditorExerciseRow({
    super.key,
    required this.dayIndex,
    required this.exerciseIndex,
    required this.exercise,
    required this.rowViolations,
    this.movementPattern,
    this.highlighted = false,
  });

  @override
  State<PlanEditorExerciseRow> createState() => _PlanEditorExerciseRowState();
}

class _PlanEditorExerciseRowState extends State<PlanEditorExerciseRow> {
  late final TextEditingController _sets;
  late final TextEditingController _repMin;
  late final TextEditingController _repMax;
  late final TextEditingController _rpe;
  late final TextEditingController _rest;

  @override
  void initState() {
    super.initState();
    _sets = TextEditingController(text: widget.exercise.sets.toString());
    _repMin = TextEditingController(text: widget.exercise.repMin.toString());
    _repMax = TextEditingController(text: widget.exercise.repMax.toString());
    _rpe = TextEditingController(text: widget.exercise.targetRpe.toString());
    _rest = TextEditingController(text: widget.exercise.restSeconds.toString());
  }

  @override
  void didUpdateWidget(covariant PlanEditorExerciseRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // External update (refine / undo / swap) — refresh the field texts
    // without disturbing the user's current focus.
    _syncIfChanged(_sets, widget.exercise.sets.toString());
    _syncIfChanged(_repMin, widget.exercise.repMin.toString());
    _syncIfChanged(_repMax, widget.exercise.repMax.toString());
    _syncIfChanged(_rpe, widget.exercise.targetRpe.toString());
    _syncIfChanged(_rest, widget.exercise.restSeconds.toString());
  }

  void _syncIfChanged(TextEditingController c, String value) {
    if (c.text != value) c.text = value;
  }

  @override
  void dispose() {
    _sets.dispose();
    _repMin.dispose();
    _repMax.dispose();
    _rpe.dispose();
    _rest.dispose();
    super.dispose();
  }

  void _commitEdit() {
    final updated = PlannedExerciseModel(
      exerciseId: widget.exercise.exerciseId,
      name: widget.exercise.name,
      muscleGroup: widget.exercise.muscleGroup,
      sets: int.tryParse(_sets.text) ?? widget.exercise.sets,
      repMin: int.tryParse(_repMin.text) ?? widget.exercise.repMin,
      repMax: int.tryParse(_repMax.text) ?? widget.exercise.repMax,
      targetRpe: int.tryParse(_rpe.text) ?? widget.exercise.targetRpe,
      restSeconds: int.tryParse(_rest.text) ?? widget.exercise.restSeconds,
      order: widget.exercise.order,
      notes: widget.exercise.notes,
    );
    context.read<PlanEditorBloc>().add(PlanEditorEditExercise(
          dayIndex: widget.dayIndex,
          exerciseIndex: widget.exerciseIndex,
          updated: updated,
        ));
  }

  Future<void> _openSwapPicker() async {
    final repo = context.read<ExerciseRepository>();
    final blocRef = context.read<PlanEditorBloc>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DT.of(context).cardSurfaceElevated,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(DT.rCard))),
      builder: (sheet) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, ctrl) => ExercisePicker(
          exerciseRepo: repo,
          athleteId: null,
          scrollController: ctrl,
          initialMovementPattern: widget.movementPattern,
          onSelect: (ExerciseModel picked) {
            blocRef.add(PlanEditorSwapExercise(
              dayIndex: widget.dayIndex,
              exerciseIndex: widget.exerciseIndex,
              newExercise: picked,
            ));
            Navigator.of(sheet).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final errs = widget.rowViolations.where((v) => v.isError).toList();
    final warns = widget.rowViolations.where((v) => v.isWarning).toList();
    final rowColor = widget.highlighted
        ? DT.of(context).accentPrimary.withValues(alpha: 0.10)
        : DT.of(context).cardSurface;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: DT.s2),
      padding: const EdgeInsets.all(DT.s3),
      decoration: BoxDecoration(
        color: rowColor,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        boxShadow: [
          BoxShadow(
              color: DT.of(context).shadowLight,
              blurRadius: 6,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.exercise.name,
                      style: TextStyle(
                          color: DT.of(context).textPrimary,
                          fontSize: DT.s3,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.exercise.muscleGroup,
                      style: TextStyle(
                          color: DT.of(context).textSecondary,
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Csere',
                icon:
                    Icon(Icons.swap_horiz, color: DT.of(context).iconLight),
                onPressed: _openSwapPicker,
              ),
              IconButton(
                tooltip: 'Törlés',
                icon: Icon(Icons.delete_outline, color: DT.of(context).accentDanger),
                onPressed: () => context
                    .read<PlanEditorBloc>()
                    .add(PlanEditorRemoveExercise(
                      dayIndex: widget.dayIndex,
                      exerciseIndex: widget.exerciseIndex,
                    )),
              ),
            ],
          ),
          const SizedBox(height: DT.s2),
          Row(
            children: [
              _NumField(label: 'Szett', controller: _sets, onEdited: _commitEdit),
              const SizedBox(width: DT.s2),
              _NumField(
                  label: 'Ism. min',
                  controller: _repMin,
                  onEdited: _commitEdit),
              const SizedBox(width: DT.s2),
              _NumField(
                  label: 'Ism. max',
                  controller: _repMax,
                  onEdited: _commitEdit),
              const SizedBox(width: DT.s2),
              _NumField(label: 'RPE', controller: _rpe, onEdited: _commitEdit),
              const SizedBox(width: DT.s2),
              _NumField(
                  label: 'Pihenő (s)',
                  controller: _rest,
                  onEdited: _commitEdit),
            ],
          ),
          if (errs.isNotEmpty || warns.isNotEmpty) ...[
            const SizedBox(height: DT.s2),
            Wrap(
              spacing: DT.s2,
              runSpacing: DT.s1,
              children: [
                ...errs.map((v) => PlanEditorViolationBadge(violation: v)),
                ...warns.map((v) => PlanEditorViolationBadge(violation: v)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onEdited;

  const _NumField({
    required this.label,
    required this.controller,
    required this.onEdited,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
                color: DT.of(context).textSecondary, fontSize: 10),
          ),
          const SizedBox(height: 2),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onChanged: (_) => onEdited(),
            style: TextStyle(
                color: DT.of(context).textPrimary,
                fontSize: DT.s3,
                fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: DT.s1),
              filled: true,
              fillColor: DT.of(context).bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DT.rCardSmall),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
