import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/exercise/data/models/exercise_model.dart';
import 'package:flutter_application_1/features/exercise/data/repositories/exercise_repository.dart';
import 'package:flutter_application_1/features/trainer/data/models/trainer_request_model.dart';
import 'package:flutter_application_1/features/trainer/data/repositories/roster_repository.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';
import 'package:flutter_application_1/features/workout/data/repositories/workout_repository.dart';
import 'package:intl/intl.dart';

// ── Equipment type constants ──────────────────────────────────────────────────

const _kFreeWeight = 'Szabadsúly';
const _kMachine = 'Gép';
const _kBodyweight = 'Testsúly';
const _equipmentOptions = [_kFreeWeight, _kMachine, _kBodyweight];

String _guessEquipment(String? backendEquipment) {
  final e = (backendEquipment ?? '').toLowerCase();
  if (e.contains('body') || e.contains('test')) return _kBodyweight;
  if (e.contains('machine') || e.contains('gép') || e.contains('kabel') || e.contains('cable')) return _kMachine;
  return _kFreeWeight;
}

// ── Data class ────────────────────────────────────────────────────────────────

class _BuilderExercise {
  final String exerciseId;
  final String name;
  final String muscleGroup;
  String equipmentType;
  int sets;
  int? targetReps;
  double? targetWeightKg;
  // Filled after athlete selection
  double? prevWeightKg;
  int? prevReps;

  _BuilderExercise({
    required this.exerciseId,
    required this.name,
    required this.muscleGroup,
    required this.equipmentType,
    this.sets = 3,
    this.targetReps,
    this.targetWeightKg,
    this.prevWeightKg,
    this.prevReps,
  });
}

