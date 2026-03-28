import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/user_session.dart';
import 'package:flutter_application_1/features/coach/presentation/coach_home_page.dart';
import 'package:flutter_application_1/features/workout/bloc/workout_bloc.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return UserSession.instance.isCoach ? const CoachHomePage() : const AthleteHomePage();
  }
}

class AthleteHomePage extends StatefulWidget {
  const AthleteHomePage({super.key});
  @override
  State<AthleteHomePage> createState() => _AthleteHomePageState();
}

class _AthleteHomePageState extends State<AthleteHomePage> {
  DateTime _selected = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<WorkoutBloc>().add(LoadMyWorkouts());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.of(context).bg,
      appBar: AppBar(
        backgroundColor: DT.of(context).bg,
        elevation: 0,
        toolbarHeight: 80,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => context.go('/profile'),
              child: Container(
                margin: const EdgeInsets.only(right: DT.s3),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: DT.of(context).bg, width: 2),
                  boxShadow: const [BoxShadow(color: DT.shadowMedium, blurRadius: 10, offset: Offset(0, 2))],
                ),
                child: ClipOval(
                  child: Container(
                    color: DT.metricBlue.withValues(alpha: 0.15),
                    child: const Icon(Icons.person, color: DT.metricBlue),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Szia, ${UserSession.instance.firstName ?? ''}!',
                    style: TextStyle(fontSize: DT.s4, fontWeight: FontWeight.w600, color: DT.of(context).textPrimary),
                  ),
                  Text(
                    DateFormat('yyyy.MM.dd').format(DateTime.now()),
                    style: TextStyle(fontSize: DT.s3, color: DT.of(context).textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: DT.gbWhite,
                borderRadius: BorderRadius.circular(DT.rCardSmall),
                boxShadow: [BoxShadow(color: DT.of(context).shadowLight, blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Icon(Icons.search, color: DT.of(context).iconLight),
            ),
          ],
        ),
      ),
      body: BlocBuilder<WorkoutBloc, WorkoutState>(
        builder: (context, state) {
          if (state is WorkoutInitial || state is WorkoutLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final workouts = state is WorkoutsLoaded ? state.workouts : <WorkoutModel>[];

          final workoutDateKeys = workouts
              .map((w) => '${w.scheduledDate.year}-${w.scheduledDate.month}-${w.scheduledDate.day}')
              .toSet();

          WorkoutModel? todayWorkout;
          try {
            todayWorkout = workouts.firstWhere(
              (w) => w.scheduledDate.year == _selected.year &&
                     w.scheduledDate.month == _selected.month &&
                     w.scheduledDate.day == _selected.day,
            );
          } catch (_) {}

          return SingleChildScrollView(
            padding: const EdgeInsets.all(DT.s5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ezen a héten', style: TextStyle(fontSize: DT.s4, fontWeight: FontWeight.w700, color: DT.of(context).textPrimary)),
                const SizedBox(height: DT.s3),
                _WeeklyStrip(
                  selected: _selected,
                  workoutDateKeys: workoutDateKeys,
                  onDateSelected: (date) => setState(() => _selected = date),
                ),
                const SizedBox(height: DT.s5),
                Text('Edzéstervem', style: TextStyle(fontSize: DT.s4, fontWeight: FontWeight.w700, color: DT.of(context).textPrimary)),
                const SizedBox(height: DT.s3),
                todayWorkout != null
                    ? _WorkoutCard(workout: todayWorkout, onTap: () => context.push('/workout-detail', extra: todayWorkout!.id))
                    : const _RestDayCard(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WeeklyStrip extends StatelessWidget {
  final DateTime selected;
  final Set<String> workoutDateKeys;
  final ValueChanged<DateTime> onDateSelected;
  const _WeeklyStrip({required this.selected, required this.workoutDateKeys, required this.onDateSelected});

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
          final isSelected = date.day == selected.day && date.month == selected.month && date.year == selected.year;
          final key = '${date.year}-${date.month}-${date.day}';
          final hasWorkout = workoutDateKeys.contains(key);
          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              margin: const EdgeInsets.only(right: DT.s3),
              decoration: BoxDecoration(
                color: isSelected ? DT.gbBlack : DT.gbWhite,
                borderRadius: BorderRadius.circular(DT.rCardSmall),
                boxShadow: [BoxShadow(color: DT.of(context).shadowLight, blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('E').format(date), style: TextStyle(fontSize: DT.s3, color: isSelected ? DT.gbWhite : DT.of(context).textSecondary, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(DateFormat('d').format(date), style: TextStyle(fontSize: DT.s4, color: isSelected ? DT.gbWhite : DT.of(context).textPrimary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasWorkout ? (isSelected ? DT.gbWhite : DT.metricBlue) : Colors.transparent,
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

class _WorkoutCard extends StatelessWidget {
  final WorkoutModel workout;
  final VoidCallback onTap;
  const _WorkoutCard({required this.workout, required this.onTap});

  static Color _diffColor(WorkoutDifficulty d) {
    switch (d) {
      case WorkoutDifficulty.easy: return DT.difficultyLight;
      case WorkoutDifficulty.hard: return DT.difficultyHard;
      case WorkoutDifficulty.intense: return DT.difficultyHard;
      default: return DT.difficultyMedium;
    }
  }

  @override
  Widget build(BuildContext context) {
    final diffColor = _diffColor(workout.difficulty);
    return Material(
      color: workout.color.withValues(alpha: 0.25),
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
                    padding: const EdgeInsets.symmetric(horizontal: DT.s2, vertical: DT.s1),
                    decoration: BoxDecoration(color: diffColor, borderRadius: BorderRadius.circular(DT.s1)),
                    child: Text(workout.difficulty.label, style: const TextStyle(color: Colors.white, fontSize: DT.s3, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 14, color: DT.of(context).textSecondary),
                ],
              ),
              const SizedBox(height: DT.s3),
              Text(workout.title, style: TextStyle(fontSize: DT.s5, fontWeight: FontWeight.w700, color: DT.of(context).textPrimary)),
              if (workout.description != null) ...[
                const SizedBox(height: DT.s1),
                Text(workout.description!, style: TextStyle(fontSize: DT.s3, color: DT.of(context).textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: DT.s4),
              Wrap(
                spacing: DT.s4,
                children: [
                  _InfoChip(icon: Icons.fitness_center_outlined, label: '${workout.exercises.length} gyakorlat'),
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
        Text(label, style: TextStyle(color: DT.of(context).textSecondary, fontSize: DT.s3)),
      ],
    );
  }
}

class _RestDayCard extends StatelessWidget {
  const _RestDayCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DT.s5),
      decoration: BoxDecoration(
        color: DT.gbWhite,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        boxShadow: [BoxShadow(color: DT.of(context).shadowLight, blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Icon(Icons.self_improvement, size: 48, color: DT.of(context).iconLightGrey),
          const SizedBox(height: DT.s3),
          Text('Pihenőnap', style: TextStyle(fontSize: DT.s4, fontWeight: FontWeight.w600, color: DT.of(context).textPrimary)),
          const SizedBox(height: DT.s1),
          Text('Erre a napra nincs ütemezett edzés.', style: TextStyle(fontSize: DT.s3, color: DT.of(context).textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

