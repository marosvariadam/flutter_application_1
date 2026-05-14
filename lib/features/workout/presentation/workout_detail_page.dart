import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/auth/bloc/auth_bloc.dart';
import 'package:flutter_application_1/features/workout/bloc/workout_bloc.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';
import 'package:flutter_application_1/features/workout/data/repositories/workout_repository.dart';

class WorkoutDetailPage extends StatelessWidget {
  final String workoutId;
  const WorkoutDetailPage({super.key, required this.workoutId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => WorkoutBloc(ctx.read<WorkoutRepository>())
        ..add(LoadWorkoutDetail(workoutId)),
      child: WorkoutDetailView(workoutId: workoutId),
    );
  }
}

class WorkoutDetailView extends StatelessWidget {
  final String workoutId;
  const WorkoutDetailView({super.key, required this.workoutId});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isTrainer =
        authState is AuthAuthenticated && authState.user.isTrainer;

    return BlocConsumer<WorkoutBloc, WorkoutState>(
      listener: (context, state) {
        if (state is WorkoutActionSuccess) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
          if (state.workout?.status == WorkoutStatus.completed) {
            context.pop();
          }
        }
        if (state is WorkoutError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        if (state is WorkoutLoading) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (state is WorkoutDetailLoaded) {
          final w = state.workout;

          // ── Active workout view (athlete, in-progress) ──────────────────
          if (!isTrainer && w.status == WorkoutStatus.inProgress) {
            return Scaffold(
              backgroundColor: DT.of(context).bg,
              appBar: AppBar(
                backgroundColor: DT.of(context).bg,
                elevation: 0,
                leading: BackButton(color: DT.of(context).textPrimary),
                title: Text(w.title,
                    style: TextStyle(
                        color: DT.of(context).textPrimary,
                        fontWeight: FontWeight.w600)),
                centerTitle: true,
              ),
              body: _ActiveWorkoutBody(workout: w),
            );
          }

          // ── Detail view (trainer or planned/completed) ──────────────────
          return Scaffold(
            backgroundColor: DT.of(context).bg,
            appBar: AppBar(
              backgroundColor: DT.of(context).bg,
              elevation: 0,
              leading: BackButton(color: DT.of(context).textPrimary),
              title: Text(w.title,
                  style: TextStyle(
                      color: DT.of(context).textPrimary,
                      fontWeight: FontWeight.w600)),
              centerTitle: true,
              actions: [
                if (isTrainer && w.status == WorkoutStatus.planned)
                  IconButton(
                    icon: Icon(Icons.edit_outlined,
                        color: DT.of(context).textPrimary),
                    onPressed: () => context.push('/workout/${w.id}/edit'),
                  ),
                if (isTrainer)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: DT.cardRed),
                    onPressed: () => _confirmDelete(context, w),
                  ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(DT.s5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WorkoutHeader(workout: w),
                  const SizedBox(height: DT.s5),
                  Text('Gyakorlatok',
                      style: TextStyle(
                          color: DT.of(context).textPrimary,
                          fontSize: DT.s4,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: DT.s3),
                  ...w.exercises.map((e) => _ExerciseCard(
                        exercise: e,
                        isAthlete: !isTrainer,
                        workoutStatus: w.status,
                        workoutId: w.id,
                      )),
                  const SizedBox(height: DT.s6),
                  if (!isTrainer) _AthleteActions(workout: w),
                ],
              ),
            ),
          );
        }
        if (state is WorkoutError) {
          return Scaffold(
            appBar: AppBar(leading: const BackButton()),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: DT.cardRed),
                  const SizedBox(height: DT.s4),
                  Text(state.message,
                      style:
                          TextStyle(color: DT.of(context).textSecondary)),
                  const SizedBox(height: DT.s4),
                  ElevatedButton(
                      onPressed: () => context
                          .read<WorkoutBloc>()
                          .add(LoadWorkoutDetail(workoutId)),
                      child: const Text('Újra')),
                ],
              ),
            ),
          );
        }
        return const Scaffold(
            body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  void _confirmDelete(BuildContext context, WorkoutModel w) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edzés törlése'),
        content: Text('Biztosan törlöd a(z) "${w.title}" edzést?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Mégse')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<WorkoutBloc>().add(DeleteWorkout(w.id));
              context.pop();
            },
            child:
                const Text('Törlés', style: TextStyle(color: DT.cardRed)),
          ),
        ],
      ),
    );
  }
}

