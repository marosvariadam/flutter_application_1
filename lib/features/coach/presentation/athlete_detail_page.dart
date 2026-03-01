import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/coach/data/coach_mock_data.dart';
import 'package:flutter_application_1/features/coach/data/models/athlete_model.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AthleteDetailPage extends StatelessWidget {
  final String athleteId;
  const AthleteDetailPage({super.key, required this.athleteId});

  @override
  Widget build(BuildContext context) {
    final athlete = CoachMockData.getAthleteById(athleteId);
    if (athlete == null) {
      return const Scaffold(body: Center(child: Text('Atléta nem található.')));
    }

    final workouts = CoachMockData.getWorkoutsForAthlete(athleteId);

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
          athlete.fullName,
          style: const TextStyle(
            color: DT.textPrimary,
            fontSize: DT.s4,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: DT.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DT.s5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AthleteHeader(athlete: athlete),
            const SizedBox(height: DT.s5),
            _StatsRow(athlete: athlete),
            const SizedBox(height: DT.s5),
            const Text(
              'Ütemezett edzések',
              style: TextStyle(
                fontSize: DT.s4,
                fontWeight: FontWeight.w700,
                color: DT.textPrimary,
              ),
            ),
            const SizedBox(height: DT.s3),
            ...workouts.map((w) => _WorkoutRow(workout: w)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/workout-builder', extra: athleteId),
        backgroundColor: DT.gbBlack,
        foregroundColor: DT.gbWhite,
        icon: const Icon(Icons.add),
        label: const Text('Edzés hozzáadása'),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _AthleteHeader extends StatelessWidget {
  final AthleteModel athlete;
  const _AthleteHeader({required this.athlete});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: DT.metricBlue.withOpacity(0.12),
          ),
          child: Center(
            child: Text(
              athlete.initials,
              style: const TextStyle(
                fontSize: DT.s8,
                fontWeight: FontWeight.w700,
                color: DT.metricBlue,
              ),
            ),
          ),
        ),
        const SizedBox(width: DT.s4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                athlete.fullName,
                style: const TextStyle(
                  fontSize: DT.s5,
                  fontWeight: FontWeight.w700,
                  color: DT.textPrimary,
                ),
              ),
              if (athlete.goal != null) ...[
                const SizedBox(height: DT.s1),
                Text(
                  'Cél: ${athlete.goal}',
                  style: const TextStyle(fontSize: DT.s3, color: DT.textSecondary),
                ),
              ],
              if (athlete.lastWorkoutDate != null) ...[
                const SizedBox(height: DT.s1),
                Text(
                  'Utolsó edzés: ${athlete.lastWorkoutDate}',
                  style: const TextStyle(fontSize: DT.s3, color: DT.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final AthleteModel athlete;
  const _StatsRow({required this.athlete});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            color: DT.metricGreen,
            value: '${athlete.workoutCount}',
            label: 'Edzés',
          ),
        ),
        const SizedBox(width: DT.s3),
        Expanded(
          child: _StatCard(
            color: DT.metricOrange,
            value: '${athlete.streakDays}',
            label: 'Nap streak 🔥',
          ),
        ),
        const SizedBox(width: DT.s3),
        Expanded(
          child: _StatCard(
            color: DT.cardBlue.withOpacity(0.4),
            value: '3',
            label: 'Edzés / hét',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final Color color;
  final String value;
  final String label;
  const _StatCard({required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DT.s3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: DT.s5,
              fontWeight: FontWeight.w700,
              color: DT.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: DT.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Workout Row ──────────────────────────────────────────────────────────────

class _WorkoutRow extends StatelessWidget {
  final WorkoutModel workout;
  const _WorkoutRow({required this.workout});

  @override
  Widget build(BuildContext context) {
    final isPast = workout.scheduledDate.isBefore(DateTime.now());

    return GestureDetector(
      onTap: () => context.push('/workout-detail', extra: workout),
      child: Container(
        margin: const EdgeInsets.only(bottom: DT.s3),
        padding: const EdgeInsets.all(DT.s4),
        decoration: BoxDecoration(
          color: DT.gbWhite,
          borderRadius: BorderRadius.circular(DT.rCardSmall),
          border: Border(left: BorderSide(color: workout.color, width: 3)),
          boxShadow: const [
            BoxShadow(color: DT.shadowLight, blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        DateFormat('yyyy.MM.dd').format(workout.scheduledDate),
                        style: const TextStyle(
                          fontSize: DT.s3,
                          color: DT.textSecondary,
                        ),
                      ),
                      const SizedBox(width: DT.s2),
                      Text(
                        _dayName(workout.scheduledDate.weekday),
                        style: const TextStyle(
                          fontSize: DT.s3,
                          color: DT.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DT.s1),
                  Text(
                    workout.title,
                    style: const TextStyle(
                      fontSize: DT.s4,
                      fontWeight: FontWeight.w600,
                      color: DT.textPrimary,
                    ),
                  ),
                  const SizedBox(height: DT.s1),
                  Text(
                    '${workout.exercises.length} gyakorlat • ${workout.estimatedDuration}',
                    style: const TextStyle(fontSize: DT.s3, color: DT.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: DT.s2, vertical: DT.s1),
                  decoration: BoxDecoration(
                    color: isPast ? DT.difficultyLight.withOpacity(0.15) : DT.metricBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(DT.s1),
                  ),
                  child: Text(
                    isPast ? 'Elvégezve' : 'Tervezett',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isPast ? DT.difficultyLight : DT.metricBlue,
                    ),
                  ),
                ),
                const SizedBox(height: DT.s2),
                const Icon(Icons.arrow_forward_ios, size: 12, color: DT.textGrey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _dayName(int weekday) {
    const names = ['', 'Hétfő', 'Kedd', 'Szerda', 'Csütörtök', 'Péntek', 'Szombat', 'Vasárnap'];
    return names[weekday];
  }
}
