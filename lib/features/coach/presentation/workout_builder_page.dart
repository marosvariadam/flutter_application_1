import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/coach/data/models/athlete_model.dart';
import 'package:flutter_application_1/services/athlete_service.dart';
import 'package:flutter_application_1/services/workout_service.dart';
import 'package:intl/intl.dart';

class WorkoutBuilderPage extends StatefulWidget {
  final String? preselectedAthleteId;
  const WorkoutBuilderPage({super.key, this.preselectedAthleteId});
  @override
  State<WorkoutBuilderPage> createState() => _WorkoutBuilderPageState();
}

class _WorkoutBuilderPageState extends State<WorkoutBuilderPage> {
  final _titleController = TextEditingController(text: 'Új edzés');
  String _difficulty = 'Közepes';
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  String? _selectedAthleteId;
  final List<_BuilderExercise> _exercises = [];
  List<AthleteModel> _athletes = [];
  List<Map<String, String>> _exerciseLibrary = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedAthleteId = widget.preselectedAthleteId;
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      AthleteService().getMyAthletes(),
      WorkoutService().getExerciseLibrary(),
    ]);
    if (!mounted) return;
    setState(() {
      _athletes = results[0] as List<AthleteModel>;
      _exerciseLibrary = results[1] as List<Map<String, String>>;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _addExercise(Map<String, String> lib) {
    setState(() {
      _exercises.add(_BuilderExercise(name: lib['name']!, category: lib['category']!, sets: [_BuilderSet(weight: null, reps: null)]));
    });
    Navigator.of(context).pop();
  }

  void _removeExercise(int index) => setState(() => _exercises.removeAt(index));

  void _addSet(int exerciseIndex) {
    setState(() { _exercises[exerciseIndex].sets.add(_BuilderSet(weight: null, reps: null)); });
  }

  void _removeSet(int exerciseIndex, int setIndex) {
    setState(() {
      if (_exercises[exerciseIndex].sets.length > 1) _exercises[exerciseIndex].sets.removeAt(setIndex);
    });
  }

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
    if (_exerciseLibrary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nem található adat')));
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: DT.gbWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(DT.rCard))),
      builder: (_) => _ExercisePicker(library: _exerciseLibrary, onSelect: _addExercise),
    );
  }

  void _save() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adj meg egy edzés nevet!')));
      return;
    }
    if (_selectedAthleteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Válassz atléta!')));
      return;
    }
    // TODO: call WorkoutService().createWorkout(...)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edzés elmentve: ${_titleController.text}'), backgroundColor: DT.difficultyLight),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.bg,
      appBar: AppBar(
        backgroundColor: DT.bg,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: DT.textPrimary), onPressed: () => Navigator.of(context).pop()),
        title: const Text('Edzés összeállítása', style: TextStyle(color: DT.textPrimary, fontSize: DT.s4, fontWeight: FontWeight.w600)),
        actions: [TextButton(onPressed: _save, child: const Text('Mentés', style: TextStyle(color: DT.metricBlue, fontWeight: FontWeight.w700, fontSize: DT.s4)))],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(DT.s5),
              children: [
                _SectionLabel('Edzés neve'),
                Container(
                  decoration: BoxDecoration(color: DT.gbWhite, borderRadius: BorderRadius.circular(DT.rCardSmall)),
                  child: TextField(
                    controller: _titleController,
                    style: const TextStyle(fontSize: DT.s4, fontWeight: FontWeight.w600, color: DT.textPrimary),
                    decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: DT.s4, vertical: DT.s3)),
                  ),
                ),
                const SizedBox(height: DT.s4),
                _SectionLabel('Nehézségi szint'),
                _DifficultySelector(selected: _difficulty, onChanged: (d) => setState(() => _difficulty = d)),
                const SizedBox(height: DT.s4),
                _SectionLabel('Atléta'),
                if (_athletes.isEmpty)
                  const Padding(padding: EdgeInsets.all(DT.s3), child: Text('Nem található adat', style: TextStyle(color: DT.textSecondary)))
                else
                  _AthleteSelector(athletes: _athletes, selectedId: _selectedAthleteId, onChanged: (id) => setState(() => _selectedAthleteId = id)),
                const SizedBox(height: DT.s4),
                _SectionLabel('Dátum'),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.all(DT.s4),
                    decoration: BoxDecoration(color: DT.gbWhite, borderRadius: BorderRadius.circular(DT.rCardSmall)),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: DT.metricBlue, size: 20),
                        const SizedBox(width: DT.s3),
                        Text(DateFormat('yyyy.MM.dd').format(_date), style: const TextStyle(fontSize: DT.s4, fontWeight: FontWeight.w600, color: DT.textPrimary)),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: DT.textGrey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: DT.s5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Gyakorlatok', style: TextStyle(fontSize: DT.s4, fontWeight: FontWeight.w700, color: DT.textPrimary)),
                    Text('${_exercises.length} db', style: const TextStyle(fontSize: DT.s3, color: DT.textSecondary)),
                  ],
                ),
                const SizedBox(height: DT.s3),
                ..._exercises.asMap().entries.map(
                  (entry) => _ExerciseBuilderCard(
                    index: entry.key,
                    exercise: entry.value,
                    onRemove: () => _removeExercise(entry.key),
                    onAddSet: () => _addSet(entry.key),
                    onRemoveSet: (si) => _removeSet(entry.key, si),
                    onWeightChanged: (si, val) => setState(() => _exercises[entry.key].sets[si].weight = val),
                    onRepsChanged: (si, val) => setState(() => _exercises[entry.key].sets[si].reps = val),
                  ),
                ),
                const SizedBox(height: DT.s3),
                GestureDetector(
                  onTap: _showExercisePicker,
                  child: Container(
                    padding: const EdgeInsets.all(DT.s4),
                    decoration: BoxDecoration(color: DT.gbWhite, borderRadius: BorderRadius.circular(DT.rCardSmall), border: Border.all(color: DT.borderGrey, width: 1.5)),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, color: DT.metricBlue),
                        SizedBox(width: DT.s2),
                        Text('Gyakorlat hozzáadása', style: TextStyle(color: DT.metricBlue, fontWeight: FontWeight.w600, fontSize: DT.s4)),
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DT.s2),
      child: Text(text, style: const TextStyle(fontSize: DT.s3, fontWeight: FontWeight.w600, color: DT.textSecondary)),
    );
  }
}

