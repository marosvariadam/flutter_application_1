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

  factory AuthTokens.fromJson(Map<String, dynamic> j) {
    // Accept both 'token' and 'accessToken' keys from backend
    final token = (j['token'] ?? j['accessToken']) as String?;
    final userId = (j['userId'] ?? j['id']) as String?;
    final role = j['role'] as String?;

    if (token == null || userId == null || role == null) {
      throw FormatException(
        'Hiányzó mezők a válaszban: token=${token != null}, '
        'userId=${userId != null}, role=${role != null}. '
        'Kapott kulcsok: ${j.keys.toList()}',
      );
    }

    return AuthTokens(
      accessToken: token,
      userId: userId,
      role: role,
    );
  }
}
