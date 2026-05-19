import 'package:flutter_application_1/core/api/api_client.dart';
import 'package:flutter_application_1/core/api/api_constants.dart';
import 'package:flutter_application_1/features/exercise_stats/data/models/exercise_stat_point.dart';

class ExerciseStatsRepository {
  final ApiClient _client;
  ExerciseStatsRepository(this._client);

  /// Fetch stats for the authenticated athlete's own exercises.
  Future<List<ExerciseStatPoint>> getStats({
    required String exerciseName,
    required DateTime from,
    required DateTime to,
  }) async {
    final res = await _client.dio.get(
      ApiConstants.exerciseStats,
      queryParameters: {
        'exerciseName': exerciseName,
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
      },
    );
    final list = res.data as List;
    return list
        .map((e) => ExerciseStatPoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch stats for a specific athlete (trainer view).
  Future<List<ExerciseStatPoint>> getStatsForAthlete({
    required String athleteId,
    required String exerciseName,
    required DateTime from,
    required DateTime to,
  }) async {
    final res = await _client.dio.get(
      ApiConstants.exerciseStatsForAthlete(athleteId),
      queryParameters: {
        'exerciseName': exerciseName,
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
      },
    );
    final list = res.data as List;
    return list
        .map((e) => ExerciseStatPoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
