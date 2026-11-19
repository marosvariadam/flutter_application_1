import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/api/api_client.dart';
import 'package:flutter_application_1/core/api/api_constants.dart';
import 'package:flutter_application_1/features/training_plan/data/models/plan_results.dart';
import 'package:flutter_application_1/features/training_plan/data/models/training_plan_model.dart';

/// Backend 400 — the server rejected the body (unknown mode, missing
/// athlete profile, invalid trainingBlockId, bad start date, …). Carries
/// the server's message so the wizard can render it inline.
class PlanValidationException implements Exception {
  final String message;
  const PlanValidationException(this.message);
}

/// Backend 403 — the signed-in trainer is not linked to this athlete, or
/// an athlete tried to read a draft plan.
class PlanForbiddenException implements Exception {
  const PlanForbiddenException();
}

/// Backend 404 — plan or athlete not found.
class PlanNotFoundException implements Exception {
  const PlanNotFoundException();
}

/// Backend 409 — plan already accepted / materialized when the trainer
/// tried to edit or re-materialize it.
class PlanConflictException implements Exception {
  final String message;
  const PlanConflictException(this.message);
}

/// Backend 429 — trainer exceeded the generate/refine/explain quota. The
/// wizard shows a clear retry-later message instead of a generic error.
class PlanRateLimitedException implements Exception {
  const PlanRateLimitedException();
}

/// Backend 502/503 — LLM upstream returned an unparseable or missing
/// response. The hybrid pipeline falls back gracefully on most errors, so
/// this is specifically "we tried and we can't finish without the LLM".
class PlanLlmUnavailableException implements Exception {
  final String message;
  const PlanLlmUnavailableException(this.message);
}

/// Generate / refine can take 10–30 s — the global Dio timeout is 15 s, so
/// we bump the per-request `receiveTimeout` just for those two calls.
const Duration _kLlmReceiveTimeout = Duration(seconds: 60);

class TrainingPlanRepository {
  final ApiClient _client;
  TrainingPlanRepository(this._client);

  // ── Writes ────────────────────────────────────────────────────────────

  /// Generates and persists a draft plan for the given athlete. Only the
  /// top-scored candidate is saved on the server; the summary of the
  /// others is returned for the wizard's comparison view.
  Future<GenerateResultModel> generate({
    required String athleteId,
    required String mode,
    int? weeks,
    String? trainingBlockId,
  }) async {
    try {
      final res = await _client.dio.post(
        ApiConstants.planGenerate,
        data: {
          'athleteId': athleteId,
          'mode': mode,
          if (weeks != null) 'weeks': weeks,
          if (trainingBlockId != null && trainingBlockId.isNotEmpty)
            'trainingBlockId': trainingBlockId,
        },
        options: Options(receiveTimeout: _kLlmReceiveTimeout),
      );
      return GenerateResultModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _mapError(e, llm: true);
    }
  }

  Future<RefineResultModel> refine({
    required String planId,
    required String instruction,
  }) async {
    try {
      final res = await _client.dio.post(
        ApiConstants.planRefine(planId),
        data: {'instruction': instruction},
        options: Options(receiveTimeout: _kLlmReceiveTimeout),
      );
      return RefineResultModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _mapError(e, llm: true);
    }
  }

  /// Manual edit via PUT. Returns the server's re-validated response so
  /// the editor can keep violation badges in sync.
  Future<RefineResultModel> update({
    required String planId,
    String? title,
    int? weeks,
    String? split,
    List<PlanDayModel>? days,
  }) async {
    try {
      final res = await _client.dio.put(
        ApiConstants.planById(planId),
        data: {
          if (title != null) 'title': title,
          if (weeks != null) 'weeks': weeks,
          if (split != null) 'split': split,
          if (days != null)
            'days': days.map((d) => d.toJson()).toList(),
        },
      );
      return RefineResultModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _mapError(e);
    }
  }

  Future<ValidationResultModel> validate(String planId) async {
    try {
      final res = await _client.dio.post(ApiConstants.planValidate(planId));
      return ValidationResultModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _mapError(e);
    }
  }

  Future<TrainingPlanModel> accept(String planId) async {
    try {
      final res = await _client.dio.post(ApiConstants.planAccept(planId));
      return TrainingPlanModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _mapError(e);
    }
  }

  Future<MaterializeResultModel> materialize({
    required String planId,
    required DateTime startDate,
  }) async {
    try {
      final res = await _client.dio.post(
        ApiConstants.planMaterialize(planId),
        data: {'startDate': startDate.toUtc().toIso8601String()},
      );
      return MaterializeResultModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _mapError(e);
    }
  }

  // ── Reads ─────────────────────────────────────────────────────────────

  Future<PlanExplanationModel> explanation({
    required String planId,
    String language = 'hu',
  }) async {
    try {
      final res = await _client.dio.get(
        ApiConstants.planExplanation(planId),
        queryParameters: {'language': language},
        // Explanation is also LLM-backed, same timeout treatment as generate.
        options: Options(receiveTimeout: _kLlmReceiveTimeout),
      );
      return PlanExplanationModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _mapError(e, llm: true);
    }
  }

  Future<List<TrainingPlanModel>> forAthlete(String athleteId) async {
    try {
      final res =
          await _client.dio.get(ApiConstants.planForAthlete(athleteId));
      final list = res.data as List;
      return list
          .map((e) => TrainingPlanModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _mapError(e);
    }
  }

  Future<List<TrainingPlanModel>> mine() async {
    try {
      final res = await _client.dio.get(ApiConstants.planMine);
      final list = res.data as List;
      return list
          .map((e) => TrainingPlanModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _mapError(e);
    }
  }

  /// Translates Dio errors to the typed exceptions above. `llm: true` turns
  /// 502 into `PlanLlmUnavailableException` (503 covers both cases since
  /// the backend returns 503 for "no candidate plan could be produced").
  Never _mapError(DioException e, {bool llm = false}) {
    final code = e.response?.statusCode;
    final body = e.response?.data;
    String? msg;
    if (body is Map && body['message'] is String) {
      msg = body['message'] as String;
    }

    if (code == 400) {
      throw PlanValidationException(msg ?? 'Érvénytelen adat.');
    }
    if (code == 403) throw const PlanForbiddenException();
    if (code == 404) throw const PlanNotFoundException();
    if (code == 409) {
      throw PlanConflictException(msg ?? 'A terv már nem szerkeszthető.');
    }
    if (code == 429) throw const PlanRateLimitedException();
    if (llm && (code == 502 || code == 503)) {
      throw PlanLlmUnavailableException(
          msg ?? 'Az LLM pillanatnyilag nem elérhető.');
    }
    throw e;
  }
}
