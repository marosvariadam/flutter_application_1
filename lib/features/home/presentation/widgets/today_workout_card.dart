import 'package:flutter/material.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/design/dt_colors.dart';
import 'package:flutter_application_1/app/design/dt_text.dart';
import 'package:flutter_application_1/app/shared/widgets/dt_card.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';

/// The selected day's workout: tinted in the workout's color with a left
/// accent bar, difficulty badge, title, description and meta row.
class TodayWorkoutCard extends StatelessWidget {
  final WorkoutModel workout;
  final VoidCallback onTap;

  const TodayWorkoutCard({
    super.key,
    required this.workout,
    required this.onTap,
  });

  static Color difficultyColor(DTColors c, WorkoutDifficulty d) => switch (d) {
        WorkoutDifficulty.easy => c.difficultyEasy,
        WorkoutDifficulty.moderate => c.difficultyMedium,
        WorkoutDifficulty.hard => c.difficultyHard,
        WorkoutDifficulty.intense => c.difficultyIntense,
      };

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    final t = DTText.of(context);
    final radius = BorderRadius.circular(DT.rCardSmall);
    return Material(
      color: workout.color.withValues(alpha: 0.25),
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.all(DT.s5),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border(left: BorderSide(color: workout.color, width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DT.s2, vertical: DT.s1),
                    decoration: BoxDecoration(
                      color: difficultyColor(c, workout.difficulty),
                      borderRadius: BorderRadius.circular(DT.rXs),
                    ),
                    child: Text(
                      workout.difficulty.label,
                      style: t.caption.copyWith(
                          color: c.textOnAccent, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios,
                      size: 14, color: c.textSecondary),
                ],
              ),
              const SizedBox(height: DT.s3),
              Text(workout.title, style: t.h2),
              if (workout.description != null) ...[
                const SizedBox(height: DT.s1),
                Text(
                  workout.description!,
                  style: t.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
