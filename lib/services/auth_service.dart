import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  
  static const String _baseUrl = "http://10.0.2.2:5233/api/auth";
  static const String _userUrl = "http://10.0.2.2:5233/api/users";
  
  final _storage = const FlutterSecureStorage();

  // LOGIN
  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save Token + identity
        await _storage.write(key: 'jwt_token', value: data['token']);
        await _storage.write(key: 'user_role', value: data['role']);
        await _storage.write(key: 'user_id', value: data['userId']);
        await _storage.write(key: 'user_email', value: email);
        // Name may come from the JWT payload or a separate profile endpoint;
        // store if the backend includes it in the login response.
        if (data['firstName'] != null) {
          await _storage.write(key: 'first_name', value: data['firstName'].toString());
        }
        if (data['lastName'] != null) {
          await _storage.write(key: 'last_name', value: data['lastName'].toString());
        }

        return true;
      } else {
        return false;
      }
    } catch (e) {
      throw Exception('Connection Error: $e');
    }
  }

  // REGISTER 
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required int role, // 0 = Trainer, 1 = Athlete
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_userUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'passwordHash': password, // Backend expects 'passwordHash' 
          'role': role,
          'assignedTrainerId': null, // Default to null
        }),
      );
      print("Server Response Code: ${response.statusCode}");
      print("Server Response Body: ${response.body}");

      if (response.statusCode == 201) {
        // Cache name + email so the profile page can show real data
        await _storage.write(key: 'first_name', value: firstName);
        await _storage.write(key: 'last_name', value: lastName);
        await _storage.write(key: 'user_email', value: email);
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Registration Error: $e');
    }
  }

  // LOGOUT
  Future<void> logout() async {
    await _storage.deleteAll();
  }
}