/// A trainer-scheduled date-ranged program phase for one athlete.
///
/// Backend constraints (enforced server-side, surfaced as errors here):
///   • endDate >= startDate
///   • blocks for the same athlete must not overlap
class TrainingBlockModel {
  final String id;
  final String athleteId;
  final String focus;
  final DateTime startDate; // date only (UTC midnight)
  final DateTime endDate;   // date only (UTC midnight)
  final String? notes;

  const TrainingBlockModel({
    required this.id,
    required this.athleteId,
    required this.focus,
    required this.startDate,
    required this.endDate,
    this.notes,
  });

  /// True if [day] (any time of day) falls within the block.
  bool covers(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    final e = DateTime(endDate.year, endDate.month, endDate.day);
    return !d.isBefore(s) && !d.isAfter(e);
  }

  factory TrainingBlockModel.fromJson(Map<String, dynamic> j) =>
      TrainingBlockModel(
        id: j['id'] as String,
        athleteId: j['athleteId'] as String? ?? '',
        focus: j['focus'] as String? ?? '',
        startDate: DateTime.parse(j['startDate'] as String).toUtc(),
        endDate: DateTime.parse(j['endDate'] as String).toUtc(),
        notes: j['notes'] as String?,
      );
}

/// The set of allowed focus values per the backend spec.
class TrainingBlockFocus {
  static const all = <String>[
    'Push',
    'Pull',
    'Legs',
    'Upper',
    'Lower',
    'Full',
    'Chest',
    'Back',
    'Shoulders',
    'Arms',
    'Core',
  ];
}
