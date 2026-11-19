import 'package:flutter/material.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/design/dt_colors.dart';
import 'package:flutter_application_1/app/shared/widgets/status_chip.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';

/// Theme color of a difficulty level: easy green, moderate amber, hard
/// orange, intense red.
extension WorkoutDifficultyColor on WorkoutDifficulty {
  Color color(DTColors c) => switch (this) {
        WorkoutDifficulty.easy => c.difficultyEasy,
        WorkoutDifficulty.moderate => c.difficultyMedium,
        WorkoutDifficulty.hard => c.difficultyHard,
        WorkoutDifficulty.intense => c.difficultyIntense,
      };
}

/// Theme color of a workout status: planned blue, in progress orange,
/// completed green.
extension WorkoutStatusColor on WorkoutStatus {
  Color color(DTColors c) => switch (this) {
        WorkoutStatus.planned => c.accentPrimary,
        WorkoutStatus.inProgress => c.accentOrange,
        WorkoutStatus.completed => c.accentSuccess,
      };
}

/// Difficulty label as a soft [StatusChip] in the level's color.
class DifficultyChip extends StatelessWidget {
  final WorkoutDifficulty difficulty;

  const DifficultyChip(this.difficulty, {super.key});

  @override
  Widget build(BuildContext context) => StatusChip.custom(
        difficulty.label,
        color: difficulty.color(DT.of(context)),
      );
}
