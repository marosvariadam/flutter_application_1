import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/autoregulation/data/models/autoregulation_model.dart';
import 'package:flutter_application_1/features/autoregulation/presentation/autoregulation_copy.dart';

AutoregulationSuggestionModel _s({
  double? next,
  double? last,
  double? lastRpe,
  String outcome = AutoregulationOutcomes.increase,
  String scheme = 'DoubleProgression',
  int targetRpe = 8,
  int suggestedSets = 3,
}) =>
    AutoregulationSuggestionModel(
      exerciseId: 'e1',
      name: 'Bench Press',
      muscleGroup: 'Chest',
      scheme: scheme,
      currentReps: '6-10',
      targetRpe: targetRpe,
      suggestedWeightKg: next,
      suggestedSets: suggestedSets,
      outcome: outcome,
      reason: '',
      lastLogged: last == null
          ? null
          : LastLoggedSessionModel(
              date: DateTime.utc(2026, 11, 12),
              sets: 3,
              reps: 10,
              weightKg: last,
              rpe: lastRpe,
            ),
    );

void main() {
  group('formatKg', () {
    test('drops a trailing .0 and keeps one decimal otherwise', () {
      expect(formatKg(80), '80');
      expect(formatKg(82.5), '82.5');
      expect(formatKg(7.5), '7.5');
    });
  });

  group('autoregulationChipLabel', () {
    test('increase shows a signed delta and the target RPE', () {
      expect(autoregulationChipLabel(_s(next: 82.5, last: 80, targetRpe: 7)),
          '+2.5 kg — minden szett RPE 7');
    });

    test('decrease uses a minus sign', () {
      expect(
        autoregulationChipLabel(_s(
            next: 75, last: 80, outcome: AutoregulationOutcomes.decrease)),
        '−5 kg — minden szett RPE 8',
      );
    });

    test('hold says the weight stays', () {
      expect(
        autoregulationChipLabel(
            _s(next: 80, last: 80, outcome: AutoregulationOutcomes.hold)),
        '80 kg marad — minden szett RPE 8',
      );
    });

    test('deload shows the reduced weight and set count', () {
      expect(
        autoregulationChipLabel(_s(
          next: 72.5,
          last: 80,
          outcome: AutoregulationOutcomes.deload,
          suggestedSets: 2,
        )),
        'Deload: 72.5 kg · 2 szett',
      );
    });

    test('without a logged session it shows the absolute weight', () {
      expect(autoregulationChipLabel(_s(next: 60)),
          '60 kg — minden szett RPE 8');
    });

    test('is empty when there is no weight to apply', () {
      expect(autoregulationChipLabel(_s(next: null, last: 80)), '');
    });
  });

  group('autoregulationExplanation', () {
    test('includes the last logged session', () {
      final text =
          autoregulationExplanation(_s(next: 82.5, last: 80, lastRpe: 7.5));
      expect(text, contains('Előző: 80 kg × 10 @ RPE 7.5'));
      expect(text, contains('Koppints az alkalmazáshoz.'));
    });

    test('RPE-based scheme explains the e1RM solve', () {
      final text = autoregulationExplanation(
          _s(next: 77.5, last: 80, scheme: 'RpeBased'));
      expect(text, startsWith('Az e1RM-becslés alapján'));
    });
  });
}