// ── Page ──────────────────────────────────────────────────────────────────────

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

  final List<_BuilderExercise> _exercises = [];
  List<AthleteModel> _athletes = [];
  List<ExerciseModel> _exerciseLibrary = [];

  // exerciseName.toLowerCase() → {prevWeightKg, prevReps}
  Map<String, ({double? weight, int? reps})> _prevData = {};

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isFetchingPrev = false;

  @override
  void initState() {
    super.initState();
    _selectedAthleteId = widget.preselectedAthleteId;
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
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
      // Most recent workouts first — earlier entries won't overwrite later ones
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
    if (id != null) _fetchPreviousData(id);
  }

  void _addExercise(ExerciseModel lib) {
    final equip = _guessEquipment(lib.equipment);
    final prev = _prevData[lib.name.toLowerCase()];
    setState(() {
      _exercises.add(_BuilderExercise(
        exerciseId: lib.id,
        name: lib.name,
        muscleGroup: lib.muscleGroup,
        equipmentType: equip,
        sets: 3,
        prevWeightKg: prev?.weight,
        prevReps: prev?.reps,
      ));
    });
    Navigator.of(context).pop();
  }

  void _addCustomExercise(String name, String muscleGroup, String equip) {
    final prev = _prevData[name.toLowerCase()];
    setState(() {
      _exercises.add(_BuilderExercise(
        exerciseId: '',
        name: name,
        muscleGroup: muscleGroup,
        equipmentType: equip,
        sets: 3,
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
      backgroundColor: DT.gbWhite,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(DT.rCard))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, ctrl) => _ExercisePicker(
          library: _exerciseLibrary,
          scrollController: ctrl,
          onSelect: _addExercise,
          onCustom: _addCustomExercise,
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
        final isBodyweight = ex.equipmentType == _kBodyweight;
        return {
          if (ex.exerciseId.isNotEmpty) 'exerciseId': ex.exerciseId,
          'name': ex.name,
          'index': e.key,
          'sets': ex.sets,
          'targetReps': ex.targetReps ?? 0,
          'targetWeightKg': isBodyweight ? 0.0 : (ex.targetWeightKg ?? 0.0),
          'equipmentType': ex.equipmentType,
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
    return Scaffold(
      backgroundColor: DT.bg,
      appBar: AppBar(
        backgroundColor: DT.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: DT.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Edzés összeállítása',
            style: TextStyle(
                color: DT.textPrimary,
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
                // ── Workout name ──────────────────────────────────────────────
                _SectionLabel('Edzés neve'),
                _WhiteCard(
                  child: TextField(
                    controller: _titleCtrl,
                    style: const TextStyle(
                        fontSize: DT.s4,
                        fontWeight: FontWeight.w600,
                        color: DT.textPrimary),
                    decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: DT.s4, vertical: DT.s3)),
                  ),
                ),
                const SizedBox(height: DT.s4),

                // ── Difficulty ────────────────────────────────────────────────
                _SectionLabel('Nehézségi szint'),
                _DifficultySelector(
                    selected: _difficulty,
                    onChanged: (d) => setState(() => _difficulty = d)),
                const SizedBox(height: DT.s4),

                // ── Athlete ───────────────────────────────────────────────────
                _SectionLabel('Sportoló'),
                if (_athletes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(DT.s3),
                    child: Text('Nincs hozzárendelt sportoló.',
                        style: TextStyle(color: DT.textSecondary)),
                  )
                else
                  _AthleteSelector(
                    athletes: _athletes,
                    selectedId: _selectedAthleteId,
                    isFetchingPrev: _isFetchingPrev,
                    onChanged: _onAthleteChanged,
                  ),
                const SizedBox(height: DT.s4),

                // ── Date ──────────────────────────────────────────────────────
                _SectionLabel('Dátum'),
                GestureDetector(
                  onTap: _pickDate,
                  child: _WhiteCard(
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: DT.metricBlue, size: 20),
                        const SizedBox(width: DT.s3),
                        Text(DateFormat('yyyy.MM.dd').format(_date),
                            style: const TextStyle(
                                fontSize: DT.s4,
                                fontWeight: FontWeight.w600,
                                color: DT.textPrimary)),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios,
                            size: 14, color: DT.textGrey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: DT.s4),

                // ── Notes ─────────────────────────────────────────────────────
                _SectionLabel('Megjegyzés (opcionális)'),
                _WhiteCard(
                  child: TextField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    style: const TextStyle(
                        fontSize: DT.s3, color: DT.textPrimary),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Pl. fókuszálj a technikára…',
                      hintStyle: TextStyle(color: DT.textGrey),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: DT.s4, vertical: DT.s3),
                    ),
                  ),
                ),
                const SizedBox(height: DT.s5),

                // ── Exercises ─────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Gyakorlatok',
                        style: TextStyle(
                            fontSize: DT.s4,
                            fontWeight: FontWeight.w700,
                            color: DT.textPrimary)),
                    Text('${_exercises.length} db',
                        style: const TextStyle(
                            fontSize: DT.s3, color: DT.textSecondary)),
                  ],
                ),
                const SizedBox(height: DT.s3),

                ..._exercises.asMap().entries.map((entry) =>
                    _ExerciseBuilderCard(
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
                      color: DT.gbWhite,
                      borderRadius: BorderRadius.circular(DT.rCardSmall),
                      border: Border.all(color: DT.borderGrey, width: 1.5),
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

// ── Exercise card ─────────────────────────────────────────────────────────────

class _ExerciseBuilderCard extends StatefulWidget {
  final _BuilderExercise exercise;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _ExerciseBuilderCard({
    super.key,
    required this.exercise,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_ExerciseBuilderCard> createState() => _ExerciseBuilderCardState();
}

class _ExerciseBuilderCardState extends State<_ExerciseBuilderCard> {
  late TextEditingController _repsCtrl;
  late TextEditingController _weightCtrl;

  @override
  void initState() {
    super.initState();
    _repsCtrl = TextEditingController(
        text: widget.exercise.targetReps?.toString() ?? '');
    _weightCtrl = TextEditingController(
        text: widget.exercise.targetWeightKg?.toString() ?? '');
  }

  @override
  void dispose() {
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  bool get _isBodyweight => widget.exercise.equipmentType == _kBodyweight;

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    final hasPrev = ex.prevWeightKg != null || ex.prevReps != null;

    return Container(
      margin: const EdgeInsets.only(bottom: DT.s4),
      decoration: BoxDecoration(
        color: DT.gbWhite,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        boxShadow: const [
          BoxShadow(
              color: DT.shadowLight, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(DT.s4, DT.s3, DT.s2, DT.s2),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ex.name,
                          style: const TextStyle(
                              fontSize: DT.s4,
                              fontWeight: FontWeight.w700,
                              color: DT.textPrimary)),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: DT.s2, vertical: 2),
                        decoration: BoxDecoration(
                          color: DT.metricBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(ex.muscleGroup,
                            style: const TextStyle(
                                fontSize: 11,
                                color: DT.metricBlue,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.delete_outline, color: DT.cardRed),
                    onPressed: widget.onRemove),
              ],
            ),
          ),

          // Equipment type
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: DT.s4, vertical: DT.s2),
            child: Row(
              children: _equipmentOptions.map((opt) {
                final selected = ex.equipmentType == opt;
                return Padding(
                  padding: const EdgeInsets.only(right: DT.s2),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => ex.equipmentType = opt);
                      widget.onChanged();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: DT.s3, vertical: DT.s1),
                      decoration: BoxDecoration(
                        color: selected
                            ? DT.metricBlue
                            : DT.bg,
                        borderRadius:
                            BorderRadius.circular(DT.rCardSmall),
                        border: Border.all(
                            color: selected
                                ? DT.metricBlue
                                : DT.borderGrey),
                      ),
                      child: Text(opt,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : DT.textSecondary)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Sets / Reps / Weight row
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: DT.s4, vertical: DT.s3),
            decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: DT.borderLight))),
            child: Row(
              children: [
                // Sets stepper
                Column(
                  children: [
                    const Text('Sorozat',
                        style: TextStyle(
                            fontSize: 11, color: DT.textSecondary)),
                    const SizedBox(height: DT.s1),
                    Row(
                      children: [
                        _StepBtn(
                          icon: Icons.remove,
                          onTap: ex.sets > 1
                              ? () {
                                  setState(() => ex.sets--);
                                  widget.onChanged();
                                }
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: DT.s2),
                          child: Text('${ex.sets}',
                              style: const TextStyle(
                                  fontSize: DT.s4,
                                  fontWeight: FontWeight.w700,
                                  color: DT.textPrimary)),
                        ),
                        _StepBtn(
                          icon: Icons.add,
                          onTap: () {
                            setState(() => ex.sets++);
                            widget.onChanged();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: DT.s4),

                // Reps
                Expanded(
                  child: Column(
                    children: [
                      const Text('Ismétlés',
                          style: TextStyle(
                              fontSize: 11, color: DT.textSecondary)),
                      const SizedBox(height: DT.s1),
                      _NumField(
                        controller: _repsCtrl,
                        hint: '10',
                        isDecimal: false,
                        onChanged: (v) {
                          ex.targetReps = int.tryParse(v);
                          widget.onChanged();
                        },
                      ),
                    ],
                  ),
                ),

                // Weight (hidden for bodyweight)
                if (!_isBodyweight) ...[
                  const SizedBox(width: DT.s3),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Súly (kg)',
                            style: TextStyle(
                                fontSize: 11, color: DT.textSecondary)),
                        const SizedBox(height: DT.s1),
                        _NumField(
                          controller: _weightCtrl,
                          hint: '0',
                          isDecimal: true,
                          onChanged: (v) {
                            ex.targetWeightKg = double.tryParse(v);
                            widget.onChanged();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Previous data hint
          if (hasPrev)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: DT.s4, vertical: DT.s2),
              decoration: BoxDecoration(
                color: DT.metricGreen,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(DT.rCardSmall),
                  bottomRight: Radius.circular(DT.rCardSmall),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history, size: 14, color: DT.textSecondary),
                  const SizedBox(width: DT.s1),
                  Text(
                    _prevText(ex),
                    style: const TextStyle(
                        fontSize: 11,
                        color: DT.textSecondary,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _prevText(_BuilderExercise ex) {
    final w = ex.prevWeightKg;
    final r = ex.prevReps;
    if (w != null && r != null) {
      final wStr = w == w.roundToDouble() ? w.toInt().toString() : w.toStringAsFixed(1);
      return 'Előző: $wStr kg × $r ism.';
    }
    if (r != null) return 'Előző: $r ismétlés';
    if (w != null) {
      final wStr = w == w.roundToDouble() ? w.toInt().toString() : w.toStringAsFixed(1);
      return 'Előző: $wStr kg';
    }
    return '';
  }
}

// ── Exercise picker ───────────────────────────────────────────────────────────

class _ExercisePicker extends StatefulWidget {
  final List<ExerciseModel> library;
  final ScrollController scrollController;
  final ValueChanged<ExerciseModel> onSelect;
  final void Function(String name, String muscleGroup, String equip) onCustom;

  const _ExercisePicker({
    required this.library,
    required this.scrollController,
    required this.onSelect,
    required this.onCustom,
  });

  @override
  State<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<_ExercisePicker> {
  String _query = '';
  bool _showCustom = false;
  final _customNameCtrl = TextEditingController();
  String _customMuscle = 'Mellizom';
  String _customEquip = _kFreeWeight;

  static const _muscles = [
    'Mellizom', 'Hátizom', 'Vállizom', 'Bicepsz', 'Tricepsz',
    'Hasizom', 'Lábizom', 'Farizom', 'Vádli', 'Egyéb'
  ];

  @override
  void dispose() {
    _customNameCtrl.dispose();
    super.dispose();
  }

  List<ExerciseModel> get _filtered {
    if (_query.isEmpty) return widget.library;
    final q = _query.toLowerCase();
    return widget.library
        .where((e) =>
            e.name.toLowerCase().contains(q) ||
            e.muscleGroup.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle bar
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: DT.s3),
            decoration: BoxDecoration(
                color: DT.borderGrey, borderRadius: BorderRadius.circular(2)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(DT.s4, DT.s3, DT.s4, DT.s2),
          child: Row(
            children: [
              const Expanded(
                child: Text('Gyakorlat választása',
                    style: TextStyle(
                        fontSize: DT.s4,
                        fontWeight: FontWeight.w700,
                        color: DT.textPrimary)),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _showCustom = !_showCustom),
                icon: Icon(_showCustom ? Icons.list : Icons.add,
                    size: 16, color: DT.metricBlue),
                label: Text(_showCustom ? 'Lista' : 'Egyedi',
                    style: const TextStyle(color: DT.metricBlue, fontSize: DT.s3)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
            ],
          ),
        ),

        if (_showCustom)
          _CustomExerciseForm(
            nameCtrl: _customNameCtrl,
            muscles: _muscles,
            selectedMuscle: _customMuscle,
            selectedEquip: _customEquip,
            onMuscleChanged: (m) => setState(() => _customMuscle = m),
            onEquipChanged: (e) => setState(() => _customEquip = e),
            onAdd: () {
              if (_customNameCtrl.text.trim().isEmpty) return;
              widget.onCustom(
                _customNameCtrl.text.trim(),
                _customMuscle,
                _customEquip,
              );
            },
          )
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(DT.s4, 0, DT.s4, DT.s3),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Keresés…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: DT.bg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DT.rCardSmall),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: DT.s3),
              ),
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text('Nem található.',
                        style: TextStyle(
                            color: DT.textSecondary, fontSize: DT.s4)))
                : ListView.separated(
                    controller: widget.scrollController,
                    padding: const EdgeInsets.fromLTRB(
                        DT.s4, 0, DT.s4, DT.s5),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: DT.borderLight),
                    itemBuilder: (_, i) {
                      final ex = _filtered[i];
                      return ListTile(
                        onTap: () => widget.onSelect(ex),
                        title: Text(ex.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: DT.textPrimary,
                                fontSize: DT.s3)),
                        subtitle: Text(
                            '${ex.muscleGroup}${ex.equipment != null ? ' · ${ex.equipment}' : ''}',
                            style: const TextStyle(
                                color: DT.textSecondary, fontSize: 11)),
                        trailing: const Icon(Icons.add_circle,
                            color: DT.metricBlue),
                        contentPadding: EdgeInsets.zero,
                      );
                    },
                  ),
          ),
        ],
      ],
    );
  }
}

class _CustomExerciseForm extends StatelessWidget {
  final TextEditingController nameCtrl;
  final List<String> muscles;
  final String selectedMuscle;
  final String selectedEquip;
  final ValueChanged<String> onMuscleChanged;
  final ValueChanged<String> onEquipChanged;
  final VoidCallback onAdd;

  const _CustomExerciseForm({
    required this.nameCtrl,
    required this.muscles,
    required this.selectedMuscle,
    required this.selectedEquip,
    required this.onMuscleChanged,
    required this.onEquipChanged,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DT.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: nameCtrl,
            style: const TextStyle(color: DT.textPrimary),
            decoration: InputDecoration(
              hintText: 'Gyakorlat neve',
              hintStyle: const TextStyle(color: DT.textSecondary),
              filled: true,
              fillColor: DT.bg,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DT.rCardSmall),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: DT.s3),
          const Text('Izomcsoport',
              style: TextStyle(color: DT.textSecondary, fontSize: DT.s3)),
          const SizedBox(height: DT.s2),
          Wrap(
            spacing: DT.s2,
            runSpacing: DT.s1,
            children: muscles
                .map((m) => GestureDetector(
                      onTap: () => onMuscleChanged(m),
                      child: _Chip(
                          label: m, selected: m == selectedMuscle),
                    ))
                .toList(),
          ),
          const SizedBox(height: DT.s3),
          const Text('Felszerelés',
              style: TextStyle(color: DT.textSecondary, fontSize: DT.s3)),
          const SizedBox(height: DT.s2),
          Row(
            children: _equipmentOptions
                .map((e) => Padding(
                      padding: const EdgeInsets.only(right: DT.s2),
                      child: GestureDetector(
                        onTap: () => onEquipChanged(e),
                        child: _Chip(
                            label: e, selected: e == selectedEquip),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: DT.s4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: DT.metricBlue,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(DT.rCardSmall)),
              ),
              child: const Text('Hozzáadás',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: DT.s4),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  const _Chip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: DT.s2, vertical: DT.s1),
      decoration: BoxDecoration(
        color: selected ? DT.metricBlue : DT.bg,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        border: Border.all(
            color: selected ? DT.metricBlue : DT.borderGrey),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : DT.textSecondary)),
    );
  }
}

// ── Shared UI helpers ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: DT.s2),
        child: Text(text,
            style: const TextStyle(
                fontSize: DT.s3,
                fontWeight: FontWeight.w600,
                color: DT.textSecondary)),
      );
}

