import 'package:flutter_application_1/features/user/data/models/user_model.dart';

/// Matches the backend login response: { "token": "...", "userId": "...", "role": "..." }
class AuthTokens {
  final String accessToken;
  final String userId;
  final String role;

  const AuthTokens({
    required this.accessToken,
    required this.userId,
    required this.role,
  });

  /// Minimal UserModel so AuthBloc can call getUser(tokens.user.id) unchanged.
  UserModel get user => UserModel(
        id: userId,
        firstName: '',
        lastName: '',
        email: '',
        role: role,
      );

  factory AuthTokens.fromJson(Map<String, dynamic> j) => AuthTokens(
        accessToken: j['token'] as String,
        userId: j['userId'] as String,
        role: j['role'] as String,
      );
}
