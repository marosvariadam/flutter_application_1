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

  factory ExerciseSetModel.fromJson(Map<String, dynamic> json) {
    return ExerciseSetModel(
      setNumber: (json['setNumber'] as num).toInt(),
      weight: (json['weight'] as num?)?.toDouble(),
      reps: (json['reps'] as num?)?.toInt(),
      repRangeMin: (json['repRangeMin'] as num?)?.toInt(),
      repRangeMax: (json['repRangeMax'] as num?)?.toInt(),
    );
  }

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
