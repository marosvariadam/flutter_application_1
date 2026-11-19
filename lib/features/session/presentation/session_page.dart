import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/user_session.dart';
import 'package:flutter_application_1/features/coach/presentation/athletes_page.dart';
import 'package:flutter_application_1/features/training_plan/bloc/my_plans_cubit.dart';
import 'package:flutter_application_1/features/training_plan/data/repositories/training_plan_repository.dart';
import 'package:flutter_application_1/features/training_plan/presentation/widgets/my_plan_section.dart';
import 'package:flutter_application_1/features/workout/bloc/workout_bloc.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';

// Role-aware shell: coaches see their athlete roster, athletes see workout catalog.
class SessionsPage extends StatelessWidget {
  const SessionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (UserSession.instance.isCoach) return const AthletesPage();
    return const _AthleteSessionsPage();
  }
}

class _AthleteSessionsPage extends StatefulWidget {
  const _AthleteSessionsPage();

  @override
  State<_AthleteSessionsPage> createState() => _AthleteSessionsPageState();
}

class _AthleteSessionsPageState extends State<_AthleteSessionsPage> {
  // Owned here (not by the list item) so scrolling the section out of view
  // doesn't refetch the plan.
  late final MyPlansCubit _myPlansCubit;

  @override
  void initState() {
    super.initState();
    _myPlansCubit = MyPlansCubit(context.read<TrainingPlanRepository>())
      ..load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<WorkoutBloc>().add(LoadMyWorkouts());
    });
  }

  @override
  void dispose() {
    _myPlansCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _myPlansCubit,
      child: Builder(builder: _buildScaffold),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.of(context).bg,
      appBar: AppBar(
        backgroundColor: DT.of(context).bg,
        elevation: 0,
        title: Text(
          'Edzés',
          style: TextStyle(
            color: DT.of(context).textPrimary,
            fontSize: DT.s4,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<WorkoutBloc, WorkoutState>(
        builder: (context, state) {
          if (state is WorkoutInitial || state is WorkoutLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          Future<void> onRefresh() async {
            _myPlansCubit.load();
            context.read<WorkoutBloc>().add(LoadMyWorkouts());
            await context.read<WorkoutBloc>().stream
                .firstWhere((s) => s is WorkoutsLoaded || s is WorkoutError);
          }

          if (state is WorkoutError) {
            return RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(DT.s5, DT.s5, DT.s5, 0),
                    child: MyPlanSection(),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: DT.of(context).accentDanger),
                        const SizedBox(height: DT.s4),
                        Text(
                          state.message,
                          style: TextStyle(color: DT.of(context).textSecondary, fontSize: DT.s4),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: DT.s4),
                        ElevatedButton(
                          onPressed: () => context.read<WorkoutBloc>().add(LoadMyWorkouts()),
                          child: const Text('Újra'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          final workouts = state is WorkoutsLoaded ? state.workouts : <WorkoutModel>[];

          if (workouts.isEmpty) {
            return RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(DT.s5, DT.s5, DT.s5, 0),
                    child: MyPlanSection(),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fitness_center_outlined, size: 64, color: DT.of(context).iconLightGrey),
                        const SizedBox(height: DT.s4),
                        Text(
                          'Jelenleg nincs elérhető edzés.',
                          style: TextStyle(color: DT.of(context).textSecondary, fontSize: DT.s4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          final upcoming = workouts.where((w) => w.status != WorkoutStatus.completed).toList();
          final completed = workouts.where((w) => w.status == WorkoutStatus.completed).toList();
          final hasMore = state is WorkoutsLoaded && state.hasMore;

          final items = <Object>[
            const _PlanSectionItem(),
            if (upcoming.isNotEmpty) ...[
              _SectionHeader('Közelgő edzések', upcoming.length),
              ...upcoming,
            ],
            if (completed.isNotEmpty) ...[
              _SectionHeader('Teljesítve', completed.length),
              ...completed,
            ],
            if (hasMore) const _LoaderItem(),
          ];

          return RefreshIndicator(
            onRefresh: onRefresh,
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n is ScrollEndNotification &&
                    n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                  context.read<WorkoutBloc>().add(LoadMoreWorkouts());
                }
                return false;
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(DT.s5),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  if (item is _PlanSectionItem) return const MyPlanSection();
                  if (item is _SectionHeader) {
                    return _SectionHeaderTile(header: item);
                  }
                  if (item is _LoaderItem) {
                    return const Center(child: Padding(
                      padding: EdgeInsets.all(DT.s4),
                      child: CircularProgressIndicator(),
                    ));
                  }
                  final workout = item as WorkoutModel;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: DT.s4),
                    child: _SessionCard(
                      workout: workout,
                      onTap: () => context.push('/workout-detail', extra: workout.id),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// List item helpers

class _SectionHeader {
  final String title;
  final int count;
  const _SectionHeader(this.title, this.count);
}

class _LoaderItem {
  const _LoaderItem();
}

class _PlanSectionItem {
  const _PlanSectionItem();
}

class _SectionHeaderTile extends StatelessWidget {
  final _SectionHeader header;
  const _SectionHeaderTile({required this.header});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DT.s3, top: DT.s2),
      child: Row(
        children: [
          Text(
            header.title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: DT.of(context).textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: DT.s2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: DT.of(context).borderLight,
              borderRadius: BorderRadius.circular(DT.rChip),
            ),
            child: Text(
              '${header.count}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: DT.of(context).textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//

class _SessionCard extends StatelessWidget {
  final WorkoutModel workout;
  final VoidCallback onTap;

  const _SessionCard({required this.workout, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCompleted = workout.status == WorkoutStatus.completed;
    final isInProgress = workout.status == WorkoutStatus.inProgress;

    final difficultyColor = switch (workout.difficulty) {
      WorkoutDifficulty.easy => DT.of(context).difficultyEasy,
      WorkoutDifficulty.hard || WorkoutDifficulty.intense => DT.of(context).difficultyHard,
      _ => DT.of(context).difficultyMedium,
    };

    final accentColor = isCompleted ? DT.of(context).accentSuccess : workout.color;

    return Opacity(
      opacity: isCompleted ? 0.65 : 1.0,
      child: Material(
        color: DT.of(context).cardSurface,
        borderRadius: BorderRadius.circular(DT.s5),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DT.s5),
          child: Padding(
            padding: const EdgeInsets.all(DT.s5),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left accent bar
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: accentColor,
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
                              child: Text(
                                workout.title,
                                style: TextStyle(
                                  color: DT.of(context).textPrimary,
                                  fontSize: DT.s4,
                                  fontWeight: FontWeight.w600,
                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                  decorationColor: DT.of(context).textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: DT.s2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: DT.s2, vertical: DT.s1),
                              decoration: BoxDecoration(
                                color: difficultyColor,
                                borderRadius: BorderRadius.circular(DT.s2),
                              ),
                              child: Text(
                                workout.difficulty.label,
                                style: TextStyle(
                                  color: DT.of(context).textOnAccent,
                                  fontSize: DT.s3,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (workout.trainerName != null) ...[
                          const SizedBox(height: DT.s1),
                          Text(
                            'Edző: ${workout.trainerName}',
                            style: TextStyle(color: DT.of(context).textSecondary, fontSize: DT.s3),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (workout.description != null) ...[
                          const SizedBox(height: DT.s1),
                          Text(
                            workout.description!,
                            style: TextStyle(color: DT.of(context).textSecondary, fontSize: DT.s3),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: DT.s2),
                        Wrap(
                          spacing: DT.s3,
                          runSpacing: DT.s1,
                          children: [
                            _InfoChip(icon: Icons.access_time, text: workout.estimatedDuration),
                            _InfoChip(icon: Icons.local_fire_department, text: workout.kcal),
                            if (isInProgress)
                              _InfoChip(icon: Icons.play_circle_outline, text: 'Folyamatban'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: DT.s3),
                  // Right indicator
                  Center(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(DT.rChip),
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : Icons.arrow_forward_ios,
                        color: accentColor,
                        size: isCompleted ? 18 : 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: DT.s4, color: DT.of(context).iconLight),
        const SizedBox(width: DT.s1),
        Text(
          text,
          style: TextStyle(
            color: DT.of(context).textSecondary,
            fontSize: DT.s3,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
