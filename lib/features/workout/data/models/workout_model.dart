import 'package:flutter/material.dart';

enum WorkoutStatus {
  planned,
  inProgress,
  completed;

  String get label {
    switch (this) {
      case WorkoutStatus.planned:
        return 'Tervezett';
      case WorkoutStatus.inProgress:
        return 'Folyamatban';
      case WorkoutStatus.completed:
        return 'Teljesítve';
    }
  }

  static WorkoutStatus fromJson(String? s) {
    switch (s?.toLowerCase()) {
      case 'inprogress':
        return WorkoutStatus.inProgress;
      case 'completed':
        return WorkoutStatus.completed;
      default:
        return WorkoutStatus.planned;
    }
  }
}

enum WorkoutDifficulty {
  easy,
  moderate,
  hard,
  intense;

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

  static WorkoutDifficulty fromJson(String? s) {
    switch (s?.toLowerCase()) {
      case 'easy':
      case 'könnyű':
        return WorkoutDifficulty.easy;
      case 'hard':
      case 'nehéz':
        return WorkoutDifficulty.hard;
      case 'intense':
      case 'intenzív':
        return WorkoutDifficulty.intense;
      default:
        return WorkoutDifficulty.moderate;
    }
  }
}

class WorkoutModel {
  final String id;
  final String title;
  final String? description;
  final DateTime scheduledDate;
  final String athleteId;
  final String coachId;
  final WorkoutDifficulty difficulty;
  final WorkoutStatus status;
  final String? trainerName;
  final String? notes;
  final String? athleteName;
  final String? athleteFeedback;
  final Color color;
  final String estimatedDuration;
  final String kcal;
  final List<WorkoutExercise> exercises;

  WorkoutModel({
    required this.id,
    required this.title,
    this.description,
    required this.scheduledDate,
    required this.athleteId,
    required this.coachId,
    required this.difficulty,
    this.status = WorkoutStatus.planned,
    this.trainerName,
    this.notes,
    this.athleteName,
    this.athleteFeedback,
    required this.color,
    required this.estimatedDuration,
    required this.kcal,
    required this.exercises,
  });

  // Colors assigned client-side by index (server has no color concept)
  static const _colors = [
    Color(0xFFBBD2FF), // blue
    Color(0xFF4ECDC4), // teal
    Color(0xFFFFC85D), // yellow
    Color(0xFFFF6B35), // orange
  ];

  factory WorkoutModel.fromJson(Map<String, dynamic> json, {int colorIndex = 0}) {
    final exerciseList = json['exercises'] as List? ?? [];
    return WorkoutModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      athleteId: json['athleteId'] as String? ?? '',
      coachId: json['coachId'] as String? ?? '',
      difficulty: WorkoutDifficulty.fromJson(json['difficulty'] as String?),
      status: WorkoutStatus.fromJson(json['status'] as String?),
      trainerName: json['trainerName'] as String? ?? json['coachName'] as String?,
      notes: json['notes'] as String?,
      athleteName: json['athleteName'] as String?,
      athleteFeedback: json['athleteFeedback'] as String?,
      color: _colors[colorIndex % _colors.length],
      estimatedDuration: json['estimatedDuration'] as String? ?? '—',
      kcal: json['kcal'] as String? ?? '—',
      exercises: exerciseList
          .asMap()
          .entries
          .map((e) => WorkoutExercise.fromJson(
              e.value as Map<String, dynamic>,
              index: e.key))
          .toList(),
    );
  }

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets);
}

/// Returned by paginated list endpoints.
class PaginatedWorkouts {
  final List<WorkoutModel> items;
  final bool hasMore;
  final int page;
  PaginatedWorkouts({required this.items, required this.hasMore, required this.page});

  factory PaginatedWorkouts.fromList(List data, {int page = 1}) {
    final items = data
        .asMap()
        .entries
        .map((e) => WorkoutModel.fromJson(e.value as Map<String, dynamic>, colorIndex: e.key))
        .toList();
    return PaginatedWorkouts(items: items, hasMore: false, page: page);
  }
}

/// An exercise entry within a workout, including target and actual values.
class WorkoutExercise {
  final String exerciseId;
  final String name;
  final int index;
  final int sets;
  final int targetReps;
  final double targetWeightKg;
  final String? instructions;
  final String? equipmentType; // 'Szabadsúly' | 'Gép' | 'Testsúly'
  final String? muscleGroup;
  final int? actualSets;
  final int? actualReps;
  final double? actualWeightKg;
  final int? rpe; // 0-10, optional Rate of Perceived Exertion
  final String? exerciseNotes;

  const WorkoutExercise({
    required this.exerciseId,
    required this.name,
    required this.index,
    required this.sets,
    required this.targetReps,
    required this.targetWeightKg,
    this.instructions,
    this.equipmentType,
    this.muscleGroup,
    this.actualSets,
    this.actualReps,
    this.actualWeightKg,
    this.rpe,
    this.exerciseNotes,
  });

  factory WorkoutExercise.fromJson(Map<String, dynamic> json, {int index = 0}) {
    return WorkoutExercise(
      exerciseId: json['exerciseId'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      index: (json['index'] as num?)?.toInt() ?? index,
      sets: (json['sets'] as num?)?.toInt() ?? 0,
      targetReps: (json['targetReps'] as num?)?.toInt() ?? 0,
      targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble() ?? 0,
      instructions: json['instructions'] as String?,
      equipmentType: json['equipmentType'] as String?,
      muscleGroup: json['muscleGroup'] as String?,
      actualSets: (json['actualSets'] as num?)?.toInt(),
      actualReps: (json['actualReps'] as num?)?.toInt(),
      actualWeightKg: (json['actualWeightKg'] as num?)?.toDouble(),
      rpe: (json['rpe'] as num?)?.toInt(),
      exerciseNotes: json['exerciseNotes'] as String?,
    );
  }
}
