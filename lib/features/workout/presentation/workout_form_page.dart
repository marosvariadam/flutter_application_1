import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/exercise/data/models/exercise_model.dart';
import 'package:flutter_application_1/features/trainer/data/models/trainer_request_model.dart';
import 'package:flutter_application_1/features/trainer/data/repositories/roster_repository.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';
import 'package:flutter_application_1/features/workout/data/repositories/workout_repository.dart';

class WorkoutFormPage extends StatefulWidget {
  final String? workoutId; // null = create; non-null = edit
  const WorkoutFormPage({super.key, this.workoutId});

  @override
  State<WorkoutFormPage> createState() => _WorkoutFormPageState();
}

class _WorkoutFormPageState extends State<WorkoutFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  WorkoutDifficulty _difficulty = WorkoutDifficulty.moderate;
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedAthleteId;
  String? _selectedAthleteName;
  List<AthleteModel> _athletes = [];
  List<_ExerciseEntry> _exercises = [];
  bool _loading = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAthletes();
    if (widget.workoutId != null) _loadExistingWorkout();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAthletes() async {
    setState(() => _loading = true);
    try {
      final result =
          await context.read<RosterRepository>().getAthletes();
      setState(() => _athletes = result.items);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadExistingWorkout() async {
    try {
      final w = await context
          .read<WorkoutRepository>()
          .getWorkout(widget.workoutId!);
      setState(() {
        _titleCtrl.text = w.title;
        _notesCtrl.text = w.notes ?? '';
        _difficulty = w.difficulty;
        _scheduledDate = w.scheduledDate;
        _selectedAthleteId = w.athleteId;
        _selectedAthleteName = w.athleteName;
        _exercises = w.exercises
            .map((e) => _ExerciseEntry(
                  exerciseId: e.exerciseId,
                  name: e.name,
                  sets: e.sets,
                  targetReps: e.targetReps,
                  targetWeightKg: e.targetWeightKg,
                  instructions: e.instructions,
                ))
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _scheduledDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAthleteId == null) {
      setState(() => _error = 'Válassz sportolót!');
      return;
    }
    if (_exercises.isEmpty) {
      setState(() => _error = 'Adj hozzá legalább egy gyakorlatot!');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final exerciseData = _exercises
          .map((e) => {
                'exerciseId': e.exerciseId,
                'name': e.name,
                'sets': e.sets,
                'targetReps': e.targetReps,
                'targetWeightKg': e.targetWeightKg,
                if (e.instructions != null)
                  'instructions': e.instructions,
              })
          .toList();

      final repo = context.read<WorkoutRepository>();
      if (widget.workoutId != null) {
        await repo.updateWorkout(
          widget.workoutId!,
          title: _titleCtrl.text.trim(),
          difficulty: _difficulty,
          scheduledDate: _scheduledDate,
          notes: _notesCtrl.text.trim().isEmpty
              ? null
              : _notesCtrl.text.trim(),
          exercises: exerciseData,
        );
      } else {
        await repo.createWorkout(
          title: _titleCtrl.text.trim(),
          athleteId: _selectedAthleteId!,
          difficulty: _difficulty,
          scheduledDate: _scheduledDate,
          notes: _notesCtrl.text.trim().isEmpty
              ? null
              : _notesCtrl.text.trim(),
          exercises: exerciseData,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.workoutId != null
                  ? 'Edzés frissítve!'
                  : 'Edzés létrehozva!')),
        );
        context.pop();
      }
    } catch (_) {
      setState(() => _error = 'Nem sikerült menteni az edzést.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.of(context).bg,
      appBar: AppBar(
        backgroundColor: DT.of(context).bg,
        elevation: 0,
        leading: BackButton(color: DT.of(context).textPrimary),
        title: Text(
            widget.workoutId != null ? 'Edzés szerkesztése' : 'Új edzés',
            style: TextStyle(
                color: DT.of(context).textPrimary, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(DT.s5),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Edzés neve',
                        prefixIcon: Icon(Icons.fitness_center_outlined),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Kötelező' : null,
                    ),
                    const SizedBox(height: DT.s3),
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Megjegyzések (opcionális)',
                        prefixIcon: Icon(Icons.notes),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: DT.s4),
                    Text('Nehézség',
                        style: TextStyle(
                            color: DT.of(context).textSecondary,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: DT.s2),
                    Wrap(
                      spacing: DT.s2,
                      children: WorkoutDifficulty.values
                          .map((d) => ChoiceChip(
                                label: Text(d.label),
                                selected: _difficulty == d,
                                onSelected: (_) =>
                                    setState(() => _difficulty = d),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: DT.s4),
                    ListTile(
                      onTap: _pickDate,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: Text(
                        '${_scheduledDate.year}. ${_scheduledDate.month}. ${_scheduledDate.day}.',
                        style: TextStyle(color: DT.of(context).textPrimary),
                      ),
                      subtitle: Text('Tervezett dátum',
                          style: TextStyle(
                              color: DT.of(context).textSecondary, fontSize: DT.s3)),
                    ),
                    const SizedBox(height: DT.s4),
                    if (widget.workoutId == null) ...[
                      Text('Sportoló',
                          style: TextStyle(
                              color: DT.of(context).textSecondary,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: DT.s2),
                      DropdownButtonFormField<String>(
                        value: _selectedAthleteId,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        items: _athletes
                            .map((a) => DropdownMenuItem(
                                  value: a.id,
                                  child: Text(a.fullName),
                                ))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedAthleteId = v;
                            _selectedAthleteName = _athletes
                                .firstWhere((a) => a.id == v)
                                .fullName;
                          });
                        },
                        hint: const Text('Válassz sportolót'),
                      ),
                      const SizedBox(height: DT.s5),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Gyakorlatok',
                            style: TextStyle(
                                color: DT.of(context).textPrimary,
                                fontSize: DT.s4,
                                fontWeight: FontWeight.w700)),
                        TextButton.icon(
                          onPressed: () =>
                              _showAddExerciseDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Hozzáad'),
                        ),
                      ],
                    ),
                    const SizedBox(height: DT.s3),
                    ..._exercises.asMap().entries.map((entry) {
                      final i = entry.key;
                      final e = entry.value;
                      return _ExerciseFormCard(
                        key: ValueKey('exercise_$i'),
                        entry: e,
                        onDelete: () =>
                            setState(() => _exercises.removeAt(i)),
                        onChanged: (updated) {
                          setState(() => _exercises[i] = updated);
                        },
                      );
                    }),
                    if (_error != null) ...[
                      const SizedBox(height: DT.s3),
                      Text(_error!,
                          style: const TextStyle(
                              color: DT.cardRed, fontSize: DT.s3)),
                    ],
                    const SizedBox(height: DT.s6),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DT.metricBlue,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(DT.rCardSmall)),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Mentés',
                                style: TextStyle(
                                    color: DT.textWhite,
                                    fontSize: DT.s4,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: DT.s5),
                  ],
                ),
              ),
            ),
    );
  }

  void _showAddExerciseDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final setsCtrl = TextEditingController(text: '3');
    final repsCtrl = TextEditingController(text: '10');
    final weightCtrl = TextEditingController(text: '0');
    final instrCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DT.gbWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: DT.s5,
          right: DT.s5,
          top: DT.s5,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + DT.s5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gyakorlat hozzáadása',
                style: TextStyle(
                    fontSize: DT.s5,
                    fontWeight: FontWeight.w700,
                    color: DT.of(context).textPrimary)),
            const SizedBox(height: DT.s4),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Gyakorlat neve'),
                  ),
                ),
                const SizedBox(width: DT.s2),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final result = await context.push<ExerciseModel>(
                        '/exercise-catalogue');
                    if (result != null) {
                      setState(() {
                        _exercises.add(_ExerciseEntry(
                          exerciseId: result.id,
                          name: result.name,
                          sets: 3,
                          targetReps: 10,
                          targetWeightKg: 0,
                        ));
                      });
                    }
                  },
                  child: const Text('Katalógus'),
                ),
              ],
            ),
            const SizedBox(height: DT.s3),
            Row(
              children: [
                Expanded(
                    child: TextField(
                        controller: setsCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Sorozat'))),
                const SizedBox(width: DT.s2),
                Expanded(
                    child: TextField(
                        controller: repsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Ismétlés'))),
                const SizedBox(width: DT.s2),
                Expanded(
                    child: TextField(
                        controller: weightCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                        decoration:
                            const InputDecoration(labelText: 'Súly'))),
              ],
            ),
            const SizedBox(height: DT.s3),
            TextField(
              controller: instrCtrl,
              decoration: const InputDecoration(
                  labelText: 'Utasítások (opcionális)'),
            ),
            const SizedBox(height: DT.s4),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  setState(() {
                    _exercises.add(_ExerciseEntry(
                      exerciseId:
                          'custom_${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      sets: int.tryParse(setsCtrl.text) ?? 3,
                      targetReps: int.tryParse(repsCtrl.text) ?? 10,
                      targetWeightKg:
                          double.tryParse(weightCtrl.text) ?? 0,
                      instructions: instrCtrl.text.trim().isEmpty
                          ? null
                          : instrCtrl.text.trim(),
                    ));
                  });
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: DT.metricBlue),
                child: const Text('Hozzáadás',
                    style: TextStyle(color: DT.textWhite)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseEntry {
  String exerciseId;
  String name;
  int sets;
  int targetReps;
  double targetWeightKg;
  String? instructions;

  _ExerciseEntry({
    required this.exerciseId,
    required this.name,
    required this.sets,
    required this.targetReps,
    required this.targetWeightKg,
    this.instructions,
  });
}

class _ExerciseFormCard extends StatelessWidget {
  final _ExerciseEntry entry;
  final VoidCallback onDelete;
  final void Function(_ExerciseEntry) onChanged;

  const _ExerciseFormCard({
    super.key,
    required this.entry,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DT.s3),
      padding: const EdgeInsets.all(DT.s3),
      decoration: BoxDecoration(
        color: DT.gbWhite,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name,
                    style: TextStyle(
                        color: DT.of(context).textPrimary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                    '${entry.sets} × ${entry.targetReps} ism. @ ${entry.targetWeightKg} kg',
                    style: TextStyle(
                        color: DT.of(context).textSecondary, fontSize: DT.s3)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: DT.cardRed),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
