import 'package:flutter_application_1/core/api/api_client.dart';
import 'package:flutter_application_1/core/api/api_constants.dart';
import 'package:flutter_application_1/features/exercise/data/models/exercise_model.dart';

class ExerciseRepository {
  final ApiClient _client;
  ExerciseRepository(this._client);

  Future<PaginatedExercises> getExercises({
    String? search,
    String? muscleGroup,
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await _client.dio.get(
      ApiConstants.exercise,
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (muscleGroup != null && muscleGroup.isNotEmpty)
          'muscleGroup': muscleGroup,
      },
    );
    // Backend returns plain array
    return PaginatedExercises.fromList(res.data as List);
  }

  Future<ExerciseModel> createExercise({
    required String name,
    required String muscleGroup,
    String? description,
    String? equipment,
  }) async {
    final res = await _client.dio.post(ApiConstants.exercise, data: {
      'name': name,
      'muscleGroup': muscleGroup,
      if (description != null && description.isNotEmpty)
        'description': description,
      if (equipment != null && equipment.isNotEmpty) 'equipment': equipment,
    });
    return ExerciseModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ExerciseModel> updateExercise(
    String id, {
    required String name,
    required String muscleGroup,
    String? description,
    String? equipment,
  }) async {
    final res = await _client.dio.put(ApiConstants.exerciseById(id), data: {
      'name': name,
      'muscleGroup': muscleGroup,
      if (description != null && description.isNotEmpty)
        'description': description,
      if (equipment != null && equipment.isNotEmpty) 'equipment': equipment,
    });
    return ExerciseModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteExercise(String id) async {
    await _client.dio.delete(ApiConstants.exerciseById(id));
  }
}
