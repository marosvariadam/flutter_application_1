import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/design/dt_text.dart';
import 'package:flutter_application_1/features/workout/bloc/workout_bloc.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';
import 'package:flutter_application_1/features/workout/presentation/widgets/rpe_slider.dart';
import 'package:flutter_application_1/features/workout/presentation/widgets/workout_detail_sections.dart';
import 'package:flutter_application_1/features/workout/presentation/widgets/set_row.dart';

/// Athlete's in-progress workout: progress bar, one card per exercise with
/// set rows (steppers, numeric keyboard), RPE, then the finish actions.
///
/// Checking off a set gives a haptic tick, copies its weight/reps into the
/// next empty set of the exercise, and when the exercise is complete
/// scrolls to the next one.
class ActiveWorkoutBody extends StatefulWidget {
  final WorkoutModel workout;
  const ActiveWorkoutBody({super.key, required this.workout});

  @override
  State<ActiveWorkoutBody> createState() => _ActiveWorkoutBodyState();
}

class _ActiveWorkoutBodyState extends State<ActiveWorkoutBody> {
  late final List<List<SetEntry>> _sets;
  // Per-exercise RPE (0-10), null = not set. Optional.
  late final List<int?> _rpePerExercise;
  late final List<GlobalKey> _cardKeys;

  @override
  void initState() {
    super.initState();
    _sets = widget.workout.exercises
        .map((e) => List.generate(e.sets, (_) => SetEntry()))
        .toList();
    _rpePerExercise =
        widget.workout.exercises.map((e) => e.rpe).toList(growable: false);
    _cardKeys = List.generate(
        widget.workout.exercises.length, (_) => GlobalKey());
  }

  @override
  void dispose() {
    for (final sets in _sets) {
      for (final s in sets) {
        s.dispose();
      }
    }
    super.dispose();
  }

  int get _totalSets => _sets.fold(0, (sum, sets) => sum + sets.length);

  int get _doneSets =>
      _sets.fold(0, (sum, sets) => sum + sets.where((s) => s.isDone).length);

  /// (exercise, set) of the first set still to do, or null when all done.
  (int, int)? get _current {
    for (var e = 0; e < _sets.length; e++) {
      final s = _sets[e].indexWhere((x) => !x.isDone);
      if (s >= 0) return (e, s);
    }
    return null;
  }

  void _toggleSet(int exerciseIndex, int setIndex) {
    final sets = _sets[exerciseIndex];
    final set = sets[setIndex];
    final exercise = widget.workout.exercises[exerciseIndex];
    FocusScope.of(context).unfocus();
    setState(() => set.isDone = !set.isDone);

    if (set.isDone) {
      HapticFeedback.mediumImpact();
      _carryForward(exercise, sets, setIndex);
      final exerciseDone = sets.every((s) => s.isDone);
      if (exerciseDone && exerciseIndex + 1 < _cardKeys.length) {
        _scrollTo(exerciseIndex + 1);
      }
    }

    context.read<WorkoutBloc>().add(LogExercise(
          workoutId: widget.workout.id,
          index: exercise.index,
          actualSets: sets.where((s) => s.isDone).length,
          actualReps: set.reps ?? exercise.targetReps,
          actualWeightKg: set.weight ?? exercise.targetWeightKg,
          rpe: _rpePerExercise[exerciseIndex],
        ));
  }

  /// Pre-fills the next open set with what was just lifted, unless the
  /// athlete already typed something there.
  void _carryForward(WorkoutExercise exercise, List<SetEntry> sets, int from) {
    final next = sets.indexWhere((s) => !s.isDone, from + 1);
    if (next < 0) return;
    final done = sets[from];
    final target = sets[next];
    if (target.weightCtrl.text.isEmpty) {
      final w = done.weight ?? exercise.targetWeightKg;
      if (w > 0) target.weightCtrl.text = SetSteps.formatWeight(w);
    }
    if (target.repsCtrl.text.isEmpty) {
      target.repsCtrl.text = '${done.reps ?? exercise.targetReps}';
    }
  }

