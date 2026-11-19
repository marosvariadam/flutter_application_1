import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/training_plan/data/models/plan_results.dart';
import 'package:flutter_application_1/features/training_plan/data/models/violation_model.dart';

Map<String, dynamic> _plan() => {
      'id': 'p1',
      'trainerId': 't1',
      'athleteId': 'a1',
      'title': 'T',
      'goal': 'Hypertrophy',
      'weeks': 4,
      'split': 'UpperLower',
      'status': 'Draft',
      'progression': 'DoubleProgression',
      'source': 'Hybrid',
      'createdAt': '2026-10-01T12:00:00Z',
      'days': [],
    };

void main() {
  group('GenerateResultModel', () {
    final full = {
      'plan': _plan(),
      'predictedScore': 0.78,
      'usedPredictor': true,
      'warnings': [
        {
          'code': 'FREQUENCY_TOO_LOW',
          'severity': 'Warning',
          'message': 'Chest trained < 2x/week',
        },
      ],
      'errors': [
        {
          'code': 'VOLUME_ABOVE_MRV',
          'severity': 'Error',
          'message': 'Shoulders weekly sets above MRV',
          'dayIndex': 1,
        },
      ],
      'candidatesSummary': [
        {
          'title': 'Candidate A',
          'score': 0.78,
          'usedPredictor': true,
          'daysCount': 4,
        },
        {
          'title': 'Candidate B',
          'score': 0.71,
          'usedPredictor': true,
          'daysCount': 4,
        },
      ],
    };

    test('fromJson parses plan, violations, and candidates', () {
      final r = GenerateResultModel.fromJson(full);
      expect(r.plan.title, 'T');
      expect(r.predictedScore, 0.78);
      expect(r.usedPredictor, isTrue);
      expect(r.warnings.single.code, ViolationCodes.frequencyTooLow);
      expect(r.errors.single.severity, ViolationSeverity.error);
      expect(r.candidates, hasLength(2));
      expect(r.candidates.first.score, 0.78);
    });

    test('round-trip is stable', () {
      final a = GenerateResultModel.fromJson(full);
      final b = GenerateResultModel.fromJson(a.toJson());
      expect(b.predictedScore, a.predictedScore);
      expect(b.warnings.single.code, a.warnings.single.code);
      expect(b.errors.single.dayIndex, a.errors.single.dayIndex);
      expect(b.candidates.length, a.candidates.length);
      expect(b.candidates.last.title, a.candidates.last.title);
    });
  });

  group('RefineResultModel', () {
    final full = {
      'plan': _plan(),
      'warnings': [],
      'errors': [],
      'diff': [
        {
          'dayIndex': 0,
          'added': ['e1:3x8-12@7'],
          'removed': ['e2:3x8-12@7'],
        }
      ],
    };

    test('fromJson parses diff entries', () {
      final r = RefineResultModel.fromJson(full);
      expect(r.diff, hasLength(1));
      expect(r.diff.first.added, ['e1:3x8-12@7']);
      expect(r.diff.first.removed, ['e2:3x8-12@7']);
    });

    test('round-trip is stable', () {
      final a = RefineResultModel.fromJson(full);
      final b = RefineResultModel.fromJson(a.toJson());
      expect(b.diff.first.added, a.diff.first.added);
      expect(b.diff.first.removed, a.diff.first.removed);
    });
  });

  group('MaterializeResultModel', () {
    final full = {
      'planId': 'p1',
      'workoutsCreated': 16,
      'scheduledWindow': {
        'from': '2026-11-20T00:00:00Z',
        'to': '2026-12-18T00:00:00Z',
      },
    };

    test('fromJson parses the scheduled window', () {
      final r = MaterializeResultModel.fromJson(full);
      expect(r.planId, 'p1');
      expect(r.workoutsCreated, 16);
      expect(r.scheduledFrom.year, 2026);
      expect(r.scheduledTo.month, 12);
    });

    test('round-trip is stable', () {
      final a = MaterializeResultModel.fromJson(full);
      final b = MaterializeResultModel.fromJson(a.toJson());
      expect(b.scheduledFrom, a.scheduledFrom);
      expect(b.scheduledTo, a.scheduledTo);
      expect(b.workoutsCreated, a.workoutsCreated);
    });
  });

  group('ValidationResultModel', () {
    test('fromJson splits warnings and errors by severity', () {
      final r = ValidationResultModel.fromJson({
        'warnings': [
          {
            'code': 'PATTERN_IMBALANCE',
            'severity': 'Warning',
            'message': 'Push/pull ratio off',
          },
        ],
        'errors': [
          {
            'code': 'UNKNOWN_EXERCISE',
            'severity': 'Error',
            'message': 'exerciseId missing',
          },
        ],
      });
      expect(r.warnings.single.isWarning, isTrue);
      expect(r.errors.single.isError, isTrue);
    });
  });

  group('PlanExplanationModel', () {
    test('round-trip is stable', () {
      final a = PlanExplanationModel.fromJson({
        'planId': 'p1',
        'language': 'hu',
        'explanation': 'A terv…',
      });
      final b = PlanExplanationModel.fromJson(a.toJson());
      expect(b.planId, 'p1');
      expect(b.language, 'hu');
      expect(b.explanation, 'A terv…');
    });
  });
}
