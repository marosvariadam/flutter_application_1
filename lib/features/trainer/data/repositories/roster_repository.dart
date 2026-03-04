import 'package:flutter_application_1/core/api/api_client.dart';
import 'package:flutter_application_1/core/api/api_constants.dart';
import 'package:flutter_application_1/core/storage/token_storage.dart';
import 'package:flutter_application_1/features/trainer/data/models/trainer_request_model.dart';

class RosterRepository {
  final ApiClient _client;
  RosterRepository(this._client);

  Future<PaginatedAthletes> getAthletes({int page = 1, int pageSize = 20}) async {
    final trainerId = await TokenStorage.getUserId();
    final res = await _client.dio.get(
      ApiConstants.trainerAthletes(trainerId ?? ''),
    );
    // Backend returns plain array — wrap in PaginatedAthletes
    final items = (res.data as List)
        .map((e) => AthleteModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedAthletes(
      items: items,
      total: items.length,
      page: 1,
      pageSize: items.length,
    );
  }

  /// Creates an athlete account via the public register endpoint.
  Future<AthleteModel> createAthlete({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final res = await _client.dio.post(
      ApiConstants.register,
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'role': 'Athlete',
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
      ApiConstants.updateUser(id),
      data: {'firstName': firstName, 'lastName': lastName, 'email': email},
    );
    return AthleteModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteAthlete(String id) async {
    await _client.dio.delete(ApiConstants.deleteUser(id));
  }

  /// Not supported by current backend — no-op.
  Future<void> resetAthletePassword(String id, String newPassword) async {}
}