  void _scrollTo(int exerciseIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _cardKeys[exerciseIndex].currentContext;
      if (ctx == null || !mounted) return;
      final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      Scrollable.ensureVisible(ctx,
          duration: still ? Duration.zero : DT.normal,
          curve: Curves.easeOut,
          alignment: 0.05);
    });
  }

  void _onRpeChanged(int exerciseIndex, int? rpe) {
    setState(() => _rpePerExercise[exerciseIndex] = rpe);
    final exercise = widget.workout.exercises[exerciseIndex];
    final doneSets = _sets[exerciseIndex].where((s) => s.isDone).length;
    // Persist immediately so RPE survives a refresh even without toggling a set.
    if (doneSets > 0) {
      context.read<WorkoutBloc>().add(LogExercise(
            workoutId: widget.workout.id,
            index: exercise.index,
            actualSets: doneSets,
            rpe: rpe,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = _doneSets;
    final total = _totalSets;
    final current = _current;

    return Column(
      children: [
        _ProgressBar(done: done, total: total),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(DT.s5, DT.s4, DT.s5, DT.s5),
            itemCount: widget.workout.exercises.length + 1,
            itemBuilder: (context, i) {
              if (i == widget.workout.exercises.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: DT.s2),
                  child: AthleteActions(workout: widget.workout),
                );
              }
              return _ActiveExerciseCard(
                key: _cardKeys[i],
                exercise: widget.workout.exercises[i],
                sets: _sets[i],
                currentSet: current?.$1 == i ? current!.$2 : null,
                onToggleSet: (setIndex) => _toggleSet(i, setIndex),
                onEdited: () => setState(() {}),
                rpe: _rpePerExercise[i],
                onRpeChanged: (v) => _onRpeChanged(i, v),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int done;
  final int total;

  const _ProgressBar({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    final t = DTText.of(context);
    final progress = total == 0 ? 0.0 : done / total;
    final color = progress >= 1.0 ? c.accentSuccess : c.accentPrimary;

    return Container(
      padding: const EdgeInsets.fromLTRB(DT.s5, DT.s3, DT.s5, DT.s4),
      color: c.cardSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('$done / $total sorozat teljesítve',
                    style: t.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Text('${(progress * 100).round()}%',
                  style: t.caption
                      .copyWith(color: color, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: DT.s2),
          ClipRRect(
            borderRadius: BorderRadius.circular(DT.rPill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: c.bg,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              semanticsLabel: 'Haladás',
              semanticsValue: '$done / $total sorozat',
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveExerciseCard extends StatelessWidget {
  final WorkoutExercise exercise;
  final List<SetEntry> sets;

  /// Index of the set to do next in this exercise (outlined), if any.
  final int? currentSet;
  final ValueChanged<int> onToggleSet;
  final VoidCallback onEdited;
  final int? rpe;
  final ValueChanged<int?> onRpeChanged;

  const _ActiveExerciseCard({
    super.key,
    required this.exercise,
    required this.sets,
    required this.currentSet,
    required this.onToggleSet,
    required this.onEdited,
    required this.rpe,
    required this.onRpeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    final t = DTText.of(context);
    final doneSets = sets.where((s) => s.isDone).length;
    final allDone = sets.isNotEmpty && doneSets == sets.length;
    final tone = allDone ? c.accentSuccess : c.accentPrimary;

    return AnimatedContainer(
      duration: DT.normal,
      margin: const EdgeInsets.only(bottom: DT.s4),
      decoration: BoxDecoration(
        color: c.cardSurface,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        border: Border.all(
          color: allDone
              ? c.accentSuccess.withValues(alpha: 0.5)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(DT.s4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exercise.name, style: t.title),
                      if (exercise.equipmentType != null &&
                          exercise.equipmentType!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(exercise.equipmentType!, style: t.caption),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: DT.s2),
                AnimatedContainer(
                  duration: DT.normal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: DT.s3, vertical: DT.s1),
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(DT.rChip),
                  ),
                  child: Text('$doneSets / ${sets.length}',
                      style: t.caption.copyWith(
                          color: tone, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          if (exercise.instructions != null &&
              exercise.instructions!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(DT.s4, 0, DT.s4, DT.s3),
              child: Text(exercise.instructions!,
                  style: t.caption.copyWith(fontStyle: FontStyle.italic)),
            ),
          for (var i = 0; i < sets.length; i++)
            SetRow(
              setNumber: i + 1,
              entry: sets[i],
              exercise: exercise,
              isCurrent: currentSet == i,
              onToggle: () => onToggleSet(i),
              onEdited: onEdited,
            ),
          RpeSlider(value: rpe, onChanged: onRpeChanged),
          const SizedBox(height: DT.s3),
        ],
      ),
    );
  }
}
