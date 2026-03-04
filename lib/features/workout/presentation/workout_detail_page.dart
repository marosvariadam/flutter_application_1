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
          return Scaffold(
            backgroundColor: DT.bg,
            appBar: AppBar(
              backgroundColor: DT.bg,
              elevation: 0,
              leading: BackButton(color: DT.textPrimary),
              title: Text(w.title,
                  style: const TextStyle(
                      color: DT.textPrimary, fontWeight: FontWeight.w600)),
              centerTitle: true,
              actions: [
                if (isTrainer &&
                    w.status == WorkoutStatus.planned)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: DT.textPrimary),
                    onPressed: () =>
                        context.push('/workout/${w.id}/edit'),
                  ),
                if (isTrainer)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: DT.cardRed),
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
                  const Text('Gyakorlatok',
                      style: TextStyle(
                          color: DT.textPrimary,
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
                  const Icon(Icons.error_outline,
                      size: 48, color: DT.cardRed),
                  const SizedBox(height: DT.s4),
                  Text(state.message,
                      style: const TextStyle(
                          color: DT.textSecondary)),
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
        content:
            Text('Biztosan törlöd a(z) "${w.title}" edzést?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Mégse')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<WorkoutBloc>()
                  .add(DeleteWorkout(w.id));
              context.pop();
            },
            child: const Text('Törlés',
                style: TextStyle(color: DT.cardRed)),
          ),
        ],
      ),
    );
  }
}

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
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: DT.iconLight),
            const SizedBox(width: DT.s2),
            Text(
              DateFormat('yyyy. MMMM d., EEEE', 'hu')
                  .format(workout.scheduledDate),
              style: const TextStyle(
                  color: DT.textSecondary, fontSize: DT.s3),
            ),
          ]),
          if (workout.athleteName != null) ...[
            const SizedBox(height: DT.s2),
            Row(children: [
              const Icon(Icons.person_outline,
                  size: 16, color: DT.iconLight),
              const SizedBox(width: DT.s2),
              Text('Sportoló: ${workout.athleteName}',
                  style: const TextStyle(
                      color: DT.textSecondary, fontSize: DT.s3)),
            ]),
          ],
          if (workout.notes != null && workout.notes!.isNotEmpty) ...[
            const SizedBox(height: DT.s3),
            Text(workout.notes!,
                style: const TextStyle(
                    color: DT.textSecondary, fontSize: DT.s3)),
          ],
          if (workout.athleteFeedback != null &&
              workout.athleteFeedback!.isNotEmpty) ...[
            const SizedBox(height: DT.s3),
            Container(
              padding: const EdgeInsets.all(DT.s3),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(DT.rCardSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sportoló visszajelzése:',
                      style: TextStyle(
                          color: DT.textSecondary,
                          fontSize: DT.s3,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: DT.s1),
                  Text(workout.athleteFeedback!,
                      style: const TextStyle(
                          color: DT.textPrimary, fontSize: DT.s3)),
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
      padding: const EdgeInsets.symmetric(
          horizontal: DT.s3, vertical: DT.s1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(DT.rChip),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: DT.s3,
              fontWeight: FontWeight.w600)),
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    final e = widget.exercise;
    _setsCtrl = TextEditingController(
        text: e.actualSets?.toString() ?? '');
    _repsCtrl = TextEditingController(
        text: e.actualReps?.toString() ?? '');
    _weightCtrl = TextEditingController(
        text: e.actualWeightKg?.toString() ?? '');
    _notesCtrl =
        TextEditingController(text: e.exerciseNotes ?? '');
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
          exerciseNotes:
              _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
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
                style: const TextStyle(
                    color: DT.textPrimary, fontWeight: FontWeight.w600)),
            subtitle: Text(
                '${e.sets} sorozat × ${e.targetReps} ism. @ ${e.targetWeightKg} kg',
                style: const TextStyle(
                    color: DT.textSecondary, fontSize: DT.s3)),
            trailing: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                color: DT.iconLight),
          ),
          if (_expanded) ...[
            if (e.instructions != null && e.instructions!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    DT.s4, 0, DT.s4, DT.s3),
                child: Text(e.instructions!,
                    style: const TextStyle(
                        color: DT.textSecondary, fontSize: DT.s3)),
              ),
            if (canLog) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    DT.s4, 0, DT.s4, DT.s4),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: _LogField(
                                ctrl: _setsCtrl,
                                label: 'Sorozat')),
                        const SizedBox(width: DT.s2),
                        Expanded(
                            child: _LogField(
                                ctrl: _repsCtrl,
                                label: 'Ismétlés')),
                        const SizedBox(width: DT.s2),
                        Expanded(
                            child: _LogField(
                                ctrl: _weightCtrl,
                                label: 'Súly (kg)',
                                isDecimal: true)),
                      ],
                    ),
                    const SizedBox(height: DT.s2),
                    TextField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Megjegyzés',
                          isDense: true),
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
                padding: const EdgeInsets.fromLTRB(
                    DT.s4, 0, DT.s4, DT.s4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 16),
                    const SizedBox(width: DT.s2),
                    Text(
                      '${e.actualSets} × ${e.actualReps} ism. @ ${e.actualWeightKg} kg',
                      style: const TextStyle(
                          color: Colors.green, fontSize: DT.s3),
                    ),
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
      decoration:
          InputDecoration(labelText: label, isDense: true),
    );
  }
}

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
                    color: DT.textWhite,
                    fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(DT.rCardSmall))),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
