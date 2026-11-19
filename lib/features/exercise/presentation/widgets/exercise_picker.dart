import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/athlete_profile/data/models/athlete_profile_model.dart';
import 'package:flutter_application_1/features/exercise/data/models/exercise_model.dart';
import 'package:flutter_application_1/features/exercise/data/repositories/exercise_repository.dart';

/// Muscle-group filter chips the picker and custom-exercise form share. Keep
/// in sync with the backend seed labels so the filter actually matches.
const List<String> kPickerMuscles = [
  'Mellizom', 'Hátizom', 'Vállizom', 'Bicepsz', 'Tricepsz',
  'Hasizom', 'Lábizom', 'Farizom', 'Vádli', 'Egyéb',
];

/// Movement pattern enum names from the backend. Null = no filter.
const List<String> kMovementPatterns = [
  'HorizontalPush',
  'VerticalPush',
  'HorizontalPull',
  'VerticalPull',
  'Squat',
  'Hinge',
  'Lunge',
  'Carry',
  'Isolation',
  'Core',
];

/// Hungarian display labels for the movement pattern enum values.
const Map<String, String> kMovementPatternLabels = {
  'HorizontalPush': 'Vízsz. tolás',
  'VerticalPush': 'Függ. tolás',
  'HorizontalPull': 'Vízsz. húzás',
  'VerticalPull': 'Függ. húzás',
  'Squat': 'Guggolás',
  'Hinge': 'Csípő',
  'Lunge': 'Kitörés',
  'Carry': 'Hordozás',
  'Isolation': 'Izoláció',
  'Core': 'Törzs',
};

/// Equipment chip labels in the custom-exercise form. The workout builder
/// uses its own equipment vocabulary; here we keep the picker's internal set.
const String kFreeWeight = 'Szabadsúly';
const String kMachine = 'Gép';
const String kBodyweight = 'Testsúly';
const List<String> kEquipmentOptions = [kFreeWeight, kMachine, kBodyweight];

/// Scrollable bottom-sheet contents letting a trainer pick an exercise from
/// the library or create a new custom one. Behaviour and visuals copied from
/// the previous inline implementation in `workout_builder_page.dart`.
///
/// Equipment and movement-pattern chip rows appear once the loaded exercises
/// carry typed data; callers can also prefill the pattern (e.g. the plan
/// editor's "swap, same movement pattern" flow). When no filter is set the
/// picker behaves exactly as before.
class ExercisePicker extends StatefulWidget {
  final ExerciseRepository exerciseRepo;
  final String? athleteId;
  final ScrollController scrollController;
  final ValueChanged<ExerciseModel> onSelect;
  final ValueChanged<ExerciseModel>? onCustomCreated;

  /// Prefill filter: lock the picker to one movement pattern (e.g. during a
  /// swap). Null = user picks from the chip bar.
  final String? initialMovementPattern;

  const ExercisePicker({
    super.key,
    required this.exerciseRepo,
    required this.athleteId,
    required this.scrollController,
    required this.onSelect,
    this.onCustomCreated,
    this.initialMovementPattern,
  });

  @override
  State<ExercisePicker> createState() => _ExercisePickerState();
}

enum _PickerMode { list, custom }

class _ExercisePickerState extends State<ExercisePicker> {
  _PickerMode _mode = _PickerMode.list;
  List<ExerciseModel> _exercises = [];
  bool _isLoading = true;
  bool _isCreating = false;

  String _search = '';
  String? _muscleFilter;
  String? _equipmentFilter;
  String? _patternFilter;
  final _searchCtrl = TextEditingController();

  // Custom form
  final _customNameCtrl = TextEditingController();
  String _customMuscle = 'Mellizom';
  String _customEquip = kFreeWeight;

