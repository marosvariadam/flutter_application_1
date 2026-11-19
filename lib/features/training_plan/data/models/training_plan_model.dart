/// Backend enum names, kept as strings so the UI never has to know the
/// serializer's casing rules. Mirrors `Models/TrainingPlan.cs`.
class PlanSplits {
  static const fullBody = 'FullBody';
  static const upperLower = 'UpperLower';
  static const pushPullLegs = 'PushPullLegs';
  static const custom = 'Custom';

  static const all = <String>[fullBody, upperLower, pushPullLegs, custom];

  /// Hungarian label shown in the UI.
  static const Map<String, String> labels = {
    fullBody: 'Full Body',
    upperLower: 'Felső / Alsó',
    pushPullLegs: 'Push / Pull / Legs',
    custom: 'Egyedi',
  };
}

class PlanStatuses {
  static const draft = 'Draft';
  static const accepted = 'Accepted';
  static const materialized = 'Materialized';
  static const archived = 'Archived';

  static const Map<String, String> labels = {
    draft: 'Piszkozat',
    accepted: 'Elfogadva',
    materialized: 'Ütemezve',
    archived: 'Archivált',
  };
}

class PlanProgressionSchemes {
  static const linear = 'Linear';
  static const doubleProgression = 'DoubleProgression';
  static const rpeBased = 'RpeBased';

  static const Map<String, String> labels = {
    linear: 'Lineáris',
    doubleProgression: 'Dupla progresszió',
    rpeBased: 'RPE alapú',
  };
}

class PlanGenerationSources {
  static const constraint = 'Constraint';
  static const llmOnly = 'LlmOnly';
  static const hybrid = 'Hybrid';
  static const manual = 'Manual';

  /// Labels shown on the generate wizard's mode picker. The two
  /// non-hybrid modes are tagged as comparison-only, mirroring the
  /// frontend spec wording.
  static const Map<String, String> wizardLabels = {
    hybrid: 'Hibrid',
    constraint: 'Csak szabályalapú',
    llmOnly: 'Csak LLM',
  };

  static const Map<String, String> wizardDescriptions = {
    hybrid: 'Alapértelmezett — CP-SAT + LLM, ML pontozással.',
    constraint: 'Összehasonlításhoz: tiszta CP-SAT, LLM nélkül.',
    llmOnly: 'Összehasonlításhoz: csak az LLM kimenete.',
  };
}

/// A trainer-authored or AI-generated plan for a single athlete. Mirrors
/// `Models/TrainingPlan.cs`; enums are serialized as strings so this model
/// can store them as-is.
class TrainingPlanModel {
  final String id;
  final String trainerId;
  final String athleteId;
  final String? trainingBlockId;
  final String title;
  final String goal;
  final int weeks;
  final String split;
  final String status;
  final List<PlanDayModel> days;
  final String progression;
  final String source;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  const TrainingPlanModel({
    required this.id,
    required this.trainerId,
    required this.athleteId,
    this.trainingBlockId,
    required this.title,
    required this.goal,
    required this.weeks,
    required this.split,
    required this.status,
    required this.days,
    required this.progression,
    required this.source,
    required this.createdAt,
    this.acceptedAt,
  });

  factory TrainingPlanModel.fromJson(Map<String, dynamic> j) =>
      TrainingPlanModel(
        id: j['id'] as String? ?? '',
        trainerId: j['trainerId'] as String? ?? '',
        athleteId: j['athleteId'] as String? ?? '',
        trainingBlockId: j['trainingBlockId'] as String?,
        title: j['title'] as String? ?? '',
        goal: j['goal'] as String? ?? 'GeneralFitness',
        weeks: (j['weeks'] as num?)?.toInt() ?? 0,
        split: j['split'] as String? ?? PlanSplits.fullBody,
        status: j['status'] as String? ?? PlanStatuses.draft,
        days: (j['days'] as List? ?? const [])
            .map((e) => PlanDayModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        progression:
            j['progression'] as String? ?? PlanProgressionSchemes.doubleProgression,
        source: j['source'] as String? ?? PlanGenerationSources.manual,
        createdAt:
            DateTime.tryParse(j['createdAt'] as String? ?? '')?.toUtc() ??
                DateTime.now().toUtc(),
        acceptedAt: DateTime.tryParse(j['acceptedAt'] as String? ?? ''),
      );

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'trainerId': trainerId,
        'athleteId': athleteId,
        if (trainingBlockId != null) 'trainingBlockId': trainingBlockId,
        'title': title,
        'goal': goal,
        'weeks': weeks,
        'split': split,
        'status': status,
        'days': days.map((d) => d.toJson()).toList(),
        'progression': progression,
        'source': source,
        'createdAt': createdAt.toIso8601String(),
        if (acceptedAt != null) 'acceptedAt': acceptedAt!.toIso8601String(),
      };