// ── Active workout ─────────────────────────────────────────────────────────

/// Local per-set state: editable weight/reps + done flag.
class _SetData {
  final TextEditingController weightCtrl;
  final TextEditingController repsCtrl;
  bool isDone;

  _SetData() : weightCtrl = TextEditingController(), repsCtrl = TextEditingController(), isDone = false;

  void dispose() {
    weightCtrl.dispose();
    repsCtrl.dispose();
  }
}

class _ActiveWorkoutBody extends StatefulWidget {
  final WorkoutModel workout;
  const _ActiveWorkoutBody({required this.workout});

  @override
  State<_ActiveWorkoutBody> createState() => _ActiveWorkoutBodyState();
}

class _ActiveWorkoutBodyState extends State<_ActiveWorkoutBody> {
  late final List<List<_SetData>> _setData;
  // Per-exercise RPE (0-10), null = not set. Optional per spec.
  late final List<int?> _rpePerExercise;

  @override
  void initState() {
    super.initState();
    _setData = widget.workout.exercises
        .map((e) => List.generate(e.sets, (_) => _SetData()))
        .toList();
    _rpePerExercise =
        widget.workout.exercises.map((e) => e.rpe).toList(growable: false);
  }

  @override
  void dispose() {
    for (final sets in _setData) {
      for (final s in sets) { s.dispose(); }
    }
    super.dispose();
  }

  int get _totalSets =>
      _setData.fold(0, (sum, sets) => sum + sets.length);

  int get _doneSets =>
      _setData.fold(0, (sum, sets) => sum + sets.where((s) => s.isDone).length);

  void _toggleSet(int exerciseIndex, int setIndex) {
    setState(() {
      _setData[exerciseIndex][setIndex].isDone =
          !_setData[exerciseIndex][setIndex].isDone;
    });

    final set = _setData[exerciseIndex][setIndex];
    final exercise = widget.workout.exercises[exerciseIndex];
    final doneSets = _setData[exerciseIndex].where((s) => s.isDone).length;

    context.read<WorkoutBloc>().add(LogExercise(
          workoutId: widget.workout.id,
          index: exercise.index,
          actualSets: doneSets,
          actualReps: int.tryParse(set.repsCtrl.text.trim()) ??
              exercise.targetReps,
          actualWeightKg: double.tryParse(set.weightCtrl.text.trim()) ??
              exercise.targetWeightKg,
          rpe: _rpePerExercise[exerciseIndex],
        ));
  }

