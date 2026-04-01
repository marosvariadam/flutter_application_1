import 'package:flutter_application_1/core/api/api_client.dart';
import 'package:flutter_application_1/core/api/api_constants.dart';
import 'package:flutter_application_1/core/storage/token_storage.dart';
import 'package:flutter_application_1/features/user/data/models/user_model.dart';

class UserRepository {
  final ApiClient _client;
  UserRepository(this._client);

  Future<UserModel> getUser(String id) async {
    final res = await _client.dio.get(ApiConstants.userById(id));
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<UserModel> updateUser({
    required String firstName,
    required String lastName,
    required String email,
    double? weightKg,
  }) async {
    final id = await TokenStorage.getUserId();
    final body = {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      if (weightKg != null) 'weightKg': weightKg,
    };
    final res = await _client.dio.put(ApiConstants.updateUser(id ?? ''), data: body);
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// Not supported by current backend — throws if called.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    throw UnimplementedError(
        'Change password is not yet supported by the backend.');
  }

  Future<void> deleteAccount() async {
    final id = await TokenStorage.getUserId();
    await _client.dio.delete(ApiConstants.deleteUser(id ?? ''));
  }
}
