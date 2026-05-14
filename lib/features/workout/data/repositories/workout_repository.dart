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
      'difficulty': difficulty.name,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
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

  Future<WorkoutModel> startWorkout(String id) async {
    final res = await _client.dio.patch(ApiConstants.startWorkout(id));
    if (res.statusCode == 204 || res.data == null) {
      return getWorkout(id);
    }
    return WorkoutModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> logExercise(
    String workoutId,
    int index, {
    int? actualSets,
    int? actualReps,
    double? actualWeightKg,
    int? rpe,
    String? exerciseNotes,
  }) async {
    await _client.dio.patch(
      ApiConstants.logExercise(workoutId, index),
      data: {
        if (actualSets != null) 'actualSets': actualSets,
        if (actualReps != null) 'actualReps': actualReps,
        if (actualWeightKg != null) 'actualWeightKg': actualWeightKg,
        if (rpe != null) 'rpe': rpe,
        if (exerciseNotes != null) 'exerciseNotes': exerciseNotes,
      },
    );
  }

  Future<List<WorkoutModel>> getTrainerReview(String athleteId) async {
    final res = await _client.dio.get(ApiConstants.trainerReview(athleteId));
    final list = res.data as List;
    return list
        .asMap()
        .entries
        .map((e) => WorkoutModel.fromJson(
            e.value as Map<String, dynamic>,
            colorIndex: e.key))
        .toList();
  }

  Future<List<WorkoutModel>> getTrainerCalendar(
      DateTime from, DateTime to) async {
    final res = await _client.dio.get(ApiConstants.trainerCalendar,
        queryParameters: {
          'from': from.toIso8601String(),
          'to': to.toIso8601String(),
        });
    final list = res.data as List;
    return list
        .asMap()
        .entries
        .map((e) => WorkoutModel.fromJson(
            e.value as Map<String, dynamic>,
            colorIndex: e.key))
        .toList();
  }

  Future<List<WorkoutModel>> getAthleteCalendar(
      DateTime from, DateTime to) async {
    final res = await _client.dio.get(ApiConstants.athleteCalendar,
        queryParameters: {
          'from': from.toIso8601String(),
          'to': to.toIso8601String(),
        });
    final list = res.data as List;
    return list
        .asMap()
        .entries
        .map((e) => WorkoutModel.fromJson(
            e.value as Map<String, dynamic>,
            colorIndex: e.key))
        .toList();
  }

  // ── Shared ─────────────────────────────────────────────────────────────────

  Future<WorkoutModel> getWorkout(String id) async {
    final res = await _client.dio.get(ApiConstants.workoutById(id));
    return WorkoutModel.fromJson(res.data as Map<String, dynamic>);
  }
}
