// Equipment type constants

const kEquipmentFreeWeight = 'Szabadsúly';
const kEquipmentMachine = 'Gép';
const kEquipmentBodyweight = 'Testsúly';
const kEquipmentOptions = [kEquipmentFreeWeight, kEquipmentMachine, kEquipmentBodyweight];

String guessEquipment(String? backendEquipment) {
  final e = (backendEquipment ?? '').toLowerCase();
  if (e.contains('body') || e.contains('test')) return kEquipmentBodyweight;
  if (e.contains('machine') || e.contains('gép') || e.contains('kabel') || e.contains('cable')) return kEquipmentMachine;
  return kEquipmentFreeWeight;
}

// Data classes

class BuilderSetEntry {
  int? reps;
  double? weightKg;
  BuilderSetEntry({this.reps, this.weightKg});
}

class BuilderExercise {
  final String exerciseId;
  final String name;
  final String muscleGroup;
  String equipmentType;
  List<BuilderSetEntry> setEntries;
  // Filled after athlete selection - used only for the hint row
  double? prevWeightKg;
  int? prevReps;

  BuilderExercise({
    required this.exerciseId,
    required this.name,
    required this.muscleGroup,
    required this.equipmentType,
    int initialSets = 3,
    int? defaultReps,
    double? defaultWeightKg,
    this.prevWeightKg,
    this.prevReps,
  }) : setEntries = List.generate(
          initialSets,
          (_) => BuilderSetEntry(reps: defaultReps, weightKg: defaultWeightKg),
        );

  int get sets => setEntries.length;
}
