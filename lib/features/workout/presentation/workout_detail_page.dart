import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/workout/data/models/exercise_model.dart';
import 'package:flutter_application_1/features/workout/data/models/exercise_set_model.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';
import 'package:intl/intl.dart';

class WorkoutDetailPage extends StatelessWidget {
  final WorkoutModel workout;

  const WorkoutDetailPage({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.bg,
      appBar: AppBar(
        backgroundColor: DT.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DT.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          workout.title,
          style: const TextStyle(
            color: DT.textPrimary,
            fontSize: DT.s4,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: DT.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(DT.s5, 0, DT.s5, DT.s8),
        children: [
          _WorkoutHeader(workout: workout),
          const SizedBox(height: DT.s5),
          ...workout.exercises.map(
            (exercise) => Padding(
              padding: const EdgeInsets.only(bottom: DT.s4),
              child: _ExerciseCard(exercise: exercise),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Workout Header ──────────────────────────────────────────────────────────

class _WorkoutHeader extends StatelessWidget {
  final WorkoutModel workout;
  const _WorkoutHeader({required this.workout});

  @override
  Widget build(BuildContext context) {
    final diffColor = _difficultyColor(workout.difficulty);

    return Container(
      padding: const EdgeInsets.all(DT.s5),
      decoration: BoxDecoration(
        color: workout.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        border: Border(left: BorderSide(color: workout.color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Chip(label: workout.difficulty, color: diffColor),
              const SizedBox(width: DT.s2),
              Text(
                DateFormat('yyyy.MM.dd').format(workout.scheduledDate),
                style: const TextStyle(color: DT.textSecondary, fontSize: DT.s3),
              ),
            ],
          ),
          if (workout.description != null) ...[
            const SizedBox(height: DT.s3),
            Text(
              workout.description!,
              style: const TextStyle(color: DT.textSecondary, fontSize: DT.s3),
            ),
          ],
          const SizedBox(height: DT.s4),
          Wrap(
            spacing: DT.s4,
            runSpacing: DT.s2,
            children: [
              _StatChip(
                icon: Icons.fitness_center_outlined,
                label: '${workout.exercises.length} gyakorlat',
              ),
              _StatChip(icon: Icons.repeat, label: '${workout.totalSets} sorozat'),
              _StatChip(icon: Icons.access_time, label: workout.estimatedDuration),
              _StatChip(
                icon: Icons.local_fire_department_outlined,
                label: workout.kcal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _difficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'könnyű':
        return DT.difficultyLight;
      case 'nehéz':
        return DT.difficultyHard;
      default:
        return DT.difficultyMedium;
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
      padding: const EdgeInsets.symmetric(horizontal: DT.s2, vertical: DT.s1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(DT.s1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: DT.s3,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: DT.iconLight),
        const SizedBox(width: DT.s1),
        Text(
          label,
          style: const TextStyle(color: DT.textSecondary, fontSize: DT.s3),
        ),
      ],
    );
  }
}

// ─── Exercise Card ───────────────────────────────────────────────────────────

class _ExerciseCard extends StatelessWidget {
  final ExerciseModel exercise;
  const _ExerciseCard({required this.exercise});

  static const Map<String, _CategoryStyle> _styles = {
    'Mellkas': _CategoryStyle(color: Color(0xFF4A90D9), icon: Icons.fitness_center),
    'Háto': _CategoryStyle(color: Color(0xFF4ECDC4), icon: Icons.accessibility_new),
    'Lábak': _CategoryStyle(color: Color(0xFF7B68EE), icon: Icons.directions_run),
    'Vállak': _CategoryStyle(color: Color(0xFFFF6B35), icon: Icons.sports_handball),
    'Bicepsz': _CategoryStyle(color: Color(0xFFFFC85D), icon: Icons.fitness_center),
    'Tricepsz': _CategoryStyle(color: Color(0xFFFF6B6B), icon: Icons.fitness_center),
    'Core': _CategoryStyle(color: Color(0xFF32CD32), icon: Icons.self_improvement),
  };

  @override
  Widget build(BuildContext context) {
    final style = _styles[exercise.category] ??
        const _CategoryStyle(color: DT.iconLight, icon: Icons.fitness_center);

    return Container(
      decoration: BoxDecoration(
        color: DT.gbWhite,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        boxShadow: const [
          BoxShadow(color: DT.shadowLight, blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Exercise header
          Padding(
            padding: const EdgeInsets.fromLTRB(DT.s4, DT.s4, DT.s4, DT.s2),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: style.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(DT.s2),
                  ),
                  child: Icon(style.icon, color: style.color, size: 22),
                ),
                const SizedBox(width: DT.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          fontSize: DT.s4,
                          fontWeight: FontWeight.w700,
                          color: DT.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DT.s2,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: style.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(DT.s1),
                        ),
                        child: Text(
                          exercise.category,
                          style: TextStyle(
                            fontSize: 10,
                            color: style.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Description
          if (exercise.description != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(DT.s4, 0, DT.s4, DT.s3),
              child: Text(
                exercise.description!,
                style: const TextStyle(
                  fontSize: DT.s3,
                  color: DT.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          // ── Set table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: DT.s4, vertical: DT.s2),
            decoration: const BoxDecoration(
              color: DT.bg,
              border: Border.symmetric(
                horizontal: BorderSide(color: DT.borderLight, width: 1),
              ),
            ),
            child: Row(
              children: const [
                SizedBox(
                  width: 36,
                  child: Text(
                    'Set',
                    style: TextStyle(
                      fontSize: DT.s3,
                      color: DT.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Súly (kg)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: DT.s3,
                      color: DT.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Ismétlés',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: DT.s3,
                      color: DT.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 36),
              ],
            ),
          ),

          // ── Set rows
          ...exercise.sets.map(
            (set) => _SetRow(set: set, accentColor: style.color),
          ),
          const SizedBox(height: DT.s2),
        ],
      ),
    );
  }
}

class _CategoryStyle {
  final Color color;
  final IconData icon;
  const _CategoryStyle({required this.color, required this.icon});
}

class _SetRow extends StatelessWidget {
  final ExerciseSetModel set;
  final Color accentColor;
  const _SetRow({required this.set, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DT.s4, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: DT.borderLight, width: 1)),
      ),
      child: Row(
        children: [
          // Set number
          SizedBox(
            width: 36,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${set.setNumber}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ),
          ),
          // Weight
          Expanded(
            child: Text(
              set.weightDisplay,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: DT.s4,
                fontWeight: FontWeight.w700,
                color: DT.textPrimary,
              ),
            ),
          ),
          // Reps
          Expanded(
            child: Text(
              set.repDisplay,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: DT.s4,
                fontWeight: FontWeight.w700,
                color: DT.textPrimary,
              ),
            ),
          ),
          // Completion circle
          SizedBox(
            width: 36,
            child: Center(
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: DT.borderGrey, width: 2),
                ),
                child: const Icon(Icons.check, size: 14, color: DT.iconLightGrey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
