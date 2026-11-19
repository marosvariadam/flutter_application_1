import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/training_plan/data/models/violation_model.dart';

void main() {
  test('fromJson/toJson round-trip keeps every field', () {
    const json = {
      'code': ViolationCodes.duplicateInDay,
      'severity': ViolationSeverity.error,
      'message': "'Squat' appears more than once on day 1.",
      'dayIndex': 1,
      'exerciseId': 'e1',
    };
    final a = ViolationModel.fromJson(json);
    final b = ViolationModel.fromJson(a.toJson());
    expect(b.code, a.code);
    expect(b.severity, a.severity);
    expect(b.message, a.message);
    expect(b.dayIndex, 1);
    expect(b.exerciseId, 'e1');
    expect(a.toJson(), json);
  });

  test('plan-wide violations omit day and exercise', () {
    final v = ViolationModel.fromJson(const {
      'code': ViolationCodes.patternImbalance,
      'severity': ViolationSeverity.warning,
      'message': 'Push:Pull ratio imbalanced (12:0).',
    });
    expect(v.isWarning, isTrue);
    expect(v.toJson().containsKey('dayIndex'), isFalse);
    expect(v.toJson().containsKey('exerciseId'), isFalse);
  });

  test('every backend rule code has a Hungarian label', () {
    const codes = [
      ViolationCodes.unknownExercise,
      ViolationCodes.equipmentUnavailable,
      ViolationCodes.stressTagConflict,
      ViolationCodes.excludedExercise,
      ViolationCodes.levelTooHigh,
      ViolationCodes.volumeBelowMev,
      ViolationCodes.volumeAboveMrv,
      ViolationCodes.sessionTooLong,
      ViolationCodes.dayCountMismatch,
      ViolationCodes.frequencyTooLow,
      ViolationCodes.invalidPrescription,
      ViolationCodes.patternImbalance,
      ViolationCodes.duplicateInDay,
    ];
    for (final code in codes) {
      final v = ViolationModel(
          code: code, severity: ViolationSeverity.error, message: '');
      expect(ViolationCodes.labels[code], isNotNull, reason: code);
      expect(v.label, ViolationCodes.labels[code]);
    }
  });

  test('unknown codes fall back to a generic Hungarian label', () {
    const error = ViolationModel(
        code: 'NEW_RULE', severity: ViolationSeverity.error, message: 'x');
    const warning = ViolationModel(
        code: 'NEW_RULE', severity: ViolationSeverity.warning, message: 'x');
    expect(error.label, 'Szabálysértés');
    expect(warning.label, 'Figyelmeztetés');
  });
}
