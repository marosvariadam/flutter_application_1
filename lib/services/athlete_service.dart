import 'dart:convert';
import 'package:flutter_application_1/features/coach/data/models/athlete_model.dart';
import 'package:flutter_application_1/services/api_client.dart';

class AthleteService {
  final _api = ApiClient.instance;

  /// Returns the athletes assigned to the currently logged-in coach.
  Future<List<AthleteModel>> getMyAthletes() async {
    try {
      final response = await _api.get('/users/athletes');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body) as List;
        return data
            .map((j) => AthleteModel.fromJson(j as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Returns a single athlete by ID.
  Future<AthleteModel?> getAthleteById(String id) async {
    try {
      final response = await _api.get('/users/$id');
      if (response.statusCode == 200) {
        return AthleteModel.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
