import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/autoregulation/data/models/autoregulation_model.dart';

Map<String, dynamic> _fullPayload() => {
      'planId': 'p1',
      'deloadApplied': false,
      'suggestions': [
        {
          'exerciseId': 'e1',
          'name': 'Bench Press',
          'muscleGroup': 'Chest',
          'scheme': 'DoubleProgression',
          'currentReps': '6-10',
          'targetRpe': 8,
          'suggestedWeightKg': 82.5,
          'suggestedSets': 3,
          'outcome': 'Increase',
          'reason': 'All sets hit 10 reps at RPE ≤ 8; add 2.5 kg.',
          'lastLogged': {
            'date': '2026-11-12T17:30:00Z',
            'sets': 3,
            'reps': 10,
            'weightKg': 80.0,
            'rpe': 7.5,
          },
        },
        {
          'exerciseId': null,
          'name': 'Back Squat',
          'muscleGroup': 'Legs',
          'scheme': 'DoubleProgression',
          'currentReps': '5-8',
          'targetRpe': 8,
          'suggestedWeightKg': null,
          'suggestedSets': 4,
          'outcome': 'Hold',
          'reason': 'No logged session yet.',
          'lastLogged': null,
        },
      ],
    };

void main() {
  group('NextWeekAutoregulationModel', () {
    test('fromJson parses plan, deload flag and suggestions', () {
      final m = NextWeekAutoregulationModel.fromJson(_fullPayload());

      expect(m.planId, 'p1');
      expect(m.hasPlan, isTrue);
      expect(m.deloadApplied, isFalse);
      expect(m.suggestions, hasLength(2));

      final bench = m.suggestions.first;
      expect(bench.exerciseId, 'e1');
      expect(bench.currentReps, '6-10');
      expect(bench.targetRpe, 8);
      expect(bench.suggestedWeightKg, 82.5);
      expect(bench.outcome, AutoregulationOutcomes.increase);
      expect(bench.lastLogged!.weightKg, 80.0);
      expect(bench.lastLogged!.rpe, 7.5);
      expect(bench.lastLogged!.date, DateTime.utc(2026, 11, 12, 17, 30));
      expect(bench.deltaKg, 2.5);
      expect(bench.isActionable, isTrue);

      final squat = m.suggestions.last;
      expect(squat.exerciseId, isNull);
      expect(squat.lastLogged, isNull);
      expect(squat.deltaKg, isNull);
      expect(squat.isActionable, isFalse);
    });

    test('fromJson/toJson round-trip is stable', () {
      final a = NextWeekAutoregulationModel.fromJson(_fullPayload());
      final b = NextWeekAutoregulationModel.fromJson(a.toJson());

      expect(b.planId, a.planId);
      expect(b.deloadApplied, a.deloadApplied);
      expect(b.suggestions.length, a.suggestions.length);
      for (var i = 0; i < a.suggestions.length; i++) {
        final x = a.suggestions[i];
        final y = b.suggestions[i];
        expect(y.exerciseId, x.exerciseId);
        expect(y.name, x.name);
        expect(y.muscleGroup, x.muscleGroup);
        expect(y.scheme, x.scheme);
        expect(y.currentReps, x.currentReps);
        expect(y.targetRpe, x.targetRpe);
        expect(y.suggestedWeightKg, x.suggestedWeightKg);
        expect(y.suggestedSets, x.suggestedSets);
        expect(y.outcome, x.outcome);
        expect(y.reason, x.reason);
        expect(y.lastLogged?.date, x.lastLogged?.date);
        expect(y.lastLogged?.weightKg, x.lastLogged?.weightKg);
        expect(y.lastLogged?.rpe, x.lastLogged?.rpe);
      }
    });

    test('no-plan payload (no deloadApplied key) parses as empty', () {
      final m = NextWeekAutoregulationModel.fromJson({
        'planId': null,
        'suggestions': <dynamic>[],
      });

      expect(m.hasPlan, isFalse);
      expect(m.deloadApplied, isFalse);
      expect(m.suggestions, isEmpty);
    });

    test('suggestionFor matches by id first, then by name', () {
      final m = NextWeekAutoregulationModel.fromJson(_fullPayload());

      expect(m.suggestionFor(exerciseId: 'e1', name: 'Renamed')?.name,
          'Bench Press');
      // Id unknown to the plan → case-insensitive name fallback.
      expect(m.suggestionFor(exerciseId: 'other', name: ' back squat ')?.name,
          'Back Squat');
      expect(m.suggestionFor(exerciseId: '', name: 'BENCH PRESS')?.exerciseId,
          'e1');
      expect(m.suggestionFor(exerciseId: 'x', name: 'Deadlift'), isNull);
    });
  });
}
