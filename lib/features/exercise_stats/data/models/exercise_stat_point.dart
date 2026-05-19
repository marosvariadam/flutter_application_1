class ExerciseStatPoint {
  final DateTime date;
  final int actualSets;
  final int actualReps;
  final double actualWeightKg;
  final int targetReps;
  final double targetWeightKg;

  const ExerciseStatPoint({
    required this.date,
    required this.actualSets,
    required this.actualReps,
    required this.actualWeightKg,
    required this.targetReps,
    required this.targetWeightKg,
  });

  factory ExerciseStatPoint.fromJson(Map<String, dynamic> j) =>
      ExerciseStatPoint(
        date: DateTime.parse(j['date'] as String),
        actualSets: (j['actualSets'] as num?)?.toInt() ?? 0,
        actualReps: (j['actualReps'] as num?)?.toInt() ?? 0,
        actualWeightKg: (j['actualWeightKg'] as num?)?.toDouble() ?? 0,
        targetReps: (j['targetReps'] as num?)?.toInt() ?? 0,
        targetWeightKg: (j['targetWeightKg'] as num?)?.toDouble() ?? 0,
      );
}
