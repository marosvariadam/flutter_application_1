import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserSession {
  static final UserSession _instance = UserSession._();
  static UserSession get instance => _instance;
  UserSession._();

  String? _role;
  String? _userId;
  String? _firstName;
  String? _lastName;
  String? _email;

  bool get isCoach => _role?.toLowerCase() == 'trainer';
  String? get role => _role;
  String? get userId => _userId;
  String? get firstName => _firstName;
  String? get lastName => _lastName;
  String? get email => _email;

  String get displayName {
    final parts = [_firstName, _lastName]
        .where((s) => s != null && s.isNotEmpty)
        .toList();
    return parts.join(' ');
  }

  String get initials {
    final f = (_firstName?.isNotEmpty == true) ? _firstName![0].toUpperCase() : '';
    final l = (_lastName?.isNotEmpty == true) ? _lastName![0].toUpperCase() : '';
    return f + l;
  }

  void set({
    required String role,
    required String userId,
    String? firstName,
    String? lastName,
    String? email,
  }) {
    _role = role;
    _userId = userId;
    _firstName = firstName;
    _lastName = lastName;
    _email = email;
  }

  Future<void> loadFromStorage() async {
    const storage = FlutterSecureStorage();
    _role = await storage.read(key: 'user_role');
    _userId = await storage.read(key: 'user_id');
    _firstName = await storage.read(key: 'first_name');
    _lastName = await storage.read(key: 'last_name');
    _email = await storage.read(key: 'user_email');
  }

  void clear() {
    _role = null;
    _userId = null;
    _firstName = null;
    _lastName = null;
    _email = null;
  }
}
