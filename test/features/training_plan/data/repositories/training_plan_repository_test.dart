import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/training_plan/data/models/training_plan_model.dart';
import 'package:flutter_application_1/features/training_plan/data/repositories/training_plan_repository.dart';

import '../../../../helpers/fake_http.dart';

Map<String, dynamic> _planJson({String id = 'p1', String status = 'Draft'}) =>
    {
      'id': id,
      'trainerId': 't1',
      'athleteId': 'a1',
      'title': 'Terv',
      'goal': 'Hypertrophy',
      'weeks': 4,
      'split': 'UpperLower',
      'status': status,
      'progression': 'DoubleProgression',
      'source': 'Hybrid',
      'createdAt': '2026-11-01T10:00:00Z',
      'days': [
        {
          'dayIndex': 0,
          'label': 'Felső A',
          'exercises': [
            {
              'exerciseId': 'e1',
              'name': 'Fekvenyomás',
              'muscleGroup': 'Chest',
              'sets': 3,
              'repMin': 6,
              'repMax': 10,
              'targetRpe': 8,
              'restSeconds': 120,
              'order': 0,
            }
          ],
        }
      ],
    };

Map<String, dynamic> _violations() => {
      'warnings': [
        {'code': 'FREQUENCY_TOO_LOW', 'severity': 'Warning', 'message': 'w'}
      ],
      'errors': <dynamic>[],
    };

