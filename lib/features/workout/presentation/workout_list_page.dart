import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/auth/bloc/auth_bloc.dart';
import 'package:flutter_application_1/features/trainer/presentation/roster_page.dart';
import 'package:flutter_application_1/features/workout/bloc/workout_bloc.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';
import 'package:flutter_application_1/features/workout/data/repositories/workout_repository.dart';

/// Central hub for the middle tab.
/// Trainers see their athlete roster; athletes see their workout list.
class WorkoutsHubPage extends StatelessWidget {
  const WorkoutsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final isTrainer =
        state is AuthAuthenticated && state.user.isTrainer;
    if (isTrainer) {
      return const RosterPage();
    }
    return const AthleteWorkoutListPage();
  }
}

// Athlete workout list

class AthleteWorkoutListPage extends StatelessWidget {
  const AthleteWorkoutListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => WorkoutBloc(ctx.read<WorkoutRepository>())
        ..add(LoadMyWorkouts()),
      child: const _AthleteWorkoutView(),
    );
  }
}

class _AthleteWorkoutView extends StatelessWidget {
  const _AthleteWorkoutView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.of(context).bg,
      appBar: AppBar(
        backgroundColor: DT.of(context).bg,
        elevation: 0,
        title: Text('Edzések',
            style: TextStyle(
                color: DT.of(context).textPrimary, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_month_outlined,
                color: DT.of(context).textPrimary),
            onPressed: () => context.push('/workout/calendar'),
          ),
        ],
      ),
      body: BlocBuilder<WorkoutBloc, WorkoutState>(
        builder: (context, state) {
          if (state is WorkoutLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          Future<void> onRefresh() async {
            context.read<WorkoutBloc>().add(LoadMyWorkouts());
            await context.read<WorkoutBloc>().stream
                .firstWhere((s) => s is WorkoutsLoaded || s is WorkoutError);
          }

          if (state is WorkoutError) {
            return RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView(
                children: [_ErrorView(
                  message: state.message,
                  onRetry: () =>
                      context.read<WorkoutBloc>().add(LoadMyWorkouts()),
                )],
              ),
            );
          }
          if (state is WorkoutsLoaded) {
            if (state.workouts.isEmpty) {
              return RefreshIndicator(
                onRefresh: onRefresh,
                child: ListView(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fitness_center_outlined,
                              size: 64, color: DT.of(context).iconLightGrey),
                          const SizedBox(height: DT.s4),
                          Text('Jelenleg nincs elérhető edzés.',
                              style: TextStyle(
                                  color: DT.of(context).textSecondary,
                                  fontSize: DT.s4)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: onRefresh,
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n is ScrollEndNotification &&
                      n.metrics.pixels >=
                          n.metrics.maxScrollExtent - 200) {
                    context.read<WorkoutBloc>().add(LoadMoreWorkouts());
                  }
                  return false;
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(DT.s5),
                  itemCount: state.workouts.length + (state.hasMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: DT.s4),
                  itemBuilder: (context, i) {
                    if (i == state.workouts.length) {
                      return const Center(
                          child: Padding(
                        padding: EdgeInsets.all(DT.s4),
                        child: CircularProgressIndicator(),
                      ));
                    }
                    return WorkoutCard(
                      workout: state.workouts[i],
                      onTap: () => context
                          .push('/workout/${state.workouts[i].id}'),
                    );
                  },
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// Shared workout card

class WorkoutCard extends StatelessWidget {
  final WorkoutModel workout;
  final VoidCallback onTap;

  const WorkoutCard({super.key, required this.workout, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(workout.status);
    final diffColor = _diffColor(workout.difficulty);

    return Material(
      color: DT.of(context).cardSurface,
      borderRadius: BorderRadius.circular(DT.rCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DT.rCard),
        child: Padding(
          padding: const EdgeInsets.all(DT.s5),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(DT.s2),
                  ),
                ),
                const SizedBox(width: DT.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(workout.title,
                                style: TextStyle(
                                    color: DT.of(context).textPrimary,
                                    fontSize: DT.s4,
                                    fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: DT.s2),
                          _Badge(
                              label: workout.difficulty.label,
                              color: diffColor),
                        ],
                      ),
                      const SizedBox(height: DT.s1),
                      if (workout.trainerName != null)
                        Text('Edző: ${workout.trainerName}',
                            style: TextStyle(
                                color: DT.of(context).textSecondary,
                                fontSize: DT.s3)),
                      const SizedBox(height: DT.s1),
                      Text(
                        DateFormat('yyyy. MMM d.', 'hu')
                            .format(workout.scheduledDate),
                        style: TextStyle(
                            color: DT.of(context).textSecondary, fontSize: DT.s3),
                      ),
                      const SizedBox(height: DT.s2),
                      _Badge(
                          label: workout.status.label,
                          color: statusColor),
                    ],
                  ),
                ),
                Center(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(DT.rChip),
                    ),
                    child: Icon(Icons.arrow_forward_ios,
                        color: statusColor, size: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
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

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: DT.s2, vertical: DT.s1),
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

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: DT.cardRed),
          const SizedBox(height: DT.s4),
          Text(message,
              style:
                  TextStyle(color: DT.of(context).textSecondary, fontSize: DT.s4)),
          const SizedBox(height: DT.s4),
          ElevatedButton(onPressed: onRetry, child: const Text('Újra')),
        ],
      ),
    );
  }
}
