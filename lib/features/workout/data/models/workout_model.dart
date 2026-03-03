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
  final String? instructions;
  // Logged by athlete
  final int? actualSets;
  final int? actualReps;
  final double? actualWeightKg;
  final String? exerciseNotes;

  const WorkoutExercise({
    required this.name,
    required this.targetSets,
    required this.targetReps,
    this.targetWeightKg,
    this.instructions,
    this.actualSets,
    this.actualReps,
    this.actualWeightKg,
    this.exerciseNotes,
  });

  factory WorkoutExercise.fromJson(Map<String, dynamic> j) => WorkoutExercise(
        name: j['name'] as String,
        targetSets: j['targetSets'] as int,
        targetReps: j['targetReps'] as int,
        targetWeightKg: (j['targetWeightKg'] as num?)?.toDouble(),
        instructions: j['instructions'] as String?,
        actualSets: j['actualSets'] as int?,
        actualReps: j['actualReps'] as int?,
        actualWeightKg: (j['actualWeightKg'] as num?)?.toDouble(),
        exerciseNotes: j['exerciseNotes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'targetSets': targetSets,
        'targetReps': targetReps,
        if (targetWeightKg != null) 'targetWeightKg': targetWeightKg,
        if (instructions != null) 'instructions': instructions,
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

  factory WorkoutModel.fromJson(Map<String, dynamic> j) => WorkoutModel(
        id: j['id'] as String,
        title: j['title'] as String,
        athleteId: j['athleteId'] as String?,
        athleteName: j['athleteName'] as String?,
        difficulty: WorkoutDifficultyX.fromString(
            j['difficulty'] as String? ?? 'easy'),
        status:
            WorkoutStatusX.fromString(j['status'] as String? ?? 'planned'),
        scheduledDate:
            DateTime.parse(j['scheduledDate'] as String),
        notes: j['notes'] as String?,
        athleteFeedback: j['athleteFeedback'] as String?,
        exercises: (j['exercises'] as List? ?? [])
            .map((e) =>
                WorkoutExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PaginatedWorkouts {
  final List<WorkoutModel> items;
  final int total;
  final int page;
  final int pageSize;

  const PaginatedWorkouts({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  bool get hasMore => (page * pageSize) < total;

  factory PaginatedWorkouts.fromJson(Map<String, dynamic> j) =>
      PaginatedWorkouts(
        items: (j['items'] as List)
            .map((e) =>
                WorkoutModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: j['total'] as int,
        page: j['page'] as int,
        pageSize: j['pageSize'] as int,
      );
}
