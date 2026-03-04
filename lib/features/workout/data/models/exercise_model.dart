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

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      category: json['category'] as String? ?? '',
      sets: (json['sets'] as List?)
              ?.map((s) => ExerciseSetModel.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
