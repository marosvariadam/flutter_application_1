import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/training_plan/data/models/training_plan_model.dart';

void main() {
  group('TrainingPlanModel', () {
    final full = {
      'id': 'p1',
      'trainerId': 't1',
      'athleteId': 'a1',
      'trainingBlockId': 'tb1',
      'title': 'Hypertrophy — 4 week',
      'goal': 'Hypertrophy',
      'weeks': 4,
      'split': 'UpperLower',
      'status': 'Draft',
      'progression': 'DoubleProgression',
      'source': 'Hybrid',
      'createdAt': '2026-10-01T12:00:00Z',
      'acceptedAt': null,
      'days': [
        {
          'dayIndex': 0,
          'label': 'Upper A',
          'exercises': [
            {
              'exerciseId': 'e1',
              'name': 'Bench Press',
              'muscleGroup': 'Chest',
              'sets': 3,
              'repMin': 6,
              'repMax': 10,
              'targetRpe': 8,
              'restSeconds': 120,
              'order': 0,
              'notes': 'Keep elbows tucked.',
            },
          ],
        },
      ],
    };

    test('fromJson parses the full backend shape', () {
      final p = TrainingPlanModel.fromJson(full);
      expect(p.id, 'p1');
      expect(p.goal, 'Hypertrophy');
      expect(p.split, PlanSplits.upperLower);
      expect(p.status, PlanStatuses.draft);
      expect(p.source, PlanGenerationSources.hybrid);
      expect(p.weeks, 4);
      expect(p.trainingBlockId, 'tb1');
      expect(p.days, hasLength(1));
      expect(p.days.first.label, 'Upper A');
      expect(p.days.first.exercises.first.prescription, '3 × 6–10 @ RPE 8');
      expect(p.totalExercises, 1);
    });

    test('fromJson/toJson round-trip is stable', () {
      final a = TrainingPlanModel.fromJson(full);
      final b = TrainingPlanModel.fromJson(a.toJson());
      expect(b.id, a.id);
      expect(b.title, a.title);
      expect(b.split, a.split);
      expect(b.status, a.status);
      expect(b.source, a.source);
      expect(b.weeks, a.weeks);
      expect(b.days.length, a.days.length);
      expect(b.days.first.exercises.first.name,
          a.days.first.exercises.first.name);
      expect(b.days.first.exercises.first.restSeconds,
          a.days.first.exercises.first.restSeconds);
    });

    test('fromJson falls back to defaults when fields are missing', () {
      final p = TrainingPlanModel.fromJson({'id': 'p2'});
      expect(p.trainerId, '');
      expect(p.athleteId, '');
      expect(p.title, '');
      expect(p.weeks, 0);
      expect(p.split, PlanSplits.fullBody);
      expect(p.status, PlanStatuses.draft);
      expect(p.source, PlanGenerationSources.manual);
      expect(p.days, isEmpty);
    });

    test('PlannedExerciseModel collapses equal rep min/max in prescription',
        () {
      final e = PlannedExerciseModel.fromJson({
        'name': 'Deadlift',
        'muscleGroup': 'Back',
        'sets': 5,
        'repMin': 5,
        'repMax': 5,
        'targetRpe': 8,
        'restSeconds': 180,
        'order': 0,
      });
      expect(e.prescription, '5 × 5 @ RPE 8');
    });
  });
}
