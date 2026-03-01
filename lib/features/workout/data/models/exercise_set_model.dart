class ExerciseSetModel {
  final int setNumber;
  final double? weight; // kg
  final int? reps;
  final int? repRangeMin;
  final int? repRangeMax;

  const ExerciseSetModel({
    required this.setNumber,
    this.weight,
    this.reps,
    this.repRangeMin,
    this.repRangeMax,
  });

  String get repDisplay {
    if (reps != null) return '$reps';
    if (repRangeMin != null && repRangeMax != null) return '$repRangeMin–$repRangeMax';
    return '—';
  }

  String get weightDisplay {
    if (weight == null) return 'Testtömeg';
    final w = weight!;
    return w % 1 == 0 ? '${w.toInt()}' : w.toStringAsFixed(1);
  }
}
