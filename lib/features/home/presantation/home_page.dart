import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/user_session.dart';
import 'package:flutter_application_1/features/coach/presentation/coach_home_page.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';
import 'package:flutter_application_1/features/workout/data/workout_mock_data.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// Role-aware shell: renders CoachHomePage or AthleteHomePage based on login role.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return UserSession.instance.isCoach
        ? const CoachHomePage()
        : const AthleteHomePage();
  }
}

// ─── Athlete Home ─────────────────────────────────────────────────────────────

class AthleteHomePage extends StatefulWidget {
  const AthleteHomePage({super.key});

  @override
  State<AthleteHomePage> createState() => _AthleteHomePageState();
}

class _AthleteHomePageState extends State<AthleteHomePage> {
  DateTime _selected = DateTime.now();

  WorkoutModel? get _workout =>
      WorkoutMockData.getWorkoutForDate(_selected, athleteId: 'a1');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.bg,
      appBar: AppBar(
        backgroundColor: DT.bg,
        elevation: 0,
        toolbarHeight: 80,
        title: Row(
          children: [
            // Avatar
            GestureDetector(
              onTap: () => context.go('/profile'),
              child: Container(
                margin: const EdgeInsets.only(right: DT.s3),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: DT.bg, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: DT.shadowMedium,
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Container(
                    color: DT.metricBlue.withOpacity(0.15),
                    child: const Icon(Icons.person, color: DT.metricBlue),
                  ),
                ),
              ),
            ),
            // Greeting + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Szia!',
                    style: TextStyle(
                      fontSize: DT.s4,
                      fontWeight: FontWeight.w600,
                      color: DT.textPrimary,
                    ),
                  ),
                  Text(
                    DateFormat('yyyy.MM.dd').format(DateTime.now()),
                    style: const TextStyle(
                      fontSize: DT.s3,
                      color: DT.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Search button
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: DT.gbWhite,
                borderRadius: BorderRadius.circular(DT.rCardSmall),
                boxShadow: const [
                  BoxShadow(color: DT.shadowLight, blurRadius: 10, offset: Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.search, color: DT.iconLight),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DT.s5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily challenge card
            _DailyChallengeCard(),
            const SizedBox(height: DT.s5),

            // Weekly date picker
            const Text(
              'Ezen a héten',
              style: TextStyle(
                fontSize: DT.s4,
                fontWeight: FontWeight.w700,
                color: DT.textPrimary,
              ),
            ),
            const SizedBox(height: DT.s3),
            _WeeklyStrip(
              selected: _selected,
              onDateSelected: (date) => setState(() => _selected = date),
            ),
            const SizedBox(height: DT.s5),

            // Workout for selected day
            const Text(
              'Edzéstervem',
              style: TextStyle(
                fontSize: DT.s4,
                fontWeight: FontWeight.w700,
                color: DT.textPrimary,
              ),
            ),
            const SizedBox(height: DT.s3),
            _workout != null
                ? _WorkoutCard(
                    workout: _workout!,
                    onTap: () => context.push('/workout-detail', extra: _workout),
                  )
                : _RestDayCard(date: _selected),
            const SizedBox(height: DT.s5),

            // Social / community section
            _SocialCard(),
          ],
        ),
      ),
    );
  }
}

// ─── Weekly Strip ─────────────────────────────────────────────────────────────

