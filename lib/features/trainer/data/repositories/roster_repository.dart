import 'package:flutter_application_1/core/api/api_client.dart';
import 'package:flutter_application_1/core/api/api_constants.dart';
import 'package:flutter_application_1/features/trainer/data/models/trainer_request_model.dart';

class RosterRepository {
  final ApiClient _client;
  RosterRepository(this._client);

  Future<PaginatedAthletes> getAthletes({int page = 1, int pageSize = 20}) async {
    final res = await _client.dio.get(
      ApiConstants.myAthletes,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return PaginatedAthletes.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AthleteModel> createAthlete({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final res = await _client.dio.post(
      ApiConstants.createAthlete,
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
      },
    );
    return AthleteModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AthleteModel> updateAthlete(
    String id, {
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    final res = await _client.dio.put(
      ApiConstants.athlete(id),
      data: {'firstName': firstName, 'lastName': lastName, 'email': email},
    );
    return AthleteModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> resetAthletePassword(String id, String newPassword) async {
    await _client.dio.post(
      ApiConstants.resetAthletePassword(id),
      data: {'newPassword': newPassword},
    );
  }

  Future<void> deleteAthlete(String id) async {
    await _client.dio.delete(ApiConstants.athlete(id));
  }
}
