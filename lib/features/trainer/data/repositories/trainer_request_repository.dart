import 'package:flutter_application_1/core/api/api_client.dart';
import 'package:flutter_application_1/core/api/api_constants.dart';
import 'package:flutter_application_1/features/trainer/data/models/trainer_request_model.dart';

class TrainerRequestRepository {
  final ApiClient _client;
  TrainerRequestRepository(this._client);

  /// Athlete: POST /api/trainer-request
  Future<TrainerRequestModel> sendRequest(
      String trainerEmail, {String? note}) async {
    final res = await _client.dio.post(
      ApiConstants.trainerRequest,
      data: {
        'trainerEmail': trainerEmail,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return TrainerRequestModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// Athlete: GET /api/trainer-request/mine
  Future<List<TrainerRequestModel>> getMyRequests() async {
    final res = await _client.dio.get(ApiConstants.myTrainerRequests);
    return (res.data as List)
        .map((e) =>
            TrainerRequestModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Trainer: GET /api/trainer-request/pending
  Future<List<TrainerRequestModel>> getPendingRequests() async {
    final res = await _client.dio.get(ApiConstants.pendingRequests);
    return (res.data as List)
        .map((e) =>
            TrainerRequestModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Trainer: PATCH /api/trainer-request/{id}/accept
  Future<void> acceptRequest(String id) async {
    await _client.dio.patch(ApiConstants.acceptRequest(id));
  }

  /// Trainer: PATCH /api/trainer-request/{id}/reject
  Future<void> rejectRequest(String id) async {
    await _client.dio.patch(ApiConstants.rejectRequest(id));
  }

  /// Athlete: DELETE /api/trainer-request/{id}
  Future<void> cancelRequest(String id) async {
    await _client.dio.delete(ApiConstants.cancelRequest(id));
  }
}
