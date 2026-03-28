import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/user_session.dart';
import 'package:flutter_application_1/features/trainer/bloc/roster_bloc.dart';
import 'package:flutter_application_1/features/trainer/bloc/trainer_request_bloc.dart';
import 'package:flutter_application_1/features/trainer/data/models/trainer_request_model.dart';
import 'package:flutter_application_1/features/workout/bloc/workout_bloc.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class CoachHomePage extends StatefulWidget {
  const CoachHomePage({super.key});

  @override
  State<CoachHomePage> createState() => _CoachHomePageState();
}

class _CoachHomePageState extends State<CoachHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RosterBloc>().add(LoadRoster());
      context.read<TrainerRequestBloc>().add(LoadPendingRequests());
      context.read<WorkoutBloc>().add(LoadTrainerWorkouts());
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final trainerName = UserSession.instance.firstName ?? 'Edző';

    return Scaffold(
      backgroundColor: DT.of(context).bg,
      appBar: AppBar(
        backgroundColor: DT.of(context).bg,
        elevation: 0,
        toolbarHeight: 80,
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DT.metricBlue.withValues(alpha: 0.15),
                border: Border.all(color: DT.gbWhite, width: 2),
              ),
              child: const Icon(Icons.person, color: DT.metricBlue),
            ),
            const SizedBox(width: DT.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Szia, $trainerName!',
                    style: TextStyle(
                      fontSize: DT.s4,
                      fontWeight: FontWeight.w600,
                      color: DT.of(context).textPrimary,
                    ),
                  ),
                  Text(
                    DateFormat('yyyy. MMMM d.', 'hu').format(now),
                    style: TextStyle(
                      fontSize: DT.s3,
                      color: DT.of(context).textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Pending requests badge
            BlocBuilder<TrainerRequestBloc, TrainerRequestState>(
              builder: (context, state) {
                final pending = state is TrainerRequestsLoaded
                    ? state.requests.where((r) => r.isPending).length
                    : 0;
                return GestureDetector(
                  onTap: () => context.push('/trainer-requests'),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: DT.gbWhite,
                          borderRadius: BorderRadius.circular(DT.rCardSmall),
                          boxShadow: [
                            BoxShadow(
                              color: DT.of(context).shadowLight,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.notifications_outlined,
                            color: DT.of(context).iconLight),
                      ),
                      if (pending > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: DT.cardRed,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$pending',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DT.s5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Stats row ──────────────────────────────────────────────────
            _StatsRow(),
            const SizedBox(height: DT.s5),

            // ── Athletes horizontal list ────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Atlétáim',
                  style: TextStyle(
                    fontSize: DT.s4,
                    fontWeight: FontWeight.w700,
                    color: DT.of(context).textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/session'),
                  child: const Text('Összes'),
                ),
              ],
            ),
            const SizedBox(height: DT.s3),
            BlocBuilder<RosterBloc, RosterState>(
              builder: (context, state) {
                if (state is RosterInitial || state is RosterLoading) {
                  return const SizedBox(
                    height: 110,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final athletes =
                    state is RosterLoaded ? state.athletes : <AthleteModel>[];
                if (athletes.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: DT.s5),
                    child: Center(
                      child: Text(
                        'Még nincs atlétád',
                        style: TextStyle(
                          color: DT.of(context).textSecondary,
                          fontSize: DT.s4,
                        ),
                      ),
                    ),
                  );
                }
                return SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: athletes.length,
                    separatorBuilder: (_, __) => const SizedBox(width: DT.s3),
                    itemBuilder: (context, i) => _AthleteChip(
                      athlete: athletes[i],
                      onTap: () =>
                          context.push('/athlete-detail/${athletes[i].id}'),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: DT.s5),

            // ── This week's workouts ────────────────────────────────────────
            Text(
              'Edzések ezen a héten',
              style: TextStyle(
                fontSize: DT.s4,
                fontWeight: FontWeight.w700,
                color: DT.of(context).textPrimary,
              ),
            ),
            const SizedBox(height: DT.s3),
            BlocBuilder<WorkoutBloc, WorkoutState>(
              builder: (context, state) {
                if (state is WorkoutInitial || state is WorkoutLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all =
                    state is WorkoutsLoaded ? state.workouts : <WorkoutModel>[];

                final weekStart = now.subtract(Duration(days: now.weekday - 1));
                final weekEnd = weekStart.add(const Duration(days: 7));
                final thisWeek = all.where((w) {
                  return !w.scheduledDate.isBefore(
                          DateTime(weekStart.year, weekStart.month, weekStart.day)) &&
                      w.scheduledDate.isBefore(weekEnd);
                }).toList()
                  ..sort((a, b) =>
                      a.scheduledDate.compareTo(b.scheduledDate));

                if (thisWeek.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(DT.s5),
                    decoration: BoxDecoration(
                      color: DT.gbWhite,
                      borderRadius: BorderRadius.circular(DT.rCardSmall),
                      boxShadow: [
                        BoxShadow(
                          color: DT.of(context).shadowLight,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.event_available_outlined,
                            size: 40, color: DT.of(context).borderGrey),
                        const SizedBox(height: DT.s2),
                        Text(
                          'Erre a hétre nincs ütemezett edzés',
                          style: TextStyle(
                            color: DT.of(context).textSecondary,
                            fontSize: DT.s3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children:
                      thisWeek.map((w) => _WorkoutRow(workout: w)).toList(),
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/workout-builder'),
        backgroundColor: DT.gbBlack,
        foregroundColor: DT.gbWhite,
        icon: const Icon(Icons.add),
        label: const Text('Új edzés'),
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Athlete count
        Expanded(
          child: BlocBuilder<RosterBloc, RosterState>(
            builder: (context, state) {
              final count =
                  state is RosterLoaded ? state.athletes.length : null;
              return _StatCard(
                color: DT.cardBlue.withValues(alpha: 0.35),
                value: count != null ? '$count' : '…',
                label: 'Atléta',
                icon: Icons.people_outline,
              );
            },
          ),
        ),
        const SizedBox(width: DT.s3),
        // Workouts this week
        Expanded(
          child: BlocBuilder<WorkoutBloc, WorkoutState>(
            builder: (context, state) {
              int? count;
              if (state is WorkoutsLoaded) {
                final now = DateTime.now();
                final weekStart =
                    now.subtract(Duration(days: now.weekday - 1));
                count = state.workouts.where((w) {
                  return !w.scheduledDate.isBefore(DateTime(
                          weekStart.year, weekStart.month, weekStart.day)) &&
                      w.scheduledDate
                          .isBefore(weekStart.add(const Duration(days: 7)));
                }).length;
              }
              return _StatCard(
                color: DT.cardTeal.withValues(alpha: 0.35),
                value: count != null ? '$count' : '…',
                label: 'Edzés e héten',
                icon: Icons.fitness_center_outlined,
              );
            },
          ),
        ),
        const SizedBox(width: DT.s3),
        // Pending requests
        Expanded(
          child: BlocBuilder<TrainerRequestBloc, TrainerRequestState>(
            builder: (context, state) {
              final count = state is TrainerRequestsLoaded
                  ? state.requests.where((r) => r.isPending).length
                  : null;
              return _StatCard(
                color: DT.cardYellow.withValues(alpha: 0.5),
                value: count != null ? '$count' : '…',
                label: 'Kérés',
                icon: Icons.person_add_outlined,
              );
            },
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
  final IconData icon;

  const _StatCard({
    required this.color,
    required this.value,
    required this.label,
    required this.icon,
  });

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
          Icon(icon, size: 20, color: DT.of(context).textPrimary),
          const SizedBox(height: DT.s2),
          Text(
            value,
            style: TextStyle(
              fontSize: DT.s5,
              fontWeight: FontWeight.w700,
              color: DT.of(context).textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: DT.of(context).textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Athlete chip ──────────────────────────────────────────────────────────────

class _AthleteChip extends StatelessWidget {
  final AthleteModel athlete;
  final VoidCallback onTap;

  const _AthleteChip({required this.athlete, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initials =
        '${athlete.firstName.isNotEmpty ? athlete.firstName[0] : ''}${athlete.lastName.isNotEmpty ? athlete.lastName[0] : ''}'
            .toUpperCase();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        padding: const EdgeInsets.all(DT.s3),
        decoration: BoxDecoration(
          color: DT.gbWhite,
          borderRadius: BorderRadius.circular(DT.rCardSmall),
          boxShadow: [
            BoxShadow(
              color: DT.of(context).shadowLight,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DT.metricBlue.withValues(alpha: 0.12),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: DT.s4,
                    fontWeight: FontWeight.w700,
                    color: DT.metricBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: DT.s2),
            Text(
              athlete.firstName,
              style: TextStyle(
                fontSize: DT.s3,
                fontWeight: FontWeight.w600,
                color: DT.of(context).textPrimary,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Workout row ───────────────────────────────────────────────────────────────

class _WorkoutRow extends StatelessWidget {
  final WorkoutModel workout;

  const _WorkoutRow({required this.workout});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (workout.status) {
      WorkoutStatus.completed => Colors.green,
      WorkoutStatus.inProgress => DT.cardOrange,
      WorkoutStatus.planned => DT.metricBlue,
    };
    final statusLabel = switch (workout.status) {
      WorkoutStatus.completed => 'Teljesítve',
      WorkoutStatus.inProgress => 'Folyamatban',
      WorkoutStatus.planned => 'Tervezett',
    };

    return GestureDetector(
      onTap: () => context.push('/workout-detail', extra: workout.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: DT.s3),
        padding: const EdgeInsets.all(DT.s4),
        decoration: BoxDecoration(
          color: DT.gbWhite,
          borderRadius: BorderRadius.circular(DT.rCardSmall),
          border: Border(left: BorderSide(color: workout.color, width: 3)),
          boxShadow: [
            BoxShadow(
              color: DT.of(context).shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMM d.', 'hu')
                        .format(workout.scheduledDate),
                    style: TextStyle(
                      fontSize: DT.s3,
                      color: DT.of(context).textSecondary,
                    ),
                  ),
                  const SizedBox(height: DT.s1),
                  Text(
                    workout.title,
                    style: TextStyle(
                      fontSize: DT.s4,
                      fontWeight: FontWeight.w600,
                      color: DT.of(context).textPrimary,
                    ),
                  ),
                  if (workout.athleteName != null) ...[
                    const SizedBox(height: DT.s1),
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 12,
                            color: DT.of(context).textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          workout.athleteName!,
                          style: TextStyle(
                            fontSize: DT.s3,
                            color: DT.of(context).textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DT.s2, vertical: DT.s1),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(DT.s1),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: DT.s2),
                Icon(Icons.arrow_forward_ios,
                    size: 12, color: DT.of(context).textGrey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