  @override
  void initState() {
    super.initState();
    _patternFilter = widget.initialMovementPattern;
    _fetchExercises();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _customNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchExercises() async {
    setState(() => _isLoading = true);
    try {
      final search = _search.isEmpty ? null : _search;
      List<ExerciseModel> result;
      if (widget.athleteId != null) {
        result = await widget.exerciseRepo.getExercisesForAthlete(
          widget.athleteId!,
          search: search,
          muscleGroup: _muscleFilter,
        );
      } else {
        final page = await widget.exerciseRepo.getExercises(
          search: search,
          muscleGroup: _muscleFilter,
          pageSize: 100,
        );
        result = page.items;
      }
      // Equipment/pattern filters stay client-side — the exercise API only
      // supports search + muscleGroup today, and we don't want to spam the
      // server with filter calls while the trainer is still ticking boxes.
      if (_equipmentFilter != null) {
        result = result
            .where((e) =>
                e.equipmentTypes.contains(_equipmentFilter) ||
                (e.equipment ?? '')
                    .toLowerCase()
                    .contains(_equipmentFilter!.toLowerCase()))
            .toList();
      }
      if (_patternFilter != null) {
        result = result
            .where((e) => e.movementPattern == _patternFilter)
            .toList();
      }
      _exercises = result;
    } catch (_) {
      _exercises = [];
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _onSearchChanged(String value) {
    _search = value;
    _fetchExercises();
  }

  void _onMuscleFilterChanged(String? muscle) {
    setState(() => _muscleFilter = muscle == _muscleFilter ? null : muscle);
    _fetchExercises();
  }

  void _onEquipmentFilterChanged(String equipment) {
    setState(() => _equipmentFilter =
        equipment == _equipmentFilter ? null : equipment);
    _fetchExercises();
  }

  void _onPatternFilterChanged(String? p) {
    setState(() => _patternFilter = p == _patternFilter ? null : p);
    _fetchExercises();
  }

  Future<void> _createCustomExercise() async {
    final name = _customNameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _isCreating = true);
    try {
      final created = await widget.exerciseRepo.createExercise(
        name: name,
        muscleGroup: _customMuscle,
        equipment: _customEquip,
      );
      widget.onCustomCreated?.call(created);
      _customNameCtrl.clear();
      // Switch back to list and refresh so new exercise shows
      setState(() => _mode = _PickerMode.list);
      _fetchExercises();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nem sikerült létrehozni a gyakorlatot.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle bar
        Center(
          child: Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: DT.s3),
            decoration: BoxDecoration(
                color: DT.of(context).borderGrey,
                borderRadius: BorderRadius.circular(2)),
          ),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(DT.s4, DT.s3, DT.s4, DT.s2),
          child: Row(
            children: [
              Expanded(
                child: Text('Gyakorlat választása',
                    style: TextStyle(
                        fontSize: DT.s4,
                        fontWeight: FontWeight.w700,
                        color: DT.of(context).textPrimary)),
              ),
              if (widget.onCustomCreated != null)
                TextButton.icon(
                  onPressed: () => setState(() {
                    _mode = _mode == _PickerMode.list
                        ? _PickerMode.custom
                        : _PickerMode.list;
                  }),
                  icon: Icon(
                      _mode == _PickerMode.custom ? Icons.list : Icons.add,
                      size: 16, color: DT.metricBlue),
                  label: Text(
                      _mode == _PickerMode.custom ? 'Lista' : 'Új gyakorlat',
                      style: const TextStyle(
                          color: DT.metricBlue, fontSize: DT.s3)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
            ],
          ),
        ),

        if (_mode == _PickerMode.custom)
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: _CustomExerciseForm(
                nameCtrl: _customNameCtrl,
                muscles: kPickerMuscles,
                selectedMuscle: _customMuscle,
                selectedEquip: _customEquip,
                isCreating: _isCreating,
                onMuscleChanged: (m) => setState(() => _customMuscle = m),
                onEquipChanged: (e) => setState(() => _customEquip = e),
                onAdd: _createCustomExercise,
              ),
            ),
          )
        else ...[
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(DT.s4, 0, DT.s4, DT.s2),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Keresés…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: DT.of(context).bg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DT.rCardSmall),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: DT.s3),
              ),
            ),
          ),
          // Muscle group filter chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: DT.s4),
              itemCount: kPickerMuscles.length,
              separatorBuilder: (_, __) => const SizedBox(width: DT.s2),
              itemBuilder: (_, i) {
                final m = kPickerMuscles[i];
                final active = m == _muscleFilter;
                return GestureDetector(
                  onTap: () => _onMuscleFilterChanged(m),
                  child: PickerChip(label: m, selected: active),
                );
              },
            ),
          ),
          // Equipment filter chips (shown when the backend returned typed
          // equipment lists; stays hidden on legacy free-text data).
          if (_hasAnyEquipmentData) ...[
            const SizedBox(height: DT.s2),
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: DT.s4),
                itemCount: AthleteProfileEquipment.all.length,
                separatorBuilder: (_, __) => const SizedBox(width: DT.s2),
                itemBuilder: (_, i) {
                  final e = AthleteProfileEquipment.all[i];
                  return GestureDetector(
                    onTap: () => _onEquipmentFilterChanged(e),
                    child: PickerChip(
                      label: AthleteProfileEquipment.labels[e] ?? e,
                      selected: e == _equipmentFilter,
                    ),
                  );
                },
              ),
            ),
          ],
          // Movement pattern filter chips (shown when the backend returned
          // any typed patterns; stays hidden on legacy-only data).
          if (_hasAnyPatternData) ...[
            const SizedBox(height: DT.s2),
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: DT.s4),
                itemCount: kMovementPatterns.length,
                separatorBuilder: (_, __) => const SizedBox(width: DT.s2),
                itemBuilder: (_, i) {
                  final p = kMovementPatterns[i];
                  final active = p == _patternFilter;
                  return GestureDetector(
                    onTap: () => _onPatternFilterChanged(p),
                    child: PickerChip(
                      label: kMovementPatternLabels[p] ?? p,
                      selected: active,
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: DT.s2),
          // Exercise list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _exercises.isEmpty
                    ? Center(
                        child: Text('Nem található.',
                            style: TextStyle(
                                color: DT.of(context).textSecondary,
                                fontSize: DT.s4)))
                    : ListView.separated(
                        controller: widget.scrollController,
                        padding: const EdgeInsets.fromLTRB(
                            DT.s4, 0, DT.s4, DT.s5),
                        itemCount: _exercises.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: DT.of(context).borderLight),
                        itemBuilder: (_, i) {
                          final ex = _exercises[i];
                          return ExercisePickerTile(
                            exercise: ex,
                            onTap: () => widget.onSelect(ex),
                          );
                        },
                      ),
          ),
        ],
      ],
    );
  }

  /// Pattern chips only make sense once the backend seed is on Phase 0; before
  /// that `movementPattern` is null on every row and the chip strip would
  /// just filter everything to nothing.
  /// Also true while a pattern is selected, so a filter that matched nothing
  /// can still be cleared.
  bool get _hasAnyPatternData =>
      _exercises.any((e) => e.movementPattern != null) ||
      widget.initialMovementPattern != null ||
      _patternFilter != null;

  /// Same rule for equipment: legacy docs only have the free-text
  /// `equipment` string, so the chip row would just filter to nothing.
  bool get _hasAnyEquipmentData =>
      _exercises.any((e) => e.equipmentTypes.isNotEmpty) ||
      _equipmentFilter != null;
}

