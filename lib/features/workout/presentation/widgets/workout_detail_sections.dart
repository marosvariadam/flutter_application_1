import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/design/dt_text.dart';
import 'package:flutter_application_1/app/shared/widgets/status_chip.dart';
import 'package:flutter_application_1/features/workout/bloc/workout_bloc.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';
import 'package:flutter_application_1/features/workout/presentation/widgets/rpe_slider.dart';
import 'package:flutter_application_1/features/workout/presentation/widgets/workout_colors.dart';

// Workout header (detail / trainer view)

class WorkoutHeader extends StatelessWidget {
  final WorkoutModel workout;
  const WorkoutHeader({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DT.s5),
      decoration: BoxDecoration(
        color: DT.of(context).cardSurface,
        borderRadius: BorderRadius.circular(DT.rCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: DT.s2, runSpacing: DT.s1, children: [
            StatusChip.custom(workout.status.label,
                color: workout.status.color(DT.of(context))),
            DifficultyChip(workout.difficulty),
          ]),
          const SizedBox(height: DT.s3),
          Row(children: [
            Icon(Icons.calendar_today_outlined,
                size: 16, color: DT.of(context).iconLight),
            const SizedBox(width: DT.s2),
            Expanded(
              child: Text(
              DateFormat('yyyy. MMMM d., EEEE', 'hu')
                  .format(workout.scheduledDate),
              style: TextStyle(
                  color: DT.of(context).textSecondary, fontSize: DT.s3),
            ),
            ),
          ]),
          if (workout.athleteName != null) ...[
            const SizedBox(height: DT.s2),
            Row(children: [
              Icon(Icons.person_outline,
                  size: 16, color: DT.of(context).iconLight),
              const SizedBox(width: DT.s2),
              Expanded(
                child: Text('Sportoló: ${workout.athleteName}',
                    style: TextStyle(
                        color: DT.of(context).textSecondary, fontSize: DT.s3)),
              ),
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
                color: DT.of(context).accentSuccess.withValues(alpha: 0.08),
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
}

// Exercise card (read-only / log view for planned/completed)

class WorkoutExerciseCard extends StatefulWidget {
  final WorkoutExercise exercise;
  final bool isAthlete;
  final WorkoutStatus workoutStatus;
  final String workoutId;

  const WorkoutExerciseCard({
    super.key,
    required this.exercise,
    required this.isAthlete,
    required this.workoutStatus,
    required this.workoutId,
  });

  @override
  State<WorkoutExerciseCard> createState() => _WorkoutExerciseCardState();
}

class _WorkoutExerciseCardState extends State<WorkoutExerciseCard> {
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
          actualWeightKg:
              double.tryParse(_weightCtrl.text.trim().replaceAll(',', '.')),
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
        color: DT.of(context).cardSurface,
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
                    RpeSlider(
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
                            backgroundColor: DT.of(context).accentPrimary),
                        child: Text('Mentés',
                            style: TextStyle(color: DT.of(context).textOnAccent)),
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
                    Icon(Icons.check_circle,
                        color: DT.of(context).accentSuccess, size: 16),
                    const SizedBox(width: DT.s2),
                    Expanded(
                      child: Text(
                        '${e.actualSets} × ${e.actualReps} ism. @ ${e.actualWeightKg} kg',
                        style: TextStyle(
                            color: DT.of(context).accentSuccess, fontSize: DT.s3),
                      ),
                    ),
                    if (e.rpe != null) RpeBadge(rpe: e.rpe!),
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
class RpeBadge extends StatelessWidget {
  final int rpe;
  const RpeBadge({super.key, required this.rpe});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: DT.s2, vertical: 2),
      decoration: BoxDecoration(
        color: DT.of(context).accentPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DT.rChip),
      ),
      child: Text(
        'RPE $rpe',
        style: DTText.of(context).caption.copyWith(
              color: DT.of(context).accentPrimary,
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

// Athlete actions (start / complete)

class AthleteActions extends StatefulWidget {
  final WorkoutModel workout;
  const AthleteActions({super.key, required this.workout});

  @override
  State<AthleteActions> createState() => _AthleteActionsState();
}

class _AthleteActionsState extends State<AthleteActions> {
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
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.read<WorkoutBloc>().add(StartWorkout(widget.workout.id));
          },
          icon: Icon(Icons.play_arrow, color: DT.of(context).textOnAccent),
          label: Text('Edzés megkezdése',
              style: TextStyle(
                  color: DT.of(context).textOnAccent, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
              backgroundColor: DT.of(context).accentPrimary,
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
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.read<WorkoutBloc>().add(
                    CompleteWorkout(widget.workout.id,
                        feedback: _feedbackCtrl.text.trim()),
                  );
            },
            icon: Icon(Icons.check, color: DT.of(context).textOnAccent),
            label: Text('Edzés befejezése',
                style: TextStyle(
                    color: DT.of(context).textOnAccent, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
                backgroundColor: DT.of(context).accentSuccess,
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
