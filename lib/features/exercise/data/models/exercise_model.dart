class ExerciseModel {
  final String id;
  final String name;
  final String muscleGroup;
  final String? description;
  final String? equipment;
  final String? createdByTrainerId;

  const ExerciseModel({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.description,
    this.equipment,
    this.createdByTrainerId,
  });

  /// Custom exercises were created by a specific trainer.
  bool get isCustom => createdByTrainerId != null;

  factory ExerciseModel.fromJson(Map<String, dynamic> j) => ExerciseModel(
        id: j['id'] as String,
        name: j['name'] as String,
        muscleGroup: j['muscleGroup'] as String? ?? '',
        description: j['description'] as String?,
        equipment: j['equipment'] as String?,
        createdByTrainerId: j['createdByTrainerId'] as String?,
      );
}

/// Wraps a plain array from the backend so existing blocs don't need to change.
class PaginatedExercises {
  final List<ExerciseModel> items;
  final bool hasMore;

  const PaginatedExercises({required this.items, this.hasMore = false});

  factory PaginatedExercises.fromList(List<dynamic> list) => PaginatedExercises(
        items: list
            .map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