/// Row rendered inside the picker and the plan editor's exercise lists. Shows
/// usage frequency badge, pattern/compound chips, and a "+" affordance.
class ExercisePickerTile extends StatelessWidget {
  final ExerciseModel exercise;
  final VoidCallback onTap;

  const ExercisePickerTile(
      {super.key, required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final count = exercise.usageCount;
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Expanded(
            child: Text(exercise.name,
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: DT.of(context).textPrimary,
                    fontSize: DT.s3)),
          ),
          if (count != null && count > 0)
            Container(
              margin: const EdgeInsets.only(left: DT.s2),
              padding: const EdgeInsets.symmetric(
                  horizontal: DT.s2, vertical: 2),
              decoration: BoxDecoration(
                color: DT.cardTeal.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(DT.rChip),
              ),
              child: Text(
                count >= 5 ? 'Gyakori' : '${count}x',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: DT.cardTeal.withValues(alpha: 0.9),
                ),
              ),
            ),
        ],
      ),
      subtitle: _ExerciseSubtitle(exercise: exercise),
      trailing: const Icon(Icons.add_circle, color: DT.metricBlue),
    );
  }
}

class _ExerciseSubtitle extends StatelessWidget {
  final ExerciseModel exercise;
  const _ExerciseSubtitle({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final equipText = exercise.equipment;

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Wrap(
        spacing: DT.s2,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(exercise.muscleGroup,
              style: TextStyle(
                  color: DT.of(context).textSecondary, fontSize: 11)),
          if (equipText != null && equipText.isNotEmpty)
            Text('· $equipText',
                style: TextStyle(
                    color: DT.of(context).textSecondary, fontSize: 11)),
          ...ExerciseMetaChip.forExercise(exercise),
        ],
      ),
    );
  }
}

