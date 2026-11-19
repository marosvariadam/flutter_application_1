import 'package:flutter/material.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/training_plan/data/models/training_plan_model.dart';

/// Read-only list of a plan's training days for the athlete: every
/// exercise with its prescription, rest and the trainer's notes.
class PlanReadOnlyDays extends StatelessWidget {
  final TrainingPlanModel plan;
  const PlanReadOnlyDays({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    if (plan.days.isEmpty) {
      return Text('A terv még nem tartalmaz edzésnapokat.',
          style: TextStyle(color: c.textSecondary, fontSize: 14));
    }
    final days = List<PlanDayModel>.from(plan.days)
      ..sort((a, b) => a.dayIndex.compareTo(b.dayIndex));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final d in days) _DayCard(day: d)],
    );
  }
}

/// "90 mp", "2 perc", "2 p 30 mp".
String formatRest(int seconds) {
  if (seconds < 60) return '$seconds mp';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return s == 0 ? '$m perc' : '$m p $s mp';
}

class _DayCard extends StatelessWidget {
  final PlanDayModel day;
  const _DayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    final exercises = List<PlannedExerciseModel>.from(day.exercises)
      ..sort((a, b) => a.order.compareTo(b.order));
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: DT.s3),
      padding: const EdgeInsets.all(DT.s4),
      decoration: BoxDecoration(
        color: c.cardSurface,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        boxShadow: [
          BoxShadow(
              color: c.shadowLight, blurRadius: 6, offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${day.dayIndex + 1}. NAP',
            style: TextStyle(
              color: c.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          if (day.label.isNotEmpty)
            Text(
              day.label,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(height: DT.s2),
          if (exercises.isEmpty)
            Text('Pihenőnap.',
                style: TextStyle(color: c.textSecondary, fontSize: 14))
          else
            for (var i = 0; i < exercises.length; i++) ...[
              if (i > 0) Divider(height: DT.s4, color: c.borderLight),
              _ExerciseLine(exercise: exercises[i]),
            ],
        ],
      ),
    );
  }
}

class _ExerciseLine extends StatelessWidget {
  final PlannedExerciseModel exercise;
  const _ExerciseLine({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    final notes = exercise.notes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exercise.name,
                      style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  if (exercise.muscleGroup.isNotEmpty)
                    Text(exercise.muscleGroup,
                        style: TextStyle(
                            color: c.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: DT.s3),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(exercise.prescription,
                    style: TextStyle(
                        color: c.accentPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                if (exercise.restSeconds > 0)
                  Text('Pihenő: ${formatRest(exercise.restSeconds)}',
                      style:
                          TextStyle(color: c.textSecondary, fontSize: 12)),
              ],
            ),
          ],
        ),
        if (notes != null && notes.isNotEmpty) ...[
          const SizedBox(height: DT.s1),
          Text(notes,
              style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic)),
        ],
      ],
    );
  }
}
