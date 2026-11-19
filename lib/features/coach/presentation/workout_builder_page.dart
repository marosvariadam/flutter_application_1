import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/autoregulation/bloc/autoregulation_cubit.dart';
import 'package:flutter_application_1/features/autoregulation/data/repositories/autoregulation_repository.dart';
import 'package:flutter_application_1/features/autoregulation/presentation/widgets/autoregulation_banner.dart';
import 'package:flutter_application_1/features/coach/presentation/widgets/builder_section.dart';
import 'package:flutter_application_1/features/coach/presentation/widgets/exercise_builder_card.dart';
import 'package:flutter_application_1/features/coach/presentation/widgets/workout_athlete_selector.dart';
import 'package:flutter_application_1/features/coach/presentation/widgets/workout_builder_models.dart';
import 'package:flutter_application_1/features/coach/presentation/widgets/workout_difficulty_selector.dart';
import 'package:flutter_application_1/features/exercise/data/models/exercise_model.dart';
import 'package:flutter_application_1/features/exercise/data/repositories/exercise_repository.dart';
import 'package:flutter_application_1/features/exercise/presentation/widgets/exercise_picker.dart';
import 'package:flutter_application_1/features/trainer/data/models/trainer_request_model.dart';
import 'package:flutter_application_1/features/trainer/data/repositories/roster_repository.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';
import 'package:flutter_application_1/features/workout/data/repositories/workout_repository.dart';
import 'package:intl/intl.dart';

// Page

class WorkoutBuilderPage extends StatefulWidget {
  final String? preselectedAthleteId;
  const WorkoutBuilderPage({super.key, this.preselectedAthleteId});

  @override
  State<WorkoutBuilderPage> createState() => _WorkoutBuilderPageState();
}

class _WorkoutBuilderPageState extends State<WorkoutBuilderPage> {
  final _titleCtrl = TextEditingController(text: 'Új edzés');
  final _notesCtrl = TextEditingController();
  WorkoutDifficulty _difficulty = WorkoutDifficulty.moderate;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  String? _selectedAthleteId;

  final List<BuilderExercise> _exercises = [];
  List<AthleteModel> _athletes = [];
  List<ExerciseModel> _exerciseLibrary = [];

  // exerciseName.toLowerCase() -> {prevWeightKg, prevReps}
  Map<String, ({double? weight, int? reps})> _prevData = {};

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isFetchingPrev = false;

  // Next-week load suggestions for the selected athlete.
  late final AutoregulationCubit _autoregCubit;

