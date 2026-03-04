import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const _base = 'http://10.0.2.2:5233';

  static final ApiClient instance = ApiClient._();
  ApiClient._();

  final _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: 'jwt_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String path) async {
    return http.get(Uri.parse('$_base$path'), headers: await _headers());
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    return http.post(
      Uri.parse('$_base$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
  }
}
