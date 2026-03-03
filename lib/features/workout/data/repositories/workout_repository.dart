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
    required WorkoutDifficulty difficulty,
    required DateTime scheduledDate,
    String? notes,
    required List<Map<String, dynamic>> exercises,
  }) async {
    final res = await _client.dio.post(ApiConstants.workout, data: {
      'title': title,
      'athleteId': athleteId,
      'difficulty': difficulty.name,
      'scheduledDate': scheduledDate.toIso8601String(),
      if (notes != null) 'notes': notes,
      'exercises': exercises,
    });
    return WorkoutModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<WorkoutModel> updateWorkout(
    String id, {
    required String title,
    required WorkoutDifficulty difficulty,
    required DateTime scheduledDate,
    String? notes,
    required List<Map<String, dynamic>> exercises,
  }) async {
    final res = await _client.dio.put(ApiConstants.workoutById(id), data: {
      'title': title,
      'difficulty': difficulty.name,
      'scheduledDate': scheduledDate.toIso8601String(),
      if (notes != null) 'notes': notes,
      'exercises': exercises,
    });
    return WorkoutModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteWorkout(String id) async {
    await _client.dio.delete(ApiConstants.workoutById(id));
  }

  Future<PaginatedWorkouts> getTrainerCreated({int page = 1, int pageSize = 20}) async {
    final res = await _client.dio.get(
      ApiConstants.trainerCreated,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return PaginatedWorkouts.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<WorkoutModel>> getTrainerCalendar(DateTime from, DateTime to) async {
    final res = await _client.dio.get(
      ApiConstants.trainerCalendar,
      queryParameters: {
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
      },
    );
    return (res.data as List)
        .map((e) => WorkoutModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<WorkoutModel>> getTrainerReview(String athleteId) async {
    final res = await _client.dio.get(
      ApiConstants.trainerReview,
      queryParameters: {'athleteId': athleteId},
    );
    return (res.data as List)
        .map((e) => WorkoutModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Athlete ────────────────────────────────────────────────────────────────

  Future<PaginatedWorkouts> getMyWorkouts({int page = 1, int pageSize = 20}) async {
    final res = await _client.dio.get(
      ApiConstants.myWorkouts,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return PaginatedWorkouts.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<WorkoutModel>> getAthleteCalendar(DateTime from, DateTime to) async {
    final res = await _client.dio.get(
      ApiConstants.athleteCalendar,
      queryParameters: {
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
      },
    );
    return (res.data as List)
        .map((e) => WorkoutModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<WorkoutModel> startWorkout(String id) async {
    final res = await _client.dio.patch(ApiConstants.startWorkout(id));
    return WorkoutModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> logExercise(
    String workoutId,
    int index, {
    int? actualSets,
    int? actualReps,
    double? actualWeightKg,
    String? exerciseNotes,
  }) async {
    await _client.dio.patch(
      ApiConstants.logExercise(workoutId, index),
      data: {
        if (actualSets != null) 'actualSets': actualSets,
        if (actualReps != null) 'actualReps': actualReps,
        if (actualWeightKg != null) 'actualWeightKg': actualWeightKg,
        if (exerciseNotes != null) 'exerciseNotes': exerciseNotes,
      },
    );
  }

  Future<WorkoutModel> completeWorkout(String id, {String? feedback}) async {
    final res = await _client.dio.patch(
      ApiConstants.completeWorkout(id),
      data: {if (feedback != null && feedback.isNotEmpty) 'feedback': feedback},
    );
    return WorkoutModel.fromJson(res.data as Map<String, dynamic>);
  }

  // ── Shared ─────────────────────────────────────────────────────────────────

  Future<WorkoutModel> getWorkout(String id) async {
    final res = await _client.dio.get(ApiConstants.workoutById(id));
    return WorkoutModel.fromJson(res.data as Map<String, dynamic>);
  }
}
