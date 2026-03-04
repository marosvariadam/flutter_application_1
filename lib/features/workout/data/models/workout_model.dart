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

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets.length);

  String get trainer => 'Coach'; // placeholder until real coach data is wired
}
