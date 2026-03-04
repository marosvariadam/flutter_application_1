import 'package:flutter_application_1/core/api/api_client.dart';
import 'package:flutter_application_1/core/api/api_constants.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';

class WorkoutRepository {
  final ApiClient _client;
  WorkoutRepository(this._client);

  // ── Trainer ────────────────────────────────────────────────────────────────

  Future<WorkoutModel> createWorkout({
    required String title,
    required String athleteId,
    required DateTime scheduledDate,
    WorkoutDifficulty difficulty = WorkoutDifficulty.moderate,
    String? notes,
    required List<Map<String, dynamic>> exercises,
  }) async {
    final res = await _client.dio.post(ApiConstants.workout, data: {
      'title': title,
      'athleteId': athleteId,
      'scheduledDate': scheduledDate.toIso8601String(),
      'exercises': exercises,
    });
    return WorkoutModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<WorkoutModel> updateWorkout(
    String id, {
    required String title,
    required DateTime scheduledDate,
    WorkoutDifficulty difficulty = WorkoutDifficulty.moderate,
    String? notes,
    required List<Map<String, dynamic>> exercises,
  }) async {
    final res = await _client.dio.put(ApiConstants.workoutById(id), data: {
      'title': title,
      'scheduledDate': scheduledDate.toIso8601String(),
      'exercises': exercises,
    });
    return WorkoutModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteWorkout(String id) async {
    await _client.dio.delete(ApiConstants.workoutById(id));
  }

  Future<PaginatedWorkouts> getTrainerCreated(
      {int page = 1, int pageSize = 20}) async {
    final res = await _client.dio.get(ApiConstants.trainerCreated);
    return PaginatedWorkouts.fromList(res.data as List);
  }

  // ── Athlete ────────────────────────────────────────────────────────────────

  Future<PaginatedWorkouts> getMyWorkouts(
      {int page = 1, int pageSize = 20}) async {
    final res = await _client.dio.get(ApiConstants.myWorkouts);
    return PaginatedWorkouts.fromList(res.data as List);
  }

  Future<WorkoutModel> completeWorkout(String id, {String? feedback}) async {
    final res = await _client.dio.patch(
      ApiConstants.completeWorkout(id),
      data: {
        if (feedback != null && feedback.isNotEmpty) 'feedback': feedback
      },
    );
    // Backend returns 204 No Content on success — return fetched workout
    if (res.statusCode == 204 || res.data == null) {
      return getWorkout(id);
    }
    return WorkoutModel.fromJson(res.data as Map<String, dynamic>);
  }

  // ── Shared ─────────────────────────────────────────────────────────────────

  Future<WorkoutModel> getWorkout(String id) async {
    final res = await _client.dio.get(ApiConstants.workoutById(id));
    return WorkoutModel.fromJson(res.data as Map<String, dynamic>);
  }
}