class _WeeklyStrip extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onDateSelected;
  const _WeeklyStrip({required this.selected, required this.onDateSelected});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));

    return SizedBox(
      height: 76,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = monday.add(Duration(days: index));
          final isSelected = date.day == selected.day &&
              date.month == selected.month &&
              date.year == selected.year;
          final hasWorkout = WorkoutMockData.getWorkoutForDate(date, athleteId: 'a1') != null;

          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              margin: const EdgeInsets.only(right: DT.s3),
              decoration: BoxDecoration(
                color: isSelected ? DT.gbBlack : DT.gbWhite,
                borderRadius: BorderRadius.circular(DT.rCardSmall),
                boxShadow: const [
                  BoxShadow(color: DT.shadowLight, blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date),
                    style: TextStyle(
                      fontSize: DT.s3,
                      color: isSelected ? DT.gbWhite : DT.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      fontSize: DT.s4,
                      color: isSelected ? DT.gbWhite : DT.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Workout dot indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasWorkout
                          ? (isSelected ? DT.gbWhite : DT.metricBlue)
                          : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Workout Card ─────────────────────────────────────────────────────────────

class _WorkoutCard extends StatelessWidget {
  final WorkoutModel workout;
  final VoidCallback onTap;
  const _WorkoutCard({required this.workout, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final diffColor = _diffColor(workout.difficulty);

    return Material(
      color: workout.color.withOpacity(0.25),
      borderRadius: BorderRadius.circular(DT.rCardSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        child: Container(
          padding: const EdgeInsets.all(DT.s5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DT.rCardSmall),
            border: Border(left: BorderSide(color: workout.color, width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DT.s2,
                      vertical: DT.s1,
                    ),
                    decoration: BoxDecoration(
                      color: diffColor,
                      borderRadius: BorderRadius.circular(DT.s1),
                    ),
                    child: Text(
                      workout.difficulty,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: DT.s3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: DT.textSecondary),
                ],
              ),
              const SizedBox(height: DT.s3),
              Text(
                workout.title,
                style: const TextStyle(
                  fontSize: DT.s5,
                  fontWeight: FontWeight.w700,
                  color: DT.textPrimary,
                ),
              ),
              if (workout.description != null) ...[
                const SizedBox(height: DT.s1),
                Text(
                  workout.description!,
                  style: const TextStyle(fontSize: DT.s3, color: DT.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: DT.s4),
              Wrap(
                spacing: DT.s4,
                children: [
                  _InfoChip(icon: Icons.fitness_center_outlined,
                      label: '${workout.exercises.length} gyakorlat'),
                  _InfoChip(icon: Icons.repeat, label: '${workout.totalSets} sorozat'),
                  _InfoChip(icon: Icons.access_time, label: workout.estimatedDuration),
                  _InfoChip(icon: Icons.local_fire_department, label: workout.kcal),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _diffColor(String d) {
    switch (d.toLowerCase()) {
      case 'könnyű':
        return DT.difficultyLight;
      case 'nehéz':
        return DT.difficultyHard;
      default:
        return DT.difficultyMedium;
    }
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
        Icon(icon, size: 14, color: DT.iconLight),
        const SizedBox(width: DT.s1),
        Text(label, style: const TextStyle(color: DT.textSecondary, fontSize: DT.s3)),
      ],
    );
  }
}

// ─── Rest Day Card ────────────────────────────────────────────────────────────

class _RestDayCard extends StatelessWidget {
  final DateTime date;
  const _RestDayCard({required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DT.s5),
      decoration: BoxDecoration(
        color: DT.gbWhite,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        boxShadow: const [
          BoxShadow(color: DT.shadowLight, blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.self_improvement, size: 48, color: DT.iconLightGrey),
          const SizedBox(height: DT.s3),
          const Text(
            'Pihenőnap',
            style: TextStyle(
              fontSize: DT.s4,
              fontWeight: FontWeight.w600,
              color: DT.textPrimary,
            ),
          ),
          const SizedBox(height: DT.s1),
          Text(
            'Erre a napra nincs ütemezett edzés.',
            style: const TextStyle(fontSize: DT.s3, color: DT.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Daily Challenge Card ─────────────────────────────────────────────────────

class _DailyChallengeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DT.s5),
      decoration: BoxDecoration(
        color: DT.gbWhite,
        borderRadius: BorderRadius.circular(DT.rCard),
        boxShadow: const [
          BoxShadow(color: DT.shadowLight, blurRadius: 20, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Napi kihívás',
            style: TextStyle(
              fontSize: DT.s5,
              fontWeight: FontWeight.w700,
              color: DT.textPrimary,
            ),
          ),
          const SizedBox(height: DT.s2),
          const Text(
            'Csináld meg az edzést 9:00 előtt',
            style: TextStyle(fontSize: DT.s4, color: DT.textSecondary),
          ),
          const SizedBox(height: DT.s3),
          // Overlapping user chips
          Row(
            children: [
              _UserChip(),
              Transform.translate(
                offset: const Offset(-DT.s2, 0),
                child: _UserChip(),
              ),
              Transform.translate(
                offset: const Offset(-DT.s4, 0),
                child: _UserChip(),
              ),
              Transform.translate(
                offset: const Offset(-DT.s6, 0),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DT.bg,
                    border: Border.all(color: DT.gbWhite, width: 2),
                  ),
                  child: const Center(
                    child: Text(
                      '+12',
                      style: TextStyle(
                        fontSize: 9,
                        color: DT.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DT.s4),
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(DT.rCardSmall),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DT.s4,
                vertical: DT.s2,
              ),
              decoration: BoxDecoration(
                color: DT.gbBlack,
                borderRadius: BorderRadius.circular(DT.rCardSmall),
              ),
              child: const Text(
                'Csatlakozz →',
                style: TextStyle(
                  color: DT.gbWhite,
                  fontSize: DT.s3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: DT.metricBlue.withOpacity(0.15),
        border: Border.all(color: DT.gbWhite, width: 2),
      ),
      child: const Icon(Icons.person, size: 18, color: DT.metricBlue),
    );
  }
}

// ─── Social Card ──────────────────────────────────────────────────────────────

class _SocialCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Közösség',
          style: TextStyle(
            fontSize: DT.s4,
            fontWeight: FontWeight.w700,
            color: DT.textPrimary,
          ),
        ),
        const SizedBox(height: DT.s3),
        Container(
          padding: const EdgeInsets.symmetric(vertical: DT.s4, horizontal: DT.s5),
          decoration: BoxDecoration(
            color: DT.gbWhite,
            borderRadius: BorderRadius.circular(DT.rCard),
            boxShadow: const [
              BoxShadow(color: DT.shadowLight, blurRadius: 16, offset: Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SocialItem(
                icon: Icons.camera_alt,
                color: DT.socialPink,
                label: 'Kamera',
                onTap: () {},
              ),
              _SocialItem(
                icon: Icons.play_circle_outline,
                color: DT.socialRed,
                label: 'Videó',
                onTap: () {},
              ),
              _SocialItem(
                icon: Icons.chat_bubble_outline,
                color: DT.socialBlue,
                label: 'Üzenet',
                onTap: () => context.go('/messages'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SocialItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;
  const _SocialItem({
    required this.icon,
    required this.color,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DT.rCard),
      child: Padding(
        padding: const EdgeInsets.all(DT.s2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: DT.s5),
            ),
            const SizedBox(height: DT.s1),
            Text(
              label,
              style: TextStyle(
                fontSize: DT.s3,
                color: DT.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
