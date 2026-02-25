import 'package:flutter/material.dart';

class SessionModel {
  final String id;
  final String title;
  final String trainer;
  final String description;
  final String duration;
  final String kcal;
  final String difficulty;
  final Color color;

  const SessionModel({
    required this.id,
    required this.title,
    required this.trainer,
    required this.description,
    required this.duration,
    required this.kcal,
    required this.difficulty,
    required this.color,
  });
}
