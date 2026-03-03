import 'package:flutter_application_1/core/api/api_client.dart';
import 'package:flutter_application_1/core/api/api_constants.dart';
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
  }) async {
    final res = await _client.dio.put(ApiConstants.me, data: {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
    });
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.dio.post(ApiConstants.changePassword, data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<void> deleteAccount() async {
    await _client.dio.delete(ApiConstants.me);
  }
}
