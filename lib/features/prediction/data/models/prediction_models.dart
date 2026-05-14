/// Backend-shaped models for the Est1Rm prediction endpoint.
///
/// Shape (200):
/// {
///   "exerciseName": "...",
///   "muscleGroup": "...",
///   "weeksAhead": 8,
///   "focus": "...",
///   "modelLoaded": true,
///   "modelTrainedAt": "...",
///   "modelRmseKg": 0.85,
///   "actual":    [{ "weekStart": "...", "est1Rm": 132.5 }],
///   "predicted": [{ "weekStart": "...", "est1Rm": 135.1,
///                   "confidenceLowKg": 134.25, "confidenceHighKg": 135.95 }]
/// }
class PredictionPoint {
  final DateTime weekStart;
  final double est1Rm;

  /// Only present on predicted points; null on actual.
  final double? confidenceLowKg;
  final double? confidenceHighKg;

  const PredictionPoint({
    required this.weekStart,
    required this.est1Rm,
    this.confidenceLowKg,
    this.confidenceHighKg,
  });

  bool get hasBand => confidenceLowKg != null && confidenceHighKg != null;

  factory PredictionPoint.fromJson(Map<String, dynamic> j) => PredictionPoint(
        weekStart: DateTime.parse(j['weekStart'] as String).toUtc(),
        est1Rm: (j['est1Rm'] as num).toDouble(),
        confidenceLowKg: (j['confidenceLowKg'] as num?)?.toDouble(),
        confidenceHighKg: (j['confidenceHighKg'] as num?)?.toDouble(),
      );
}

class PredictionResult {
  final String exerciseName;
  final String? muscleGroup;
  final int weeksAhead;
  final String? focus;
  final bool modelLoaded;
  final DateTime? modelTrainedAt;
  final double? modelRmseKg;
  final List<PredictionPoint> actual;
  final List<PredictionPoint> predicted;

  const PredictionResult({
    required this.exerciseName,
    this.muscleGroup,
    required this.weeksAhead,
    this.focus,
    required this.modelLoaded,
    this.modelTrainedAt,
    this.modelRmseKg,
    required this.actual,
    required this.predicted,
  });

  bool get hasActual => actual.isNotEmpty;
  bool get hasPrediction => modelLoaded && predicted.isNotEmpty;

  factory PredictionResult.fromJson(Map<String, dynamic> j) {
    final actualList = (j['actual'] as List? ?? const [])
        .map((e) => PredictionPoint.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.weekStart.compareTo(b.weekStart));
    final predList = (j['predicted'] as List? ?? const [])
        .map((e) => PredictionPoint.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.weekStart.compareTo(b.weekStart));

    return PredictionResult(
      exerciseName: j['exerciseName'] as String? ?? '',
      muscleGroup: j['muscleGroup'] as String?,
      weeksAhead: (j['weeksAhead'] as num?)?.toInt() ?? 0,
      focus: j['focus'] as String?,
      modelLoaded: (j['modelLoaded'] as bool?) ?? false,
      modelTrainedAt: (j['modelTrainedAt'] as String?) != null
          ? DateTime.parse(j['modelTrainedAt'] as String).toUtc()
          : null,
      modelRmseKg: (j['modelRmseKg'] as num?)?.toDouble(),
      actual: actualList,
      predicted: predList,
    );
  }
}