class _DifficultySelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _DifficultySelector({required this.selected, required this.onChanged});
  static const _options = [('Könnyű', DT.difficultyLight), ('Közepes', DT.difficultyMedium), ('Nehéz', DT.difficultyHard)];
  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((opt) {
        final isSelected = opt.$1 == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(opt.$1),
            child: Container(
              margin: EdgeInsets.only(right: opt.$1 == 'Nehéz' ? 0 : DT.s2),
              padding: const EdgeInsets.symmetric(vertical: DT.s3),
              decoration: BoxDecoration(
                color: isSelected ? opt.$2 : DT.gbWhite,
                borderRadius: BorderRadius.circular(DT.rCardSmall),
                border: Border.all(color: isSelected ? opt.$2 : DT.borderGrey, width: 2),
              ),
              child: Text(opt.$1, textAlign: TextAlign.center, style: TextStyle(fontSize: DT.s3, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : DT.textSecondary)),
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
  final ValueChanged<String?> onChanged;
  const _AthleteSelector({required this.athletes, required this.selectedId, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DT.s4),
      decoration: BoxDecoration(color: DT.gbWhite, borderRadius: BorderRadius.circular(DT.rCardSmall)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedId,
          hint: const Text('Válassz atléta…', style: TextStyle(color: DT.textSecondary)),
          isExpanded: true,
          items: athletes.map((a) => DropdownMenuItem(value: a.id, child: Text(a.fullName))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _BuilderExercise {
  String name;
  String category;
  List<_BuilderSet> sets;
  _BuilderExercise({required this.name, required this.category, required this.sets});
}

class _BuilderSet {
  double? weight;
  int? reps;
  _BuilderSet({this.weight, this.reps});
}

class _ExerciseBuilderCard extends StatelessWidget {
  final int index;
  final _BuilderExercise exercise;
  final VoidCallback onRemove;
  final VoidCallback onAddSet;
  final ValueChanged<int> onRemoveSet;
  final void Function(int, double?) onWeightChanged;
  final void Function(int, int?) onRepsChanged;
  const _ExerciseBuilderCard({required this.index, required this.exercise, required this.onRemove, required this.onAddSet, required this.onRemoveSet, required this.onWeightChanged, required this.onRepsChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DT.s4),
      decoration: BoxDecoration(color: DT.gbWhite, borderRadius: BorderRadius.circular(DT.rCardSmall), boxShadow: const [BoxShadow(color: DT.shadowLight, blurRadius: 8, offset: Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(DT.s4, DT.s3, DT.s2, DT.s2),
            child: Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(exercise.name, style: const TextStyle(fontSize: DT.s4, fontWeight: FontWeight.w700, color: DT.textPrimary)),
                  Text(exercise.category, style: const TextStyle(fontSize: DT.s3, color: DT.textSecondary)),
                ])),
                IconButton(icon: const Icon(Icons.delete_outline, color: DT.cardRed), onPressed: onRemove),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: DT.s4, vertical: DT.s2),
            color: DT.bg,
            child: const Row(
              children: [
                SizedBox(width: 36, child: Text('Set', style: TextStyle(fontSize: DT.s3, color: DT.textSecondary, fontWeight: FontWeight.w600))),
                Expanded(child: Text('Súly (kg)', textAlign: TextAlign.center, style: TextStyle(fontSize: DT.s3, color: DT.textSecondary, fontWeight: FontWeight.w600))),
                Expanded(child: Text('Ismétlés', textAlign: TextAlign.center, style: TextStyle(fontSize: DT.s3, color: DT.textSecondary, fontWeight: FontWeight.w600))),
                SizedBox(width: 36),
              ],
            ),
          ),
          ...exercise.sets.asMap().entries.map(
            (entry) => _SetInputRow(
              setNumber: entry.key + 1,
              set: entry.value,
              canRemove: exercise.sets.length > 1,
              onRemove: () => onRemoveSet(entry.key),
              onWeightChanged: (v) => onWeightChanged(entry.key, v),
              onRepsChanged: (v) => onRepsChanged(entry.key, v),
            ),
          ),
          InkWell(
            onTap: onAddSet,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: DT.s3),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: DT.borderLight))),
              child: const Center(child: Text('+ Sorozat hozzáadása', style: TextStyle(color: DT.metricBlue, fontWeight: FontWeight.w600, fontSize: DT.s3))),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetInputRow extends StatelessWidget {
  final int setNumber;
  final _BuilderSet set;
  final bool canRemove;
  final VoidCallback onRemove;
  final ValueChanged<double?> onWeightChanged;
  final ValueChanged<int?> onRepsChanged;
  const _SetInputRow({required this.setNumber, required this.set, required this.canRemove, required this.onRemove, required this.onWeightChanged, required this.onRepsChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DT.s4, vertical: DT.s1),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: DT.borderLight))),
      child: Row(
        children: [
          SizedBox(width: 36, child: Text('$setNumber', style: const TextStyle(fontWeight: FontWeight.w600, color: DT.textPrimary, fontSize: DT.s3))),
          Expanded(child: _NumInput(value: set.weight?.toString() ?? '', hint: '0', onChanged: (v) => onWeightChanged(double.tryParse(v)), isDecimal: true)),
          Expanded(child: _NumInput(value: set.reps?.toString() ?? '', hint: '0', onChanged: (v) => onRepsChanged(int.tryParse(v)), isDecimal: false)),
          SizedBox(
            width: 36,
            child: canRemove
                ? GestureDetector(onTap: onRemove, child: const Icon(Icons.remove_circle_outline, size: 18, color: DT.cardRed))
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _NumInput extends StatelessWidget {
  final String value;
  final String hint;
  final ValueChanged<String> onChanged;
  final bool isDecimal;
  const _NumInput({required this.value, required this.hint, required this.onChanged, required this.isDecimal});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DT.s2),
      child: TextFormField(
        initialValue: value,
        keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: DT.s4, fontWeight: FontWeight.w600, color: DT.textPrimary),
        decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: DT.textGrey), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: DT.s2)),
        onChanged: onChanged,
      ),
    );
  }
}

