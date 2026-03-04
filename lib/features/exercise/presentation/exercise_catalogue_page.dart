import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/auth/bloc/auth_bloc.dart';
import 'package:flutter_application_1/features/exercise/bloc/exercise_bloc.dart';
import 'package:flutter_application_1/features/exercise/data/models/exercise_model.dart';
import 'package:flutter_application_1/features/exercise/data/repositories/exercise_repository.dart';

class ExerciseCataloguePage extends StatelessWidget {
  /// If true, tapping an exercise returns it to the caller (workout form).
  final bool selectionMode;

  const ExerciseCataloguePage({super.key, this.selectionMode = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ExerciseBloc(ctx.read<ExerciseRepository>())
        ..add(LoadExercises()),
      child: _CatalogueView(selectionMode: selectionMode),
    );
  }
}

class _CatalogueView extends StatefulWidget {
  final bool selectionMode;
  const _CatalogueView({required this.selectionMode});

  @override
  State<_CatalogueView> createState() => _CatalogueViewState();
}

class _CatalogueViewState extends State<_CatalogueView> {
  final _searchCtrl = TextEditingController();
  String? _selectedMuscleGroup;

  static const _muscleGroups = [
    'Mellkas', 'Hát', 'Váll', 'Bicepsz', 'Tricepsz',
    'Láb', 'Has', 'Comb', 'Fenék', 'Vádli',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search() {
    context.read<ExerciseBloc>().add(SearchExercises(
          _searchCtrl.text.trim(),
          muscleGroup: _selectedMuscleGroup,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final isTrainer = (context.watch<AuthBloc>().state) is AuthAuthenticated &&
        (context.read<AuthBloc>().state as AuthAuthenticated).user.isTrainer;

    return Scaffold(
      backgroundColor: DT.bg,
      appBar: AppBar(
        backgroundColor: DT.bg,
        elevation: 0,
        leading: BackButton(color: DT.textPrimary),
        title: const Text('Gyakorlat katalógus',
            style: TextStyle(
                color: DT.textPrimary, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          if (isTrainer && !widget.selectionMode)
            IconButton(
              icon: const Icon(Icons.add, color: DT.textPrimary),
              onPressed: () =>
                  context.push('/exercise/new').then((_) {
                context
                    .read<ExerciseBloc>()
                    .add(LoadExercises());
              }),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                DT.s4, DT.s3, DT.s4, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Keresés...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _search();
                        },
                      )
                    : null,
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                  horizontal: DT.s4, vertical: DT.s2),
              scrollDirection: Axis.horizontal,
              itemCount: _muscleGroups.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: DT.s2),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return FilterChip(
                    label: const Text('Összes'),
                    selected: _selectedMuscleGroup == null,
                    onSelected: (_) {
                      setState(() => _selectedMuscleGroup = null);
                      _search();
                    },
                  );
                }
                final mg = _muscleGroups[i - 1];
                return FilterChip(
                  label: Text(mg),
                  selected: _selectedMuscleGroup == mg,
                  onSelected: (_) {
                    setState(() => _selectedMuscleGroup =
                        _selectedMuscleGroup == mg ? null : mg);
                    _search();
                  },
                );
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<ExerciseBloc, ExerciseState>(
              builder: (context, state) {
                if (state is ExerciseLoading) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                if (state is ExerciseError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: DT.cardRed),
                        const SizedBox(height: DT.s4),
                        Text(state.message,
                            style: const TextStyle(
                                color: DT.textSecondary)),
                        const SizedBox(height: DT.s4),
                        ElevatedButton(
                            onPressed: () => context
                                .read<ExerciseBloc>()
                                .add(LoadExercises()),
                            child: const Text('Újra')),
                      ],
                    ),
                  );
                }
                if (state is ExercisesLoaded) {
                  if (state.exercises.isEmpty) {
                    return const Center(
                      child: Text('Nincs találat.',
                          style: TextStyle(
                              color: DT.textSecondary,
                              fontSize: DT.s4)),
                    );
                  }
                  return NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n is ScrollEndNotification &&
                          n.metrics.pixels >=
                              n.metrics.maxScrollExtent - 100) {
                        context
                            .read<ExerciseBloc>()
                            .add(LoadMoreExercises());
                      }
                      return false;
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(DT.s4),
                      itemCount: state.exercises.length +
                          (state.hasMore ? 1 : 0),
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: DT.s2),
                      itemBuilder: (context, i) {
                        if (i == state.exercises.length) {
                          return const Center(
                              child: Padding(
                            padding: EdgeInsets.all(DT.s4),
                            child: CircularProgressIndicator(),
                          ));
                        }
                        final e = state.exercises[i];
                        return _ExerciseTile(
                          exercise: e,
                          isTrainer: isTrainer,
                          selectionMode: widget.selectionMode,
                        );
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final ExerciseModel exercise;
  final bool isTrainer;
  final bool selectionMode;

  const _ExerciseTile({
    required this.exercise,
    required this.isTrainer,
    required this.selectionMode,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DT.gbWhite,
      borderRadius: BorderRadius.circular(DT.rCardSmall),
      child: InkWell(
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        onTap: selectionMode ? () => context.pop(exercise) : null,
        child: Padding(
          padding: const EdgeInsets.all(DT.s4),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: DT.metricBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.fitness_center,
                    color: DT.metricBlue, size: 20),
              ),
              const SizedBox(width: DT.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise.name,
                        style: const TextStyle(
                            color: DT.textPrimary,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Row(children: [
                      Text(exercise.muscleGroup,
                          style: const TextStyle(
                              color: DT.textSecondary,
                              fontSize: DT.s3)),
                      if (exercise.isCustom) ...[
                        const SizedBox(width: DT.s2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: DT.s2, vertical: 2),
                          decoration: BoxDecoration(
                            color: DT.metricOrange,
                            borderRadius:
                                BorderRadius.circular(DT.rChip),
                          ),
                          child: const Text('Egyéni',
                              style: TextStyle(
                                  color: DT.textPrimary,
                                  fontSize: 10)),
                        ),
                      ],
                    ]),
                  ],
                ),
              ),
              if (isTrainer && exercise.isCustom && !selectionMode)
                PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'edit') {
                      context.push('/exercise/${exercise.id}/edit');
                    } else if (action == 'delete') {
                      context
                          .read<ExerciseBloc>()
                          .add(DeleteExercise(exercise.id));
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'edit',
                        child: Text('Szerkesztés')),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Text('Törlés',
                            style: TextStyle(color: DT.cardRed))),
                  ],
                ),
              if (selectionMode)
                const Icon(Icons.chevron_right,
                    color: DT.iconLight),
            ],
          ),
        ),
      ),
    );
  }
}
