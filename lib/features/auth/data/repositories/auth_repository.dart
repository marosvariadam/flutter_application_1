import 'package:flutter_application_1/core/api/api_client.dart';
import 'package:flutter_application_1/core/api/api_constants.dart';
import 'package:flutter_application_1/core/storage/token_storage.dart';
import 'package:flutter_application_1/features/auth/data/models/auth_tokens.dart';
import 'package:flutter_application_1/features/user/data/models/user_model.dart';

class AuthRepository {
  final ApiClient _client;
  AuthRepository(this._client);

  Future<AuthTokens> login(String email, String password) async {
    final res = await _client.dio.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
    final tokens = AuthTokens.fromJson(res.data as Map<String, dynamic>);
    await TokenStorage.saveTokens(tokens.accessToken, tokens.refreshToken);
    await TokenStorage.saveUserInfo(tokens.user.id, tokens.user.role);
    return tokens;
  }

  Future<void> logout() async {
    try {
      await _client.dio.post(ApiConstants.logout);
    } catch (_) {}
    await TokenStorage.clearAll();
  }

  Future<void> registerTrainer({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    await _client.dio.post(ApiConstants.registerTrainer, data: {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
    });
  }

  Future<void> registerAthlete({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? trainerEmail,
    String? introNote,
  }) async {
    await _client.dio.post(ApiConstants.registerAthlete, data: {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      if (trainerEmail != null) 'trainerEmail': trainerEmail,
      if (introNote != null) 'introNote': introNote,
    });
  }

  /// Returns a minimal UserModel built from stored user info (no network call).
  Future<UserModel?> getCachedUser() async {
    final id = await TokenStorage.getUserId();
    final role = await TokenStorage.getUserRole();
    if (id == null || role == null) return null;
    return UserModel(
      id: id,
      firstName: '',
      lastName: '',
      email: '',
      role: role,
    );
  }
}