  @override
  void initState() {
    super.initState();
    _selectedAthleteId = widget.preselectedAthleteId;
    _autoregCubit =
        AutoregulationCubit(context.read<AutoregulationRepository>());
    if (_selectedAthleteId != null) _autoregCubit.load(_selectedAthleteId!);
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    _autoregCubit.close();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        context.read<RosterRepository>().getAthletes(),
        context.read<ExerciseRepository>().getExercises(pageSize: 100),
      ]);
      if (!mounted) return;
      setState(() {
        _athletes = (results[0] as PaginatedAthletes).items;
        _exerciseLibrary = (results[1] as PaginatedExercises).items;
        _isLoading = false;
      });
      if (_selectedAthleteId != null) {
        _fetchPreviousData(_selectedAthleteId!);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPreviousData(String athleteId) async {
    setState(() => _isFetchingPrev = true);
    try {
      final workouts = await context.read<WorkoutRepository>().getTrainerReview(athleteId);
      final map = <String, ({double? weight, int? reps})>{};
      // Most recent workouts first - earlier entries won't overwrite later ones
      for (final w in workouts) {
        for (final ex in w.exercises) {
          final key = ex.name.toLowerCase();
          if (!map.containsKey(key)) {
            map[key] = (weight: ex.actualWeightKg ?? ex.targetWeightKg, reps: ex.actualReps ?? ex.targetReps);
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _prevData = map;
        _isFetchingPrev = false;
        // Apply to already-added exercises
        for (final ex in _exercises) {
          final prev = _prevData[ex.name.toLowerCase()];
          ex.prevWeightKg = prev?.weight;
          ex.prevReps = prev?.reps;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _isFetchingPrev = false);
    }
  }

  void _onAthleteChanged(String? id) {
    setState(() {
      _selectedAthleteId = id;
      _prevData = {};
      for (final ex in _exercises) {
        ex.prevWeightKg = null;
        ex.prevReps = null;
      }
    });
    if (id != null) {
      _fetchPreviousData(id);
      _autoregCubit.load(id);
    } else {
      _autoregCubit.reset();
    }
  }

  void _addExercise(ExerciseModel lib) {
    final equip = guessEquipment(lib.equipment);
    final prev = _prevData[lib.name.toLowerCase()];
    setState(() {
      _exercises.add(BuilderExercise(
        exerciseId: lib.id,
        name: lib.name,
        muscleGroup: lib.muscleGroup,
        equipmentType: equip,
        initialSets: 3,
        defaultReps: prev?.reps,
        defaultWeightKg: prev?.weight,
        prevWeightKg: prev?.weight,
        prevReps: prev?.reps,
      ));
    });
    Navigator.of(context).pop();
  }

  void _removeExercise(int i) => setState(() => _exercises.removeAt(i));

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _showExercisePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DT.of(context).cardSurfaceElevated,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(DT.rCard))),
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, ctrl) => ExercisePicker(
          exerciseRepo: context.read<ExerciseRepository>(),
          athleteId: _selectedAthleteId,
          scrollController: ctrl,
          onSelect: _addExercise,
          onCustomCreated: (ex) {
            // Also add the new exercise to our local library cache
            _exerciseLibrary.insert(0, ex);
          },
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _snack('Adj meg egy edzés nevet!');
      return;
    }
    if (_selectedAthleteId == null) {
      _snack('Válassz sportolót!');
      return;
    }
    if (_exercises.isEmpty) {
      _snack('Adj hozzá legalább egy gyakorlatot!');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final exercisePayload = _exercises.asMap().entries.map((e) {
        final ex = e.value;
        final isBodyweight = ex.equipmentType == kEquipmentBodyweight;
        final first = ex.setEntries.isNotEmpty ? ex.setEntries.first : null;
        return {
          if (ex.exerciseId.isNotEmpty) 'exerciseId': ex.exerciseId,
          'name': ex.name,
          'index': e.key,
          'sets': ex.sets,
          'equipmentType': ex.equipmentType,
          // First-set values kept as top-level for backward compat
          'targetReps': first?.reps ?? 0,
          'targetWeightKg': isBodyweight ? 0.0 : (first?.weightKg ?? 0.0),
          'setEntries': ex.setEntries.asMap().entries.map((s) => {
                'setIndex': s.key,
                'targetReps': s.value.reps ?? 0,
                'targetWeightKg':
                    isBodyweight ? 0.0 : (s.value.weightKg ?? 0.0),
              }).toList(),
        };
      }).toList();

      await context.read<WorkoutRepository>().createWorkout(
            title: _titleCtrl.text.trim(),
            athleteId: _selectedAthleteId!,
            scheduledDate: _date,
            difficulty: _difficulty,
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
            exercises: exercisePayload,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Edzés sikeresen létrehozva!'),
          backgroundColor: DT.difficultyLight,
        ),
      );
      Navigator.of(context).pop();
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data is Map
          ? (data['message'] ?? data['title'] ?? data.toString())
          : 'Szerverhiba (${e.response?.statusCode})';
      _snack(msg.toString());
    } catch (e) {
      _snack('Hiba: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _autoregCubit,
      child: Builder(builder: _buildScaffold),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.of(context).bg,
      appBar: AppBar(
        backgroundColor: DT.of(context).bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: DT.of(context).textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Edzés összeállítása',
            style: TextStyle(
                color: DT.of(context).textPrimary,
                fontSize: DT.s4,
                fontWeight: FontWeight.w600)),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Mentés',
                  style: TextStyle(
                      color: DT.metricBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: DT.s4)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(DT.s5),
              children: [
                // Workout name
                BuilderSectionLabel('Edzés neve'),
                BuilderWhiteCard(
                  child: TextField(
                    controller: _titleCtrl,
                    style: TextStyle(
                        fontSize: DT.s4,
                        fontWeight: FontWeight.w600,
                        color: DT.of(context).textPrimary),
                    decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: DT.s4, vertical: DT.s3)),
                  ),
                ),
                const SizedBox(height: DT.s4),

                // Difficulty
                BuilderSectionLabel('Nehézségi szint'),
                WorkoutDifficultySelector(
                    selected: _difficulty,
                    onChanged: (d) => setState(() => _difficulty = d)),
                const SizedBox(height: DT.s4),

                // Athlete
                BuilderSectionLabel('Sportoló'),
                if (_athletes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(DT.s3),
                    child: Text('Nincs hozzárendelt sportoló.',
                        style: TextStyle(color: DT.of(context).textSecondary)),
                  )
                else
                  WorkoutAthleteSelector(
                    athletes: _athletes,
                    selectedId: _selectedAthleteId,
                    isFetchingPrev: _isFetchingPrev,
                    onChanged: _onAthleteChanged,
                  ),
                const SizedBox(height: DT.s4),

                // Date
                BuilderSectionLabel('Dátum'),
                GestureDetector(
                  onTap: _pickDate,
                  child: BuilderWhiteCard(
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: DT.metricBlue, size: 20),
                        const SizedBox(width: DT.s3),
                        Text(DateFormat('yyyy.MM.dd').format(_date),
                            style: TextStyle(
                                fontSize: DT.s4,
                                fontWeight: FontWeight.w600,
                                color: DT.of(context).textPrimary)),
                        const Spacer(),
                        Icon(Icons.arrow_forward_ios,
                            size: 14, color: DT.of(context).textGrey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: DT.s4),

                // Notes
                BuilderSectionLabel('Megjegyzés (opcionális)'),
                BuilderWhiteCard(
                  child: TextField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    style: TextStyle(
                        fontSize: DT.s3, color: DT.of(context).textPrimary),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Pl. fókuszálj a technikára…',
                      hintStyle: TextStyle(color: DT.of(context).textGrey),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: DT.s4, vertical: DT.s3),
                    ),
                  ),
                ),
                const SizedBox(height: DT.s5),

                // Exercises
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Gyakorlatok',
                        style: TextStyle(
                            fontSize: DT.s4,
                            fontWeight: FontWeight.w700,
                            color: DT.of(context).textPrimary)),
                    Text('${_exercises.length} db',
                        style: TextStyle(
                            fontSize: DT.s3, color: DT.of(context).textSecondary)),
                  ],
                ),
                const SizedBox(height: DT.s3),
                const AutoregulationBanner(),

                ..._exercises.asMap().entries.map((entry) =>
                    ExerciseBuilderCard(
                      key: ValueKey(entry.key),
                      exercise: entry.value,
                      onRemove: () => _removeExercise(entry.key),
                      onChanged: () => setState(() {}),
                    )),

                const SizedBox(height: DT.s3),
                GestureDetector(
                  onTap: _showExercisePicker,
                  child: Container(
                    padding: const EdgeInsets.all(DT.s4),
                    decoration: BoxDecoration(
                      color: DT.of(context).cardSurface,
                      borderRadius: BorderRadius.circular(DT.rCardSmall),
                      border: Border.all(color: DT.of(context).borderGrey, width: 1.5),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, color: DT.metricBlue),
                        SizedBox(width: DT.s2),
                        Text('Gyakorlat hozzáadása',
                            style: TextStyle(
                                color: DT.metricBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: DT.s4)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: DT.s8),
              ],
            ),
    );
  }
}