  /// Total number of exercise slots across the plan — used for quick summary
  /// chips on the wizard result screen.
  int get totalExercises =>
      days.fold(0, (sum, d) => sum + d.exercises.length);

  TrainingPlanModel copyWith({
    String? title,
    int? weeks,
    String? split,
    String? status,
    List<PlanDayModel>? days,
    DateTime? acceptedAt,
  }) =>
      TrainingPlanModel(
        id: id,
        trainerId: trainerId,
        athleteId: athleteId,
        trainingBlockId: trainingBlockId,
        title: title ?? this.title,
        goal: goal,
        weeks: weeks ?? this.weeks,
        split: split ?? this.split,
        status: status ?? this.status,
        days: days ?? this.days,
        progression: progression,
        source: source,
        createdAt: createdAt,
        acceptedAt: acceptedAt ?? this.acceptedAt,
      );
}

class PlanDayModel {
  final int dayIndex;
  final String label;
  final List<PlannedExerciseModel> exercises;

  const PlanDayModel({
    required this.dayIndex,
    required this.label,
    required this.exercises,
  });

  factory PlanDayModel.fromJson(Map<String, dynamic> j) => PlanDayModel(
        dayIndex: (j['dayIndex'] as num?)?.toInt() ?? 0,
        label: j['label'] as String? ?? '',
        exercises: (j['exercises'] as List? ?? const [])
            .map((e) => PlannedExerciseModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'dayIndex': dayIndex,
        'label': label,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };
}

class PlannedExerciseModel {
  final String? exerciseId;
  final String name;
  final String muscleGroup;
  final int sets;
  final int repMin;
  final int repMax;
  final int targetRpe;
  final int restSeconds;
  final int order;
  final String? notes;

  const PlannedExerciseModel({
    this.exerciseId,
    required this.name,
    required this.muscleGroup,
    required this.sets,
    required this.repMin,
    required this.repMax,
    required this.targetRpe,
    required this.restSeconds,
    required this.order,
    this.notes,
  });

  factory PlannedExerciseModel.fromJson(Map<String, dynamic> j) =>
      PlannedExerciseModel(
        exerciseId: j['exerciseId'] as String?,
        name: j['name'] as String? ?? '',
        muscleGroup: j['muscleGroup'] as String? ?? '',
        sets: (j['sets'] as num?)?.toInt() ?? 0,
        repMin: (j['repMin'] as num?)?.toInt() ?? 0,
        repMax: (j['repMax'] as num?)?.toInt() ?? 0,
        targetRpe: (j['targetRpe'] as num?)?.toInt() ?? 0,
        restSeconds: (j['restSeconds'] as num?)?.toInt() ?? 0,
        order: (j['order'] as num?)?.toInt() ?? 0,
        notes: j['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (exerciseId != null) 'exerciseId': exerciseId,
        'name': name,
        'muscleGroup': muscleGroup,
        'sets': sets,
        'repMin': repMin,
        'repMax': repMax,
        'targetRpe': targetRpe,
        'restSeconds': restSeconds,
        'order': order,
        if (notes != null) 'notes': notes,
      };

  /// e.g. "3 × 8–12 @ RPE 8". Used by the plan preview card so the wizard
  /// result screen can stay compact.
  String get prescription {
    final reps = repMin == repMax ? '$repMin' : '$repMin–$repMax';
    return '$sets × $reps @ RPE $targetRpe';
  }
}
