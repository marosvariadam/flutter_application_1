/// `RuleOutcome` names from `Planning/AutoregulationService.cs`. The
/// controller serializes them with `.ToString()`, so they arrive as-is.
class AutoregulationOutcomes {
  static const hold = 'Hold';
  static const increase = 'Increase';
  static const decrease = 'Decrease';
  static const deload = 'Deload';
}

/// Most recent completed session the backend found for an exercise in the
/// ~4-week lookback window.
class LastLoggedSessionModel {
  final DateTime date;
  final int sets;
  final int reps;
  final double weightKg;
  final double? rpe;

  const LastLoggedSessionModel({
    required this.date,
    required this.sets,
    required this.reps,
    required this.weightKg,
    this.rpe,
  });

  factory LastLoggedSessionModel.fromJson(Map<String, dynamic> j) =>
      LastLoggedSessionModel(
        date: DateTime.parse(j['date'] as String).toUtc(),
        sets: (j['sets'] as num?)?.toInt() ?? 0,
        reps: (j['reps'] as num?)?.toInt() ?? 0,
        weightKg: (j['weightKg'] as num?)?.toDouble() ?? 0,
        rpe: (j['rpe'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'sets': sets,
        'reps': reps,
        'weightKg': weightKg,
        if (rpe != null) 'rpe': rpe,
      };
}

/// One next-week load suggestion for an exercise of the athlete's latest
/// accepted plan.
class AutoregulationSuggestionModel {
  /// Null when the plan row has no library id (e.g. a repaired LLM output);
  /// the backend then keys the suggestion by [name].
  final String? exerciseId;
  final String name;
  final String muscleGroup;

  /// Plan progression scheme: `DoubleProgression`, `RpeBased` or `Linear`.
  final String scheme;

  /// Prescribed rep range as sent by the backend, e.g. `"6-10"`.
  final String currentReps;
  final int targetRpe;

  /// Null when there is nothing to prescribe (no usable logged session).
  final double? suggestedWeightKg;
  final int suggestedSets;
  final String outcome;

  /// English rule explanation from the backend; the UI builds its own
  /// Hungarian copy and keeps this for debugging / tooltips if needed.
  final String reason;
  final LastLoggedSessionModel? lastLogged;

  const AutoregulationSuggestionModel({
    this.exerciseId,
    required this.name,
    required this.muscleGroup,
    required this.scheme,
    required this.currentReps,
    required this.targetRpe,
    this.suggestedWeightKg,
    required this.suggestedSets,
    required this.outcome,
    required this.reason,
    this.lastLogged,
  });

  bool get isDeload => outcome == AutoregulationOutcomes.deload;

  /// Only suggestions with a concrete weight can be applied to a workout.
  bool get isActionable => suggestedWeightKg != null;

  /// Weight change against the last logged session, or null when either
  /// side is missing. Derived from the numbers rather than [outcome]
  /// because the RPE-based rule reports `Increase` even when the solved
  /// weight is lower than last time.
  double? get deltaKg {
    final next = suggestedWeightKg;
    final last = lastLogged?.weightKg;
    if (next == null || last == null) return null;
    return next - last;
  }

  factory AutoregulationSuggestionModel.fromJson(Map<String, dynamic> j) =>
      AutoregulationSuggestionModel(
        exerciseId: j['exerciseId'] as String?,
        name: j['name'] as String? ?? '',
        muscleGroup: j['muscleGroup'] as String? ?? '',
        scheme: j['scheme'] as String? ?? '',
        currentReps: j['currentReps'] as String? ?? '',
        targetRpe: (j['targetRpe'] as num?)?.toInt() ?? 0,
        suggestedWeightKg: (j['suggestedWeightKg'] as num?)?.toDouble(),
        suggestedSets: (j['suggestedSets'] as num?)?.toInt() ?? 0,
        outcome: j['outcome'] as String? ?? AutoregulationOutcomes.hold,
        reason: j['reason'] as String? ?? '',
        lastLogged: j['lastLogged'] is Map<String, dynamic>
            ? LastLoggedSessionModel.fromJson(
                j['lastLogged'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'name': name,
        'muscleGroup': muscleGroup,
        'scheme': scheme,
        'currentReps': currentReps,
        'targetRpe': targetRpe,
        'suggestedWeightKg': suggestedWeightKg,
        'suggestedSets': suggestedSets,
        'outcome': outcome,
        'reason': reason,
        'lastLogged': lastLogged?.toJson(),
      };
}

/// Response of `GET /api/autoregulation/{athleteId}/next-week`.
class NextWeekAutoregulationModel {
  /// Null when the athlete has no accepted plan yet; [suggestions] is then
  /// empty and `deloadApplied` is absent from the payload.
  final String? planId;

  /// True when the deload rule fired — every suggestion is then a deload
  /// prescription (−10% load, −40% sets).
  final bool deloadApplied;
  final List<AutoregulationSuggestionModel> suggestions;

  const NextWeekAutoregulationModel({
    this.planId,
    this.deloadApplied = false,
    this.suggestions = const [],
  });

  bool get hasPlan => planId != null;

  factory NextWeekAutoregulationModel.fromJson(Map<String, dynamic> j) =>
      NextWeekAutoregulationModel(
        planId: j['planId'] as String?,
        deloadApplied: j['deloadApplied'] as bool? ?? false,
        suggestions: ((j['suggestions'] as List?) ?? const [])
            .map((e) => AutoregulationSuggestionModel.fromJson(
                e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'planId': planId,
        'deloadApplied': deloadApplied,
        'suggestions': suggestions.map((s) => s.toJson()).toList(),
      };

  /// Suggestion for a builder exercise: library id first, then a
  /// case-insensitive name match (the backend dedupes by lowercased name).
  AutoregulationSuggestionModel? suggestionFor({
    String? exerciseId,
    required String name,
  }) {
    if (exerciseId != null && exerciseId.isNotEmpty) {
      for (final s in suggestions) {
        if (s.exerciseId == exerciseId) return s;
      }
    }
    final key = name.trim().toLowerCase();
    for (final s in suggestions) {
      if (s.name.trim().toLowerCase() == key) return s;
    }
    return null;
  }
}
