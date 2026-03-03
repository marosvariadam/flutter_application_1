import 'package:flutter_application_1/features/user/data/models/user_model.dart';

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> j) => AuthTokens(
        accessToken: j['accessToken'] as String,
        refreshToken: j['refreshToken'] as String,
        user: UserModel.fromJson(j['user'] as Map<String, dynamic>),
      );
}
