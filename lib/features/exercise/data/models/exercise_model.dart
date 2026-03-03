class ExerciseModel {
  final String id;
  final String name;
  final String muscleGroup;
  final String? description;
  final bool isCustom;

  const ExerciseModel({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.description,
    this.isCustom = false,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> j) => ExerciseModel(
        id: j['id'] as String,
        name: j['name'] as String,
        muscleGroup: j['muscleGroup'] as String,
        description: j['description'] as String?,
        isCustom: j['isCustom'] as bool? ?? false,
      );
}

class PaginatedExercises {
  final List<ExerciseModel> items;
  final int total;
  final int page;
  final int pageSize;

  const PaginatedExercises({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  bool get hasMore => (page * pageSize) < total;

  factory PaginatedExercises.fromJson(Map<String, dynamic> j) =>
      PaginatedExercises(
        items: (j['items'] as List)
            .map((e) =>
                ExerciseModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: j['total'] as int,
        page: j['page'] as int,
        pageSize: j['pageSize'] as int,
      );
}
