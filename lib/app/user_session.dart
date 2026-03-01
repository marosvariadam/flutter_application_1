import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserSession {
  static final UserSession _instance = UserSession._();
  static UserSession get instance => _instance;
  UserSession._();

  String? _role;
  String? _userId;

  bool get isCoach => _role?.toLowerCase() == 'trainer';
  String? get role => _role;
  String? get userId => _userId;

  void set({required String role, required String userId}) {
    _role = role;
    _userId = userId;
  }

  Future<void> loadFromStorage() async {
    const storage = FlutterSecureStorage();
    _role = await storage.read(key: 'user_role');
    _userId = await storage.read(key: 'user_id');
  }

  void clear() {
    _role = null;
    _userId = null;
  }
}
