import 'dart:convert';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';
import 'package:flutter_application_1/services/api_client.dart';

class WorkoutService {
  final _api = ApiClient.instance;

  /// All workouts for a given athlete (used for home calendar + history).
  Future<List<WorkoutModel>> getWorkoutsForAthlete(String athleteId) async {
    try {
      final response = await _api.get('/workouts/athlete/$athleteId');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body) as List;
        return data
            .asMap()
            .entries
            .map((e) => WorkoutModel.fromJson(
                e.value as Map<String, dynamic>,
                colorIndex: e.key))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Workout for a specific date, resolved from the full athlete list locally.
  Future<WorkoutModel?> getWorkoutForDate(
      DateTime date, String athleteId) async {
    final workouts = await getWorkoutsForAthlete(athleteId);
    try {
      return workouts.firstWhere(
        (w) =>
            w.scheduledDate.year == date.year &&
            w.scheduledDate.month == date.month &&
            w.scheduledDate.day == date.day,
      );
    } catch (_) {
      return null;
    }
  }

  /// Exercise catalog for the workout builder.
  Future<List<Map<String, String>>> getExerciseLibrary() async {
    try {
      final response = await _api.get('/exercises');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body) as List;
        return data
            .map((e) => {
                  'name': (e['name'] as String?) ?? '',
                  'category': (e['category'] as String?) ?? '',
                })
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Creates a new workout on the server.
  Future<bool> createWorkout(Map<String, dynamic> body) async {
    try {
      final response = await _api.post('/workouts', body);
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
