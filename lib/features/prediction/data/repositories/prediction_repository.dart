import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/api/api_client.dart';
import 'package:flutter_application_1/core/api/api_constants.dart';
import 'package:flutter_application_1/features/prediction/data/models/prediction_models.dart';

/// Thrown when the backend returns 404 - meaning the athlete has no completed
/// sessions for this exercise yet. The UI distinguishes this from a generic
/// error.
class PredictionEmptyException implements Exception {
  const PredictionEmptyException();
}

/// Thrown when the trainer is not authorised to view this athlete's data.
class PredictionForbiddenException implements Exception {
  const PredictionForbiddenException();
}

class PredictionRepository {
  final ApiClient _client;
  PredictionRepository(this._client);

  /// Forecast for the authenticated athlete's own exercise.
  Future<PredictionResult> getMyPrediction({
    required String exerciseName,
    int weeksAhead = 8,
    String? focus,
  }) {
    return _get(
      ApiConstants.predictionMine,
      exerciseName: exerciseName,
      weeksAhead: weeksAhead,
      focus: focus,
    );
  }

  /// Forecast for a specific athlete - trainer view.
  Future<PredictionResult> getPredictionForAthlete({
    required String athleteId,
    required String exerciseName,
    int weeksAhead = 8,
    String? focus,
  }) {
    return _get(
      ApiConstants.predictionForAthlete(athleteId),
      exerciseName: exerciseName,
      weeksAhead: weeksAhead,
      focus: focus,
    );
  }

  Future<PredictionResult> _get(
    String path, {
    required String exerciseName,
    required int weeksAhead,
    String? focus,
  }) async {
    try {
      final res = await _client.dio.get(
        path,
        queryParameters: {
          'exerciseName': exerciseName,
          'weeksAhead': weeksAhead,
          if (focus != null && focus.isNotEmpty) 'focus': focus,
        },
      );
      return PredictionResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404) throw const PredictionEmptyException();
      if (status == 403) throw const PredictionForbiddenException();
      rethrow;
    }
  }
}
