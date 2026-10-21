import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/api/api_client.dart';
import 'package:flutter_application_1/core/api/api_constants.dart';
import 'package:flutter_application_1/features/athlete_profile/data/models/athlete_profile_model.dart';

/// 403 — trainer isn't linked to this athlete, so they can't read/write the
/// profile. The caller decides how to surface this (we don't want a snackbar
/// here because the gate screens handle 403 differently from the detail page).
class AthleteProfileForbiddenException implements Exception {
  const AthleteProfileForbiddenException();
}

/// 401 — the client is unauthenticated (e.g. the survey ran before login
/// completed). Separate from forbidden so the survey can fall back to local
/// storage without complaining.
class AthleteProfileUnauthorizedException implements Exception {
  const AthleteProfileUnauthorizedException();
}

class AthleteProfileRepository {
  final ApiClient _client;
  AthleteProfileRepository(this._client);

  /// Reads the authenticated athlete's own profile. Returns null on 404 (the
  /// athlete hasn't filled in the structured survey yet).
  Future<AthleteProfileModel?> getMine() async {
    try {
      final res = await _client.dio.get(ApiConstants.athleteProfileMine);
      return AthleteProfileModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 404) return null;
      if (code == 401) throw const AthleteProfileUnauthorizedException();
      rethrow;
    }
  }

  Future<AthleteProfileModel?> getForAthlete(String athleteId) async {
    try {
      final res = await _client.dio
          .get(ApiConstants.athleteProfileForAthlete(athleteId));
      return AthleteProfileModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 404) return null;
      if (code == 403) throw const AthleteProfileForbiddenException();
      if (code == 401) throw const AthleteProfileUnauthorizedException();
      rethrow;
    }
  }

  /// Upserts the signed-in athlete's profile. Returns the stored copy.
  Future<AthleteProfileModel> upsertMine(AthleteProfileModel profile) async {
    try {
      final res = await _client.dio.put(
        ApiConstants.athleteProfileMine,
        data: profile.toRequestJson(),
      );
      return AthleteProfileModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401) throw const AthleteProfileUnauthorizedException();
      rethrow;
    }
  }

  Future<AthleteProfileModel> upsertForAthlete(
      String athleteId, AthleteProfileModel profile) async {
    try {
      final res = await _client.dio.put(
        ApiConstants.athleteProfileForAthlete(athleteId),
        data: profile.toRequestJson(),
      );
      return AthleteProfileModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 403) throw const AthleteProfileForbiddenException();
      if (code == 401) throw const AthleteProfileUnauthorizedException();
      rethrow;
    }
  }
}
