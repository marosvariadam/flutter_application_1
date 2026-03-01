import 'exercise_set_model.dart';

class ExerciseModel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String category; // 'Mellkas', 'Háto', 'Lábak', 'Vállak', 'Bicepsz', 'Tricepsz', 'Core'
  final List<ExerciseSetModel> sets;

  const ExerciseModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.category,
    required this.sets,
  });
}
