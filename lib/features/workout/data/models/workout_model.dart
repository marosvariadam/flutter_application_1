import 'package:flutter/material.dart';
import 'exercise_model.dart';

class WorkoutModel {
  final String id;
  final String title;
  final String? description;
  final DateTime scheduledDate;
  final String athleteId;
  final String coachId;
  final String difficulty; // 'Könnyű', 'Közepes', 'Nehéz'
  final Color color;
  final String estimatedDuration;
  final String kcal;
  final List<ExerciseModel> exercises;

  WorkoutModel({
    required this.id,
    required this.title,
    this.description,
    required this.scheduledDate,
    required this.athleteId,
    required this.coachId,
    required this.difficulty,
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
    return WorkoutModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      athleteId: json['athleteId'] as String? ?? '',
      coachId: json['coachId'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'Közepes',
      color: _colors[colorIndex % _colors.length],
      estimatedDuration: json['estimatedDuration'] as String? ?? '—',
      kcal: json['kcal'] as String? ?? '—',
      exercises: (json['exercises'] as List?)
              ?.map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets.length);
}