class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: DT.gbWhite,
            borderRadius: BorderRadius.circular(DT.rCardSmall)),
        child: child,
      );
}

class _DifficultySelector extends StatelessWidget {
  final WorkoutDifficulty selected;
  final ValueChanged<WorkoutDifficulty> onChanged;
  const _DifficultySelector(
      {required this.selected, required this.onChanged});

  static const _opts = [
    (WorkoutDifficulty.easy, 'Könnyű', DT.difficultyLight),
    (WorkoutDifficulty.moderate, 'Közepes', DT.difficultyMedium),
    (WorkoutDifficulty.hard, 'Nehéz', DT.difficultyHard),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _opts.map((opt) {
        final isSelected = opt.$1 == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(opt.$1),
            child: Container(
              margin: EdgeInsets.only(
                  right: opt.$1 == WorkoutDifficulty.hard ? 0 : DT.s2),
              padding:
                  const EdgeInsets.symmetric(vertical: DT.s3),
              decoration: BoxDecoration(
                color: isSelected ? opt.$3 : DT.gbWhite,
                borderRadius:
                    BorderRadius.circular(DT.rCardSmall),
                border: Border.all(
                    color: isSelected ? opt.$3 : DT.borderGrey,
                    width: 2),
              ),
              child: Text(opt.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: DT.s3,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : DT.textSecondary)),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AthleteSelector extends StatelessWidget {
  final List<AthleteModel> athletes;
  final String? selectedId;
  final bool isFetchingPrev;
  final ValueChanged<String?> onChanged;

  const _AthleteSelector({
    required this.athletes,
    required this.selectedId,
    required this.isFetchingPrev,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DT.s4),
      decoration: BoxDecoration(
          color: DT.gbWhite,
          borderRadius: BorderRadius.circular(DT.rCardSmall)),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedId,
                hint: const Text('Válassz sportolót…',
                    style: TextStyle(color: DT.textSecondary)),
                isExpanded: true,
                items: athletes
                    .map((a) => DropdownMenuItem(
                        value: a.id, child: Text(a.fullName)))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
          if (isFetchingPrev)
            const Padding(
              padding: EdgeInsets.only(left: DT.s2),
              child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: onTap != null ? DT.metricBlue.withValues(alpha: 0.1) : DT.bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: onTap != null ? DT.metricBlue : DT.borderGrey),
        ),
        child: Icon(icon,
            size: 16,
            color: onTap != null ? DT.metricBlue : DT.textGrey),
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isDecimal;
  final ValueChanged<String> onChanged;

  const _NumField({
    required this.controller,
    required this.hint,
    required this.isDecimal,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
      textAlign: TextAlign.center,
      style: const TextStyle(
          fontSize: DT.s4,
          fontWeight: FontWeight.w600,
          color: DT.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: DT.textGrey),
        filled: true,
        fillColor: DT.bg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DT.rCardSmall),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(vertical: DT.s2),
        isDense: true,
      ),
      onChanged: onChanged,
    );
  }
}