  void _onRpeChanged(int exerciseIndex, int? rpe) {
    setState(() => _rpePerExercise[exerciseIndex] = rpe);
    final exercise = widget.workout.exercises[exerciseIndex];
    final doneSets =
        _setData[exerciseIndex].where((s) => s.isDone).length;
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
    final progress = total == 0 ? 0.0 : done / total;

    return Column(
      children: [
        _ProgressBar(done: done, total: total, progress: progress),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(DT.s5, DT.s4, DT.s5, DT.s5),
            itemCount: widget.workout.exercises.length + 1,
            itemBuilder: (context, i) {
              if (i == widget.workout.exercises.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: DT.s2),
                  child: _AthleteActions(workout: widget.workout),
                );
              }
              final exercise = widget.workout.exercises[i];
              return _ActiveExerciseCard(
                exercise: exercise,
                sets: _setData[i],
                onToggleSet: (setIndex) => _toggleSet(i, setIndex),
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
  final double progress;

  const _ProgressBar(
      {required this.done, required this.total, required this.progress});

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    final color = progress >= 1.0 ? Colors.green : DT.metricBlue;

    return Container(
      padding: const EdgeInsets.fromLTRB(DT.s5, DT.s3, DT.s5, DT.s4),
      color: DT.gbWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$done / $total sorozat teljesítve',
                style: TextStyle(
                    color: DT.of(context).textSecondary, fontSize: DT.s3),
              ),
              Text(
                '$pct%',
                style: TextStyle(
                    color: color,
                    fontSize: DT.s3,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: DT.s2),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: DT.of(context).bg,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveExerciseCard extends StatelessWidget {
  final WorkoutExercise exercise;
  final List<_SetData> sets;
  final ValueChanged<int> onToggleSet;
  final int? rpe;
  final ValueChanged<int?> onRpeChanged;

  const _ActiveExerciseCard({
    required this.exercise,
    required this.sets,
    required this.onToggleSet,
    required this.rpe,
    required this.onRpeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final doneSets = sets.where((s) => s.isDone).length;
    final allDone = sets.isNotEmpty && doneSets == sets.length;

    final hintWeight = exercise.targetWeightKg > 0
        ? (exercise.targetWeightKg % 1 == 0
            ? exercise.targetWeightKg.toInt().toString()
            : exercise.targetWeightKg.toString())
        : '';
    final hintReps = exercise.targetReps.toString();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: DT.s4),
      decoration: BoxDecoration(
        color: DT.gbWhite,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        border: allDone
            ? Border.all(
                color: Colors.green.withValues(alpha: 0.5), width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise header
          Padding(
            padding: const EdgeInsets.all(DT.s4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exercise.name,
                          style: TextStyle(
                              color: DT.of(context).textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: DT.s4)),
                      if (exercise.equipmentType != null &&
                          exercise.equipmentType!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(exercise.equipmentType!,
                            style: TextStyle(
                                color: DT.of(context).textSecondary,
                                fontSize: DT.s3)),
                      ],
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                      horizontal: DT.s3, vertical: DT.s1),
                  decoration: BoxDecoration(
                    color: (allDone ? Colors.green : DT.metricBlue)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(DT.rChip),
                  ),
                  child: Text(
                    '$doneSets / ${sets.length}',
                    style: TextStyle(
                        color: allDone ? Colors.green : DT.metricBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: DT.s3),
                  ),
                ),
              ],
            ),
          ),
          if (exercise.instructions != null &&
              exercise.instructions!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(DT.s4, 0, DT.s4, DT.s3),
              child: Text(exercise.instructions!,
                  style: TextStyle(
                      color: DT.of(context).textSecondary,
                      fontSize: DT.s3,
                      fontStyle: FontStyle.italic)),
            ),
          // Column headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DT.s4),
            child: Row(
              children: [
                const SizedBox(width: 28 + DT.s2), // set number column
                Expanded(
                    child: Text('Súly (kg)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: DT.of(context).textSecondary,
                            fontSize: DT.s3,
                            fontWeight: FontWeight.w600))),
                const SizedBox(width: DT.s2),
                Expanded(
                    child: Text('Ism.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: DT.of(context).textSecondary,
                            fontSize: DT.s3,
                            fontWeight: FontWeight.w600))),
                const SizedBox(width: DT.s2 + 36), // checkbox column
              ],
            ),
          ),
          const SizedBox(height: DT.s2),
          // Set rows
          ...sets.asMap().entries.map((entry) => _SetRow(
                setNumber: entry.key + 1,
                data: entry.value,
                hintWeight: hintWeight,
                hintReps: hintReps,
                onToggle: () => onToggleSet(entry.key),
              )),
          // RPE slider (optional)
          _RpeSlider(value: rpe, onChanged: onRpeChanged),
          const SizedBox(height: DT.s3),
        ],
      ),
    );
  }
}