void main() {
  late FakeHttpAdapter http;
  late TrainingPlanRepository repo;

  setUp(() {
    http = FakeHttpAdapter();
    repo = TrainingPlanRepository(fakeApiClient(http));
  });

  group('requests', () {
    test('generate posts the form and waits up to 60 s for the LLM', () async {
      http.handler = (_) => FakeResponse(200, {
            'plan': _planJson(),
            'predictedScore': 0.8,
            'usedPredictor': true,
            'warnings': <dynamic>[],
            'errors': <dynamic>[],
            'candidatesSummary': <dynamic>[],
          });

      final r = await repo.generate(athleteId: 'a1', mode: 'Hybrid', weeks: 6);

      expect(http.last.method, 'POST');
      expect(http.last.path, '/api/plan/generate');
      expect(http.last.data,
          {'athleteId': 'a1', 'mode': 'Hybrid', 'weeks': 6});
      expect(http.last.receiveTimeout, const Duration(seconds: 60));
      expect(r.plan.id, 'p1');
      expect(r.predictedScore, 0.8);
    });

    test('generate sends the training block only when one is chosen',
        () async {
      http.handler = (_) => FakeResponse(200, {'plan': _planJson()});
      await repo.generate(
          athleteId: 'a1', mode: 'Constraint', trainingBlockId: 'b1');
      expect((http.last.data as Map)['trainingBlockId'], 'b1');
      expect((http.last.data as Map).containsKey('weeks'), isFalse);

      await repo.generate(athleteId: 'a1', mode: 'Constraint', trainingBlockId: '');
      expect((http.last.data as Map).containsKey('trainingBlockId'), isFalse);
    });

    test('refine posts the instruction with the long timeout', () async {
      http.handler = (_) => FakeResponse(200, {
            'plan': _planJson(),
            ..._violations(),
            'diff': [
              {'dayIndex': 0, 'added': ['x'], 'removed': <dynamic>[]}
            ],
          });

      final r = await repo.refine(planId: 'p1', instruction: 'több váll');

      expect(http.last.path, '/api/plan/p1/refine');
      expect(http.last.data, {'instruction': 'több váll'});
      expect(http.last.receiveTimeout, const Duration(seconds: 60));
      expect(r.diff.single.dayIndex, 0);
      expect(r.warnings.single.code, 'FREQUENCY_TOO_LOW');
    });

    test('update PUTs only the given fields with serialized days', () async {
      http.handler = (_) => FakeResponse(200, {'plan': _planJson(), ..._violations()});
      final plan = TrainingPlanModel.fromJson(_planJson());

      await repo.update(planId: 'p1', days: plan.days);

      expect(http.last.method, 'PUT');
      expect(http.last.path, '/api/plan/p1');
      final body = http.last.data as Map;
      expect(body.keys, ['days']);
      expect((body['days'] as List).single['label'], 'Felső A');
      expect(http.last.receiveTimeout, isNot(const Duration(seconds: 60)));
    });

    test('validate, accept and materialize hit their endpoints', () async {
      http.handler = (r) {
        if (r.path.endsWith('/validate')) return FakeResponse(200, _violations());
        if (r.path.endsWith('/accept')) {
          return FakeResponse(200, _planJson(status: 'Accepted'));
        }
        return const FakeResponse(200, {
          'planId': 'p1',
          'workoutsCreated': 12,
          'scheduledWindow': {
            'from': '2026-11-23T00:00:00Z',
            'to': '2026-12-18T00:00:00Z',
          },
        });
      };

      final v = await repo.validate('p1');
      expect(http.last.path, '/api/plan/p1/validate');
      expect(v.warnings, hasLength(1));

      final accepted = await repo.accept('p1');
      expect(http.last.path, '/api/plan/p1/accept');
      expect(accepted.status, PlanStatuses.accepted);

      final m = await repo.materialize(
          planId: 'p1', startDate: DateTime.utc(2026, 11, 23));
      expect(http.last.path, '/api/plan/p1/materialize');
      expect(http.last.data, {'startDate': '2026-11-23T00:00:00.000Z'});
      expect(m.workoutsCreated, 12);
    });

    test('explanation asks in Hungarian by default with the long timeout',
        () async {
      http.handler = (_) => const FakeResponse(200,
          {'planId': 'p1', 'language': 'hu', 'explanation': 'Szöveg'});

      final e = await repo.explanation(planId: 'p1');

      expect(http.last.method, 'GET');
      expect(http.last.path, '/api/plan/p1/explanation');
      expect(http.last.queryParameters, {'language': 'hu'});
      expect(http.last.receiveTimeout, const Duration(seconds: 60));
      expect(e.explanation, 'Szöveg');
    });

    test('forAthlete and mine parse plan lists', () async {
      http.handler = (_) => FakeResponse(200, [_planJson(), _planJson(id: 'p2')]);

      expect((await repo.forAthlete('a1')).map((p) => p.id), ['p1', 'p2']);
      expect(http.last.path, '/api/plan/athlete/a1');

      expect(await repo.mine(), hasLength(2));
      expect(http.last.path, '/api/plan/me');
    });
  });

  group('error mapping', () {
    Future<void> generateWith(int status, [Object? body]) {
      http.handler = (_) => FakeResponse(status, body);
      return repo.generate(athleteId: 'a1', mode: 'Hybrid');
    }

    test('400 carries the server message', () async {
      await expectLater(
        generateWith(400, {'message': 'Invalid trainingBlockId.'}),
        throwsA(isA<PlanValidationException>()
            .having((e) => e.message, 'message', 'Invalid trainingBlockId.')),
      );
    });

    test('400 without a message gets Hungarian default', () async {
      await expectLater(
        generateWith(400),
        throwsA(isA<PlanValidationException>()
            .having((e) => e.message, 'message', 'Érvénytelen adat.')),
      );
    });

    test('403, 404, 409 and 429 map to typed exceptions', () async {
      await expectLater(generateWith(403), throwsA(isA<PlanForbiddenException>()));
      await expectLater(generateWith(404), throwsA(isA<PlanNotFoundException>()));
      await expectLater(
        generateWith(409, {'message': 'Plan already materialized.'}),
        throwsA(isA<PlanConflictException>().having(
            (e) => e.message, 'message', 'Plan already materialized.')),
      );
      await expectLater(
          generateWith(429), throwsA(isA<PlanRateLimitedException>()));
    });

    test('502 and 503 mean the LLM is unavailable on LLM endpoints',
        () async {
      await expectLater(
          generateWith(503), throwsA(isA<PlanLlmUnavailableException>()));
      await expectLater(
          generateWith(502), throwsA(isA<PlanLlmUnavailableException>()));
    });

    test('503 on a non-LLM endpoint stays a plain DioException', () async {
      http.handler = (_) => const FakeResponse(503);
      await expectLater(repo.validate('p1'), throwsA(isA<DioException>()));
    });

    test('500 is rethrown untouched', () async {
      await expectLater(generateWith(500), throwsA(isA<DioException>()));
    });
  });
}
