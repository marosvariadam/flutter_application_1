enum WorkoutDifficulty { easy, moderate, hard, intense }

extension WorkoutDifficultyX on WorkoutDifficulty {
  String get label {
    switch (this) {
      case WorkoutDifficulty.easy:
        return 'Könnyű';
      case WorkoutDifficulty.moderate:
        return 'Közepes';
      case WorkoutDifficulty.hard:
        return 'Nehéz';
      case WorkoutDifficulty.intense:
        return 'Intenzív';
    }
  }

  static WorkoutDifficulty fromString(String s) {
    switch (s.toLowerCase()) {
      case 'moderate':
        return WorkoutDifficulty.moderate;
      case 'hard':
        return WorkoutDifficulty.hard;
      case 'intense':
        return WorkoutDifficulty.intense;
      default:
        return WorkoutDifficulty.easy;
    }
  }
}

enum WorkoutStatus { planned, inProgress, completed }

extension WorkoutStatusX on WorkoutStatus {
  String get label {
    switch (this) {
      case WorkoutStatus.planned:
        return 'Tervezett';
      case WorkoutStatus.inProgress:
        return 'Folyamatban';
      case WorkoutStatus.completed:
        return 'Befejezett';
    }
  }

  static WorkoutStatus fromString(String s) {
    switch (s.toLowerCase()) {
      case 'inprogress':
        return WorkoutStatus.inProgress;
      case 'completed':
        return WorkoutStatus.completed;
      default:
        return WorkoutStatus.planned;
    }
  }
}

class WorkoutExercise {
  final String name;
  final int targetSets;
  final int targetReps;
  final double? targetWeightKg;
  final String? instructions; // trainerNotes from backend
  final String? exerciseNotes; // athleteNotes from backend

  const WorkoutExercise({
    required this.name,
    required this.targetSets,
    required this.targetReps,
    this.targetWeightKg,
    this.instructions,
    this.exerciseNotes,
  });

  factory WorkoutExercise.fromJson(Map<String, dynamic> j) => WorkoutExercise(
        name: j['name'] as String,
        // Backend uses 'sets' + 'targetRepetitions'; fall back to camelCase variants
        targetSets: j['sets'] as int? ?? j['targetSets'] as int? ?? 0,
        targetReps: j['targetRepetitions'] as int? ??
            j['targetReps'] as int? ??
            0,
        targetWeightKg: (j['targetWeightKg'] as num?)?.toDouble(),
        instructions: j['trainerNotes'] as String? ??
            j['instructions'] as String?,
        exerciseNotes: j['athleteNotes'] as String? ??
            j['exerciseNotes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'sets': targetSets,
        'targetRepetitions': targetReps,
        if (targetWeightKg != null) 'targetWeightKg': targetWeightKg,
        if (instructions != null) 'trainerNotes': instructions,
      };
}

class WorkoutModel {
  final String id;
  final String title;
  final String? athleteId;
  final String? athleteName;
  final WorkoutDifficulty difficulty;
  final WorkoutStatus status;
  final DateTime scheduledDate;
  final String? notes;
  final String? athleteFeedback;
  final List<WorkoutExercise> exercises;

  const WorkoutModel({
    required this.id,
    required this.title,
    this.athleteId,
    this.athleteName,
    required this.difficulty,
    required this.status,
    required this.scheduledDate,
    this.notes,
    this.athleteFeedback,
    required this.exercises,
  });

  factory WorkoutModel.fromJson(Map<String, dynamic> j) {
    // Backend uses isCompleted bool; richer status string if present
    final isCompleted = j['isCompleted'] as bool? ?? false;
    final statusStr = j['status'] as String?;
    final status = statusStr != null
        ? WorkoutStatusX.fromString(statusStr)
        : (isCompleted ? WorkoutStatus.completed : WorkoutStatus.planned);

    return WorkoutModel(
      id: j['id'] as String,
      title: j['title'] as String,
      athleteId: j['athleteId'] as String?,
      athleteName: j['athleteName'] as String?,
      difficulty: WorkoutDifficultyX.fromString(
          j['difficulty'] as String? ?? 'easy'),
      status: status,
      scheduledDate: DateTime.parse(j['scheduledDate'] as String),
      notes: j['notes'] as String?,
      athleteFeedback: j['athleteFeedback'] as String?,
      exercises: (j['exercises'] as List? ?? [])
          .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Wraps a plain array response into a paginated structure so existing blocs
/// work without changes. Backend currently returns plain arrays.
class PaginatedWorkouts {
  final List<WorkoutModel> items;
  final bool hasMore;

  const PaginatedWorkouts({required this.items, this.hasMore = false});

  /// Use when the backend returns a plain JSON array.
  factory PaginatedWorkouts.fromList(List<dynamic> list) => PaginatedWorkouts(
        items: list
            .map((e) => WorkoutModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Use if the backend wraps into { items, total, page, pageSize }.
  factory PaginatedWorkouts.fromJson(Map<String, dynamic> j) {
    final rawItems = j['items'] as List?;
    if (rawItems != null) {
      final total = j['total'] as int? ?? 0;
      final page = j['page'] as int? ?? 1;
      final pageSize = j['pageSize'] as int? ?? rawItems.length;
      return PaginatedWorkouts(
        items: rawItems
            .map((e) => WorkoutModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        hasMore: (page * pageSize) < total,
      );
    }
    // Plain array response
    return PaginatedWorkouts.fromList(j.values.first as List);
  }
}