class _ExercisePicker extends StatefulWidget {
  final List<Map<String, String>> library;
  final ValueChanged<Map<String, String>> onSelect;
  const _ExercisePicker({required this.library, required this.onSelect});
  @override
  State<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<_ExercisePicker> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.library
        : widget.library.where((e) => (e['name'] ?? '').toLowerCase().contains(_query.toLowerCase()) || (e['category'] ?? '').toLowerCase().contains(_query.toLowerCase())).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(DT.s4),
          child: Row(
            children: [
              const Expanded(child: Text('Gyakorlat választása', style: TextStyle(fontSize: DT.s4, fontWeight: FontWeight.w700, color: DT.textPrimary))),
              GestureDetector(onTap: () => Navigator.of(context).pop(), child: const Icon(Icons.close, color: DT.iconLight)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(DT.s4, 0, DT.s4, DT.s3),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Keresés…',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: DT.bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(DT.rCardSmall), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: DT.s3),
            ),
          ),
        ),
        if (filtered.isEmpty)
          const Expanded(child: Center(child: Text('Nem található adat', style: TextStyle(color: DT.textSecondary, fontSize: DT.s4))))
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(DT.s4, 0, DT.s4, DT.s5),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: DT.borderLight),
              itemBuilder: (context, index) {
                final ex = filtered[index];
                return ListTile(
                  onTap: () => widget.onSelect(ex),
                  title: Text(ex['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500, color: DT.textPrimary)),
                  subtitle: Text(ex['category'] ?? '', style: const TextStyle(color: DT.textSecondary)),
                  trailing: const Icon(Icons.add_circle, color: DT.metricBlue),
                  contentPadding: EdgeInsets.zero,
                );
              },
            ),
          ),
      ],
    );
  }
}
