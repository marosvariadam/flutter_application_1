import 'package:flutter/material.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/design/dt_text.dart';
import 'package:flutter_application_1/app/shared/widgets/dt_card.dart';
import 'package:flutter_application_1/app/shared/widgets/progress_ring.dart';
import 'package:flutter_application_1/app/shared/widgets/status_chip.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';
import 'package:flutter_application_1/features/workout/presentation/widgets/workout_colors.dart';

/// The selected day's workout: tinted in the workout's color with a left
/// accent bar, difficulty chip, title, description, a progress ring
/// (completed exercises / total) and a meta row. A completed workout turns
/// the bar and ring green.
class TodayWorkoutCard extends StatelessWidget {
  final WorkoutModel workout;
  final VoidCallback onTap;

  const TodayWorkoutCard({
    super.key,
    required this.workout,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    final t = DTText.of(context);
    final radius = BorderRadius.circular(DT.rCardSmall);
    final isCompleted = workout.status == WorkoutStatus.completed;
    final total = workout.exercises.length;
    final done = isCompleted ? total : workout.completedExercises;
    final accent = isCompleted ? c.accentSuccess : workout.color;
    return Material(
      color: accent.withValues(alpha: isCompleted ? 0.12 : 0.25),
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.all(DT.s5),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border(left: BorderSide(color: accent, width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: DT.s2,
                      runSpacing: DT.s1,
                      children: [
                        DifficultyChip(workout.difficulty),
                        if (isCompleted)
                          const StatusChip('Teljesítve',
                              tone: StatusTone.success, icon: Icons.check),
                      ],
                    ),
                  ),
                  const SizedBox(width: DT.s2),
                  Icon(Icons.arrow_forward_ios,
                      size: 14, color: c.textSecondary),
                ],
              ),
              const SizedBox(height: DT.s3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(workout.title,
                            style: t.h2,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        if (workout.description != null) ...[
                          const SizedBox(height: DT.s1),
                          Text(
                            workout.description!,
                            style: t.caption,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (total > 0) ...[
                    const SizedBox(width: DT.s3),
                    ProgressRing(done: done, total: total, unit: 'gyakorlat'),
                  ],
                ],
              ),
              const SizedBox(height: DT.s4),
              Wrap(
                spacing: DT.s4,
                runSpacing: DT.s1,
                children: [
                  _InfoChip(
                      icon: Icons.fitness_center_outlined,
                      label: '${workout.exercises.length} gyakorlat'),
                  _InfoChip(
                      icon: Icons.repeat,
                      label: '${workout.totalSets} sorozat'),
                  _InfoChip(
                      icon: Icons.access_time,
                      label: workout.estimatedDuration),
                  _InfoChip(
                      icon: Icons.local_fire_department, label: workout.kcal),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: DT.of(context).iconLight),
        const SizedBox(width: DT.s1),
        Text(label, style: DTText.of(context).caption),
      ],
    );
  }
}

/// Shown in place of [TodayWorkoutCard] on days without a workout.
class RestDayCard extends StatelessWidget {
  const RestDayCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = DTText.of(context);
    return DTCard(
      radius: DT.rCardSmall,
      padding: const EdgeInsets.all(DT.s5),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Icon(Icons.self_improvement,
                size: 48, color: DT.of(context).iconLightGrey),
            const SizedBox(height: DT.s3),
            Text('Pihenőnap', style: t.title),
            const SizedBox(height: DT.s1),
            Text(
              'Erre a napra nincs ütemezett edzés.',
              style: t.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
