/// Backend `Severity` enum. `Error` blocks accept; `Warning` is advisory.
class ViolationSeverity {
  static const error = 'Error';
  static const warning = 'Warning';
}

/// Rule codes from `Planning/Violation.cs` (ViolationCode). Kept as a Dart
/// constant class so the UI can switch on them without string typos.
class ViolationCodes {
  static const unknownExercise = 'UNKNOWN_EXERCISE';
  static const equipmentUnavailable = 'EQUIPMENT_UNAVAILABLE';
  static const stressTagConflict = 'STRESS_TAG_CONFLICT';
  static const excludedExercise = 'EXCLUDED_EXERCISE';
  static const levelTooHigh = 'LEVEL_TOO_HIGH';
  static const volumeBelowMev = 'VOLUME_BELOW_MEV';
  static const volumeAboveMrv = 'VOLUME_ABOVE_MRV';
  static const sessionTooLong = 'SESSION_TOO_LONG';
  static const dayCountMismatch = 'DAY_COUNT_MISMATCH';
  static const frequencyTooLow = 'FREQUENCY_TOO_LOW';
  static const invalidPrescription = 'INVALID_PRESCRIPTION';
  static const patternImbalance = 'PATTERN_IMBALANCE';
  static const duplicateInDay = 'DUPLICATE_IN_DAY';
}

/// A single rule-violation reported by `PlanValidator`. `dayIndex` and
/// `exerciseId` are optional — day/exercise-scoped rules fill them so the
/// UI can anchor the message to the right row.
class ViolationModel {
  final String code;
  final String severity;
  final String message;
  final int? dayIndex;
  final String? exerciseId;

  const ViolationModel({
    required this.code,
    required this.severity,
    required this.message,
    this.dayIndex,
    this.exerciseId,
  });

  bool get isError => severity == ViolationSeverity.error;
  bool get isWarning => severity == ViolationSeverity.warning;

  factory ViolationModel.fromJson(Map<String, dynamic> j) => ViolationModel(
        code: j['code'] as String? ?? '',
        severity: j['severity'] as String? ?? ViolationSeverity.warning,
        message: j['message'] as String? ?? '',
        dayIndex: (j['dayIndex'] as num?)?.toInt(),
        exerciseId: j['exerciseId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'severity': severity,
        'message': message,
        if (dayIndex != null) 'dayIndex': dayIndex,
        if (exerciseId != null) 'exerciseId': exerciseId,
      };
}
