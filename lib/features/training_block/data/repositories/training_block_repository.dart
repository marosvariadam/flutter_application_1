import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/api/api_client.dart';
import 'package:flutter_application_1/core/api/api_constants.dart';
import 'package:flutter_application_1/features/training_block/data/models/training_block_model.dart';

/// Server said the new/edited block overlaps an existing one for this athlete.
/// Carries the backend message so the UI snackbar can echo it verbatim per spec.
class TrainingBlockOverlapException implements Exception {
  final String message;
  const TrainingBlockOverlapException(this.message);
}

/// 400 — typically `endDate < startDate`. Carries the server message so the
/// form can show it inline next to the date fields.
class TrainingBlockValidationException implements Exception {
  final String message;
  const TrainingBlockValidationException(this.message);
}

/// 403 — trainer doesn't own this athlete.
class TrainingBlockForbiddenException implements Exception {
  const TrainingBlockForbiddenException();
}

class TrainingBlockRepository {
  final ApiClient _client;
  TrainingBlockRepository(this._client);

  /// Date-only string (YYYY-MM-DD) as required by the backend body. The backend
  /// treats start/endDate as dates, not timestamps.
  String _dateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  // ── Read ────────────────────────────────────────────────────────────────────

  /// Trainer or self-athlete may call this. Returns blocks sorted ascending.
  Future<List<TrainingBlockModel>> getForAthlete(String athleteId) async {
    try {
      final res = await _client.dio
          .get(ApiConstants.trainingBlocksForAthlete(athleteId));
      final list = res.data as List;
      final items = list
          .map((e) =>
              TrainingBlockModel.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
      return items;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw const TrainingBlockForbiddenException();
      }
      rethrow;
    }
  }

  // ── Write (trainer-only on the server) ──────────────────────────────────────

  Future<TrainingBlockModel> create({
    required String athleteId,
    required String focus,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
  }) async {
    try {
      final res = await _client.dio.post(
        ApiConstants.trainingBlock,
        data: {
          'athleteId': athleteId,
          'focus': focus,
          'startDate': _dateOnly(startDate),
          'endDate': _dateOnly(endDate),
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      return TrainingBlockModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _mapWriteError(e); // returns Never — throws a typed exception
    }
  }

  Future<TrainingBlockModel> update(
    String id, {
    required String focus,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
  }) async {
    try {
      final res = await _client.dio.put(
        ApiConstants.trainingBlockById(id),
        data: {
          // athleteId ignored on PUT per spec; omit.
          'focus': focus,
          'startDate': _dateOnly(startDate),
          'endDate': _dateOnly(endDate),
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      return TrainingBlockModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _mapWriteError(e); // returns Never — throws a typed exception
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.dio.delete(ApiConstants.trainingBlockById(id));
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw const TrainingBlockForbiddenException();
      }
      rethrow;
    }
  }

  /// Translates backend write errors into typed exceptions the UI can branch on.
  Never _mapWriteError(DioException e) {
    final code = e.response?.statusCode;
    final body = e.response?.data;
    String? msg;
    if (body is Map && body['message'] is String) {
      msg = body['message'] as String;
    }
    if (code == 409) {
      throw TrainingBlockOverlapException(
        msg ?? 'Block overlaps an existing block for this athlete.',
      );
    }
    if (code == 400) {
      throw TrainingBlockValidationException(
        msg ?? "'endDate' must be on or after 'startDate'.",
      );
    }
    if (code == 403) {
      throw const TrainingBlockForbiddenException();
    }
    throw e;
  }
}
