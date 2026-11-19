import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/athlete_profile/data/models/athlete_profile_model.dart';
import 'package:flutter_application_1/features/athlete_profile/data/repositories/athlete_profile_repository.dart';

import '../../../../helpers/fake_http.dart';

const _json = {
  'id': 'p1',
  'athleteId': 'a1',
  'goal': 'Strength',
  'experienceLevel': 'Intermediate',
  'daysPerWeek': 4,
  'sessionMinutes': 75,
  'availableEquipment': ['Barbell'],
  'avoidStressTags': ['knee'],
  'excludedExerciseIds': <String>[],
  'muscleGroupPriority': {'Legs': 1.2},
};

void main() {
  late FakeHttpAdapter http;
  late AthleteProfileRepository repo;

  setUp(() {
    http = FakeHttpAdapter();
    repo = AthleteProfileRepository(fakeApiClient(http));
  });

  group('getMine', () {
    test('parses the profile', () async {
      http.handler = (_) => const FakeResponse(200, _json);
      final p = await repo.getMine();
      expect(http.last.path, '/api/athleteprofile/me');
      expect(p!.goal, AthleteProfileGoals.strength);
      expect(p.muscleGroupPriority, {'Legs': 1.2});
    });

    test('404 means no profile yet', () async {
      http.handler = (_) => const FakeResponse(404);
      expect(await repo.getMine(), isNull);
    });

    test('401 maps to Unauthorized', () async {
      http.handler = (_) => const FakeResponse(401);
      await expectLater(repo.getMine(),
          throwsA(isA<AthleteProfileUnauthorizedException>()));
    });

    test('500 is rethrown', () async {
      http.handler = (_) => const FakeResponse(500);
      await expectLater(repo.getMine(), throwsA(isA<DioException>()));
    });
  });

  group('getForAthlete', () {
    test('uses the athlete path, 404 → null, 403 → Forbidden', () async {
      http.handler = (_) => const FakeResponse(404);
      expect(await repo.getForAthlete('a9'), isNull);
      expect(http.last.path, '/api/athleteprofile/a9');

      http.handler = (_) => const FakeResponse(403);
      await expectLater(repo.getForAthlete('a9'),
          throwsA(isA<AthleteProfileForbiddenException>()));
    });
  });

  group('upserts', () {
    final profile = AthleteProfileModel.fromJson(_json);

    test('upsertMine PUTs the request payload without server fields',
        () async {
      http.handler = (_) => const FakeResponse(200, _json);
      await repo.upsertMine(profile);
      expect(http.last.method, 'PUT');
      expect(http.last.path, '/api/athleteprofile/me');
      expect(http.last.data, profile.toRequestJson());
      expect((http.last.data as Map).containsKey('id'), isFalse);
    });

    test('upsertMine 401 maps to Unauthorized', () async {
      http.handler = (_) => const FakeResponse(401);
      await expectLater(repo.upsertMine(profile),
          throwsA(isA<AthleteProfileUnauthorizedException>()));
    });

    test('upsertForAthlete 403 maps to Forbidden', () async {
      http.handler = (_) => const FakeResponse(403);
      await expectLater(repo.upsertForAthlete('a1', profile),
          throwsA(isA<AthleteProfileForbiddenException>()));
      expect(http.last.path, '/api/athleteprofile/a1');
    });
  });
}
