import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/api/api_client.dart';
import 'package:flutter_application_1/core/api/api_constants.dart';
import 'package:flutter_application_1/features/autoregulation/data/models/autoregulation_model.dart';

/// 403 - the signed-in trainer is not linked to this athlete.
class AutoregulationForbiddenException implements Exception {
  const AutoregulationForbiddenException();
}

/// 404 - the athlete id doesn't exist or isn't an athlete.
class AutoregulationNotFoundException implements Exception {
  const AutoregulationNotFoundException();
}

class AutoregulationRepository {
  final ApiClient _client;
  AutoregulationRepository(this._client);

  /// Trainer-only. An athlete without an accepted plan is not an error: the
  /// backend answers 200 with `planId: null` and no suggestions.
  Future<NextWeekAutoregulationModel> nextWeek(String athleteId) async {
    try {
      final res =
          await _client.dio.get(ApiConstants.autoregulationNextWeek(athleteId));
      return NextWeekAutoregulationModel.fromJson(
          res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 403) throw const AutoregulationForbiddenException();
      if (code == 404) throw const AutoregulationNotFoundException();
      rethrow;
    }
  }
}
