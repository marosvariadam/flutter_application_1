import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/auth/bloc/auth_bloc.dart';
import 'package:flutter_application_1/features/workout/bloc/workout_bloc.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';
import 'package:flutter_application_1/features/workout/data/repositories/workout_repository.dart';
import 'package:flutter_application_1/app/shared/widgets/error_state.dart';
import 'package:flutter_application_1/app/shared/widgets/section_header.dart';
import 'package:flutter_application_1/app/shared/widgets/skeleton.dart';
import 'package:flutter_application_1/features/workout/presentation/widgets/active_workout.dart';
import 'package:flutter_application_1/features/workout/presentation/widgets/workout_detail_sections.dart';

class WorkoutDetailPage extends StatelessWidget {
  final String workoutId;
  const WorkoutDetailPage({super.key, required this.workoutId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => WorkoutBloc(ctx.read<WorkoutRepository>())
        ..add(LoadWorkoutDetail(workoutId)),
      child: WorkoutDetailView(workoutId: workoutId),
    );
  }
}

class WorkoutDetailView extends StatelessWidget {
  final String workoutId;
  const WorkoutDetailView({super.key, required this.workoutId});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isTrainer =
        authState is AuthAuthenticated && authState.user.isTrainer;

    return BlocConsumer<WorkoutBloc, WorkoutState>(
      listener: (context, state) {
        if (state is WorkoutActionSuccess) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
          if (state.workout?.status == WorkoutStatus.completed) {
            context.pop();
          }
        }
        if (state is WorkoutError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        if (state is WorkoutLoading) {
          return const _LoadingScaffold();
        }
        if (state is WorkoutDetailLoaded) {
          final w = state.workout;

          // Active workout view (athlete, in-progress)
          if (!isTrainer && w.status == WorkoutStatus.inProgress) {
            return Scaffold(
              backgroundColor: DT.of(context).bg,
              appBar: AppBar(
                backgroundColor: DT.of(context).bg,
                elevation: 0,
                leading: BackButton(color: DT.of(context).textPrimary),
                title: Text(w.title,
                    style: TextStyle(
                        color: DT.of(context).textPrimary,
                        fontWeight: FontWeight.w600)),
                centerTitle: true,
              ),
              body: ActiveWorkoutBody(workout: w),
            );
          }

          // Detail view (trainer or planned/completed)
          return Scaffold(
            backgroundColor: DT.of(context).bg,
            appBar: AppBar(
              backgroundColor: DT.of(context).bg,
              elevation: 0,
              leading: BackButton(color: DT.of(context).textPrimary),
              title: Text(w.title,
                  style: TextStyle(
                      color: DT.of(context).textPrimary,
                      fontWeight: FontWeight.w600)),
              centerTitle: true,
              actions: [
                if (isTrainer && w.status == WorkoutStatus.planned)
                  IconButton(
                    tooltip: 'Szerkesztés',
                    icon: Icon(Icons.edit_outlined,
                        color: DT.of(context).textPrimary),
                    onPressed: () =>
                        context.push('/workout/${w.id}/edit').then((_) {
                      if (!context.mounted) return;
                      context
                          .read<WorkoutBloc>()
                          .add(LoadWorkoutDetail(w.id));
                    }),
                  ),
                if (isTrainer)
                  IconButton(
                    tooltip: 'Törlés',
                    icon: Icon(Icons.delete_outline, color: DT.of(context).accentDanger),
                    onPressed: () => _confirmDelete(context, w),
                  ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(DT.s5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WorkoutHeader(workout: w),
                  const SizedBox(height: DT.s5),
                  const SectionHeader(title: 'Gyakorlatok'),
                  ...w.exercises.map((e) => WorkoutExerciseCard(
                        exercise: e,
                        isAthlete: !isTrainer,
                        workoutStatus: w.status,
                        workoutId: w.id,
                      )),
                  const SizedBox(height: DT.s6),
                  if (!isTrainer) AthleteActions(workout: w),
                ],
              ),
            ),
          );
        }
        if (state is WorkoutError) {
          return Scaffold(
            appBar: AppBar(leading: const BackButton()),
            body: ErrorState(
              message: state.message,
              onRetry: () => context
                  .read<WorkoutBloc>()
                  .add(LoadWorkoutDetail(workoutId)),
            ),
          );
        }
        return const _LoadingScaffold();
      },
    );
  }

  void _confirmDelete(BuildContext context, WorkoutModel w) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edzés törlése'),
        content: Text('Biztosan törlöd a(z) "${w.title}" edzést?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Mégse')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<WorkoutBloc>().add(DeleteWorkout(w.id));
              context.pop();
            },
            child:
                Text('Törlés', style: TextStyle(color: DT.of(context).accentDanger)),
          ),
        ],
      ),
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.of(context).bg,
      appBar: AppBar(
        backgroundColor: DT.of(context).bg,
        elevation: 0,
        leading: BackButton(color: DT.of(context).textPrimary),
      ),
      body: const SkeletonList(
          itemCount: 4, itemHeight: 96, padding: EdgeInsets.all(DT.s5)),
    );
  }
}
