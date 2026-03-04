import 'package:flutter_application_1/core/api/api_client.dart';
import 'package:flutter_application_1/core/api/api_constants.dart';
import 'package:flutter_application_1/features/onboarding/data/models/onboarding_models.dart';

class OnboardingRepository {
  final ApiClient _client;
  OnboardingRepository(this._client);

  // ── Trainer ────────────────────────────────────────────────────────────────

  Future<OnboardingFormModel?> getMyForm() async {
    try {
      final res = await _client.dio.get(ApiConstants.onboardingMine);
      return OnboardingFormModel.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<OnboardingFormModel> saveForm({
    required String title,
    String? description,
    required List<OnboardingQuestion> questions,
  }) async {
    final res = await _client.dio.put(ApiConstants.onboardingForm, data: {
      'title': title,
      if (description != null) 'description': description,
      'questions': questions.map((q) => q.toJson()).toList(),
    });
    return OnboardingFormModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<OnboardingResponse>> getAllResponses() async {
    final res = await _client.dio.get(ApiConstants.onboardingResponses);
    return (res.data as List)
        .map((e) =>
            OnboardingResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OnboardingResponse> getAthleteResponse(String athleteId) async {
    final res = await _client.dio
        .get(ApiConstants.onboardingAthleteResponse(athleteId));
    return OnboardingResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // ── Athlete ────────────────────────────────────────────────────────────────

  Future<OnboardingFormModel?> getMyTrainerForm() async {
    try {
      final res = await _client.dio.get(ApiConstants.onboardingMyForm);
      return OnboardingFormModel.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> submitAnswers(List<OnboardingAnswer> answers) async {
    await _client.dio.post(ApiConstants.onboardingSubmit,
        data: {'answers': answers.map((a) => a.toJson()).toList()});
  }

  Future<OnboardingResponse?> getMyResponse() async {
    try {
      final res = await _client.dio.get(ApiConstants.onboardingMyResponse);
      return OnboardingResponse.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