/// Small tinted badge for exercise metadata (movement pattern, "Összetett").
/// Shared by the picker tiles and the exercise catalogue.
class ExerciseMetaChip extends StatelessWidget {
  final String label;

  /// Tints the chip with the primary accent instead of teal; used for the
  /// compound badge so it reads apart from the pattern chip.
  final bool primary;

  const ExerciseMetaChip({super.key, required this.label, this.primary = false});

  /// Label of the compound badge.
  static const String compoundLabel = 'Összetett';

  /// Pattern + compound chips for [exercise]. Empty for legacy documents
  /// that carry neither field.
  static List<Widget> forExercise(ExerciseModel exercise) {
    final pattern = exercise.movementPattern;
    return [
      if (pattern != null)
        ExerciseMetaChip(label: kMovementPatternLabels[pattern] ?? pattern),
      if (exercise.isCompound == true)
        const ExerciseMetaChip(label: compoundLabel, primary: true),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = DT.of(context);
    final c = primary ? colors.accentPrimary : colors.accentTeal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DT.rChip),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: c.withValues(alpha: 0.9))),
    );
  }
}

class _CustomExerciseForm extends StatelessWidget {
  final TextEditingController nameCtrl;
  final List<String> muscles;
  final String selectedMuscle;
  final String selectedEquip;
  final bool isCreating;
  final ValueChanged<String> onMuscleChanged;
  final ValueChanged<String> onEquipChanged;
  final VoidCallback onAdd;

  const _CustomExerciseForm({
    required this.nameCtrl,
    required this.muscles,
    required this.selectedMuscle,
    required this.selectedEquip,
    required this.isCreating,
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
            style: TextStyle(color: DT.of(context).textPrimary),
            decoration: InputDecoration(
              hintText: 'Gyakorlat neve',
              hintStyle: TextStyle(color: DT.of(context).textSecondary),
              filled: true,
              fillColor: DT.of(context).bg,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DT.rCardSmall),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: DT.s3),
          Text('Izomcsoport',
              style: TextStyle(
                  color: DT.of(context).textSecondary, fontSize: DT.s3)),
          const SizedBox(height: DT.s2),
          Wrap(
            spacing: DT.s2,
            runSpacing: DT.s1,
            children: muscles
                .map((m) => GestureDetector(
                      onTap: () => onMuscleChanged(m),
                      child: PickerChip(label: m, selected: m == selectedMuscle),
                    ))
                .toList(),
          ),
          const SizedBox(height: DT.s3),
          Text('Felszerelés',
              style: TextStyle(
                  color: DT.of(context).textSecondary, fontSize: DT.s3)),
          const SizedBox(height: DT.s2),
          Row(
            children: kEquipmentOptions
                .map((e) => Padding(
                      padding: const EdgeInsets.only(right: DT.s2),
                      child: GestureDetector(
                        onTap: () => onEquipChanged(e),
                        child: PickerChip(label: e, selected: e == selectedEquip),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: DT.s4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isCreating ? null : onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: DT.metricBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DT.rCardSmall)),
              ),
              child: isCreating
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Létrehozás és hozzáadás',
                      style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: DT.s4),
        ],
      ),
    );
  }
}

/// Pill-style selectable chip used across the picker. Exposed publicly so the
/// custom-exercise form (and any caller that wants to match the look) can
/// reuse it without duplicating the design-token wiring.
class PickerChip extends StatelessWidget {
  final String label;
  final bool selected;
  const PickerChip({super.key, required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    final colors = DT.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: DT.s2, vertical: DT.s1),
      decoration: BoxDecoration(
        color: selected ? colors.accentPrimary : colors.bg,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        border: Border.all(
            color: selected ? colors.accentPrimary : colors.borderGrey),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selected ? colors.textOnAccent : colors.textSecondary)),
    );
  }
}