/// Optional 0-10 Rate of Perceived Exertion control. Renders below the set rows
/// of an active exercise card. Submitting without setting RPE works (backend
/// accepts null). The label is the exact wording requested in the spec.
class _RpeSlider extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  const _RpeSlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final v = value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(DT.s4, DT.s2, DT.s4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'RPE (optional)',
                style: TextStyle(
                  color: DT.of(context).textSecondary,
                  fontSize: DT.s3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (v != null)
                GestureDetector(
                  onTap: () => onChanged(null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DT.s2, vertical: 2),
                    decoration: BoxDecoration(
                      color: DT.metricBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(DT.rChip),
                    ),
                    child: Text(
                      'RPE $v',
                      style: const TextStyle(
                        color: DT.metricBlue,
                        fontSize: DT.s3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else
                Text(
                  '—',
                  style: TextStyle(
                    color: DT.of(context).textSecondary,
                    fontSize: DT.s3,
                  ),
                ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              activeTrackColor: DT.metricBlue,
              inactiveTrackColor: DT.metricBlue.withValues(alpha: 0.15),
              thumbColor: DT.metricBlue,
              overlayColor: DT.metricBlue.withValues(alpha: 0.1),
            ),
            child: Slider(
              min: 0,
              max: 10,
              divisions: 10,
              value: (v ?? 0).toDouble(),
              label: '${v ?? 0}',
              onChanged: (raw) => onChanged(raw.round()),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final int setNumber;
  final _SetData data;
  final String hintWeight;
  final String hintReps;
  final VoidCallback onToggle;

  const _SetRow({
    required this.setNumber,
    required this.data,
    required this.hintWeight,
    required this.hintReps,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.fromLTRB(DT.s4, 0, DT.s4, DT.s2),
      padding:
          const EdgeInsets.symmetric(horizontal: DT.s3, vertical: DT.s2),
      decoration: BoxDecoration(
        color: data.isDone
            ? Colors.green.withValues(alpha: 0.07)
            : DT.of(context).bg,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
      ),
      child: Row(
        children: [
          // Set number
          SizedBox(
            width: 28,
            child: Text(
              '$setNumber',
              style: TextStyle(
                  color: data.isDone
                      ? Colors.green
                      : DT.of(context).textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: DT.s4),
            ),
          ),
          const SizedBox(width: DT.s2),
          // Weight field or done value
          Expanded(
            child: data.isDone
                ? _DoneValue(
                    value: data.weightCtrl.text.isEmpty
                        ? hintWeight
                        : data.weightCtrl.text)
                : _SetTextField(
                    controller: data.weightCtrl,
                    hint: hintWeight,
                    isDecimal: true),
          ),
          const SizedBox(width: DT.s2),
          // Reps field or done value
          Expanded(
            child: data.isDone
                ? _DoneValue(
                    value: data.repsCtrl.text.isEmpty
                        ? hintReps
                        : data.repsCtrl.text)
                : _SetTextField(
                    controller: data.repsCtrl,
                    hint: hintReps,
                    isDecimal: false),
          ),
          const SizedBox(width: DT.s2),
          // Done checkbox
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: data.isDone ? Colors.green : Colors.transparent,
                border: Border.all(
                  color: data.isDone ? Colors.green : DT.iconLightGrey,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(DT.rCardSmall),
              ),
              child: data.isDone
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneValue extends StatelessWidget {
  final String value;
  const _DoneValue({required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: Center(
        child: Text(
          value.isEmpty ? '—' : value,
          style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w600,
              fontSize: DT.s4),
        ),
      ),
    );
  }
}

class _SetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isDecimal;

  const _SetTextField(
      {required this.controller,
      required this.hint,
      required this.isDecimal});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
        textAlign: TextAlign.center,
        style: TextStyle(
            color: DT.of(context).textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: DT.s4),
        decoration: InputDecoration(
          hintText: hint.isEmpty ? '—' : hint,
          hintStyle: TextStyle(
              color: DT.of(context).textSecondary.withValues(alpha: 0.5),
              fontWeight: FontWeight.w400,
              fontSize: DT.s4),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: DT.s2),
          filled: true,
          fillColor: DT.gbWhite,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DT.rCardSmall),
            borderSide: const BorderSide(color: DT.iconLightGrey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DT.rCardSmall),
            borderSide: const BorderSide(color: DT.iconLightGrey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DT.rCardSmall),
            borderSide: const BorderSide(color: DT.metricBlue, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ── Workout header (detail / trainer view) ─────────────────────────────────

class _WorkoutHeader extends StatelessWidget {
  final WorkoutModel workout;
  const _WorkoutHeader({required this.workout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DT.s5),
      decoration: BoxDecoration(
        color: DT.gbWhite,
        borderRadius: BorderRadius.circular(DT.rCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _Chip(
                label: workout.status.label,
                color: _statusColor(workout.status)),
            const SizedBox(width: DT.s2),
            _Chip(
                label: workout.difficulty.label,
                color: _diffColor(workout.difficulty)),
          ]),
          const SizedBox(height: DT.s3),
          Row(children: [
            Icon(Icons.calendar_today_outlined,
                size: 16, color: DT.of(context).iconLight),
            const SizedBox(width: DT.s2),
            Text(
              DateFormat('yyyy. MMMM d., EEEE', 'hu')
                  .format(workout.scheduledDate),
              style: TextStyle(
                  color: DT.of(context).textSecondary, fontSize: DT.s3),
            ),
          ]),
          if (workout.athleteName != null) ...[
            const SizedBox(height: DT.s2),
            Row(children: [
              Icon(Icons.person_outline,
                  size: 16, color: DT.of(context).iconLight),
              const SizedBox(width: DT.s2),
              Text('Sportoló: ${workout.athleteName}',
                  style: TextStyle(
                      color: DT.of(context).textSecondary, fontSize: DT.s3)),
            ]),
          ],
          if (workout.notes != null && workout.notes!.isNotEmpty) ...[
            const SizedBox(height: DT.s3),
            Text(workout.notes!,
                style: TextStyle(
                    color: DT.of(context).textSecondary, fontSize: DT.s3)),
          ],
          if (workout.athleteFeedback != null &&
              workout.athleteFeedback!.isNotEmpty) ...[
            const SizedBox(height: DT.s3),
            Container(
              padding: const EdgeInsets.all(DT.s3),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(DT.rCardSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sportoló visszajelzése:',
                      style: TextStyle(
                          color: DT.of(context).textSecondary,
                          fontSize: DT.s3,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: DT.s1),
                  Text(workout.athleteFeedback!,
                      style: TextStyle(
                          color: DT.of(context).textPrimary,
                          fontSize: DT.s3)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(WorkoutStatus s) {
    switch (s) {
      case WorkoutStatus.planned:
        return DT.metricBlue;
      case WorkoutStatus.inProgress:
        return DT.cardOrange;
      case WorkoutStatus.completed:
        return Colors.green;
    }
  }

  Color _diffColor(WorkoutDifficulty d) {
    switch (d) {
      case WorkoutDifficulty.easy:
        return DT.difficultyLight;
      case WorkoutDifficulty.moderate:
        return DT.difficultyMedium;
      case WorkoutDifficulty.hard:
        return DT.difficultyHard;
      case WorkoutDifficulty.intense:
        return Colors.purple;
    }
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: DT.s3, vertical: DT.s1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DT.rChip),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: DT.s3, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Exercise card (read-only / log view for planned/completed) ─────────────

class _ExerciseCard extends StatefulWidget {
  final WorkoutExercise exercise;
  final bool isAthlete;
  final WorkoutStatus workoutStatus;
  final String workoutId;

  const _ExerciseCard({
    required this.exercise,
    required this.isAthlete,
    required this.workoutStatus,
    required this.workoutId,
  });

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  bool _expanded = false;
  late final TextEditingController _setsCtrl;
  late final TextEditingController _repsCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _notesCtrl;
  int? _rpe;

  @override
  void initState() {
    super.initState();
    final e = widget.exercise;
    _setsCtrl =
        TextEditingController(text: e.actualSets?.toString() ?? '');
    _repsCtrl =
        TextEditingController(text: e.actualReps?.toString() ?? '');
    _weightCtrl =
        TextEditingController(text: e.actualWeightKg?.toString() ?? '');
    _notesCtrl =
        TextEditingController(text: e.exerciseNotes ?? '');
    _rpe = e.rpe;
  }

  @override
  void dispose() {
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _log() {
    context.read<WorkoutBloc>().add(LogExercise(
          workoutId: widget.workoutId,
          index: widget.exercise.index,
          actualSets: int.tryParse(_setsCtrl.text),
          actualReps: int.tryParse(_repsCtrl.text),
          actualWeightKg: double.tryParse(_weightCtrl.text),
          rpe: _rpe,
          exerciseNotes: _notesCtrl.text.trim().isEmpty
              ? null
              : _notesCtrl.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.exercise;
    final canLog = widget.isAthlete &&
        widget.workoutStatus == WorkoutStatus.inProgress;

    return Container(
      margin: const EdgeInsets.only(bottom: DT.s3),
      decoration: BoxDecoration(
        color: DT.gbWhite,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _expanded = !_expanded),
            title: Text(e.name,
                style: TextStyle(
                    color: DT.of(context).textPrimary,
                    fontWeight: FontWeight.w600)),
            subtitle: Text(
                '${e.sets} sorozat × ${e.targetReps} ism. @ ${e.targetWeightKg} kg',
                style: TextStyle(
                    color: DT.of(context).textSecondary,
                    fontSize: DT.s3)),
            trailing: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                color: DT.of(context).iconLight),
          ),
          if (_expanded) ...[
            if (e.instructions != null && e.instructions!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(DT.s4, 0, DT.s4, DT.s3),
                child: Text(e.instructions!,
                    style: TextStyle(
                        color: DT.of(context).textSecondary,
                        fontSize: DT.s3)),
              ),
            if (canLog) ...[
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(DT.s4, 0, DT.s4, DT.s4),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: _LogField(
                                ctrl: _setsCtrl, label: 'Sorozat')),
                        const SizedBox(width: DT.s2),
                        Expanded(
                            child: _LogField(
                                ctrl: _repsCtrl, label: 'Ismétlés')),
                        const SizedBox(width: DT.s2),
                        Expanded(
                            child: _LogField(
                                ctrl: _weightCtrl,
                                label: 'Súly (kg)',
                                isDecimal: true)),
                      ],
                    ),
                    const SizedBox(height: DT.s2),
                    _RpeSlider(
                      value: _rpe,
                      onChanged: (v) => setState(() => _rpe = v),
                    ),
                    const SizedBox(height: DT.s2),
                    TextField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Megjegyzés', isDense: true),
                    ),
                    const SizedBox(height: DT.s3),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _log,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: DT.metricBlue),
                        child: const Text('Mentés',
                            style: TextStyle(color: DT.textWhite)),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (e.actualSets != null) ...[
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(DT.s4, 0, DT.s4, DT.s4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 16),
                    const SizedBox(width: DT.s2),
                    Expanded(
                      child: Text(
                        '${e.actualSets} × ${e.actualReps} ism. @ ${e.actualWeightKg} kg',
                        style: const TextStyle(
                            color: Colors.green, fontSize: DT.s3),
                      ),
                    ),
                    if (e.rpe != null) _RpeBadge(rpe: e.rpe!),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Small "RPE 8" chip shown in the workout-review UI when an exercise has been
/// logged with an RPE value.
class _RpeBadge extends StatelessWidget {
  final int rpe;
  const _RpeBadge({required this.rpe});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: DT.s2, vertical: 2),
      decoration: BoxDecoration(
        color: DT.metricBlue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DT.rChip),
      ),
      child: Text(
        'RPE $rpe',
        style: const TextStyle(
          color: DT.metricBlue,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LogField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool isDecimal;
  const _LogField(
      {required this.ctrl, required this.label, this.isDecimal = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
      decoration: InputDecoration(labelText: label, isDense: true),
    );
  }
}

// ── Athlete actions (start / complete) ────────────────────────────────────

class _AthleteActions extends StatefulWidget {
  final WorkoutModel workout;
  const _AthleteActions({required this.workout});

  @override
  State<_AthleteActions> createState() => _AthleteActionsState();
}

class _AthleteActionsState extends State<_AthleteActions> {
  final _feedbackCtrl = TextEditingController();

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.workout.status == WorkoutStatus.planned) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: () => context
              .read<WorkoutBloc>()
              .add(StartWorkout(widget.workout.id)),
          icon: const Icon(Icons.play_arrow, color: Colors.white),
          label: const Text('Edzés megkezdése',
              style: TextStyle(
                  color: DT.textWhite, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
              backgroundColor: DT.metricBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DT.rCardSmall))),
        ),
      );
    }

    if (widget.workout.status == WorkoutStatus.inProgress) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _feedbackCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Visszajelzés az edzőnek (opcionális)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: DT.s4),
          ElevatedButton.icon(
            onPressed: () => context.read<WorkoutBloc>().add(
                  CompleteWorkout(widget.workout.id,
                      feedback: _feedbackCtrl.text.trim()),
                ),
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text('Edzés befejezése',
                style: TextStyle(
                    color: DT.textWhite, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DT.rCardSmall))),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
