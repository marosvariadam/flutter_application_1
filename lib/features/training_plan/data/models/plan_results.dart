import 'package:flutter_application_1/features/training_plan/data/models/training_plan_model.dart';
import 'package:flutter_application_1/features/training_plan/data/models/violation_model.dart';

/// Return shape of `POST /api/plan/generate`. The backend persists only the
/// top-scored plan (`plan`); `candidates` is a comparison summary of every
/// plan the scorer evaluated (the top one is always included).
class GenerateResultModel {
  final TrainingPlanModel plan;
  final double predictedScore;
  final bool usedPredictor;
  final List<ViolationModel> warnings;
  final List<ViolationModel> errors;
  final List<CandidateSummaryModel> candidates;

  const GenerateResultModel({
    required this.plan,
    required this.predictedScore,
    required this.usedPredictor,
    required this.warnings,
    required this.errors,
    required this.candidates,
  });

  factory GenerateResultModel.fromJson(Map<String, dynamic> j) =>
      GenerateResultModel(
        plan: TrainingPlanModel.fromJson(j['plan'] as Map<String, dynamic>),
        predictedScore: (j['predictedScore'] as num?)?.toDouble() ?? 0,
        usedPredictor: j['usedPredictor'] as bool? ?? false,
        warnings: _violations(j['warnings']),
        errors: _violations(j['errors']),
        candidates: ((j['candidatesSummary'] as List?) ?? const [])
            .map((e) =>
                CandidateSummaryModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'plan': plan.toJson(),
        'predictedScore': predictedScore,
        'usedPredictor': usedPredictor,
        'warnings': warnings.map((v) => v.toJson()).toList(),
        'errors': errors.map((v) => v.toJson()).toList(),
        'candidatesSummary': candidates.map((c) => c.toJson()).toList(),
      };
}

/// Entry in `candidatesSummary`. The backend does not expose per-candidate
/// ids — only the best one is persisted — so this is comparison data, not
/// something the trainer can select from.
class CandidateSummaryModel {
  final String title;
  final double score;
  final bool usedPredictor;
  final int daysCount;

  const CandidateSummaryModel({
    required this.title,
    required this.score,
    required this.usedPredictor,
    required this.daysCount,
  });

  factory CandidateSummaryModel.fromJson(Map<String, dynamic> j) =>
      CandidateSummaryModel(
        title: j['title'] as String? ?? '',
        score: (j['score'] as num?)?.toDouble() ?? 0,
        usedPredictor: j['usedPredictor'] as bool? ?? false,
        daysCount: (j['daysCount'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'score': score,
        'usedPredictor': usedPredictor,
        'daysCount': daysCount,
      };
}

/// Return shape of `POST /api/plan/{id}/refine` and `PUT /api/plan/{id}`.
/// `diff` is only populated by the refine endpoint.
class RefineResultModel {
  final TrainingPlanModel plan;
  final List<ViolationModel> warnings;
  final List<ViolationModel> errors;
  final List<DayDiffModel> diff;

  const RefineResultModel({
    required this.plan,
    required this.warnings,
    required this.errors,
    this.diff = const [],
  });

  factory RefineResultModel.fromJson(Map<String, dynamic> j) =>
      RefineResultModel(
        plan: TrainingPlanModel.fromJson(j['plan'] as Map<String, dynamic>),
        warnings: _violations(j['warnings']),
        errors: _violations(j['errors']),
        diff: ((j['diff'] as List?) ?? const [])
            .map((e) => DayDiffModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'plan': plan.toJson(),
        'warnings': warnings.map((v) => v.toJson()).toList(),
        'errors': errors.map((v) => v.toJson()).toList(),
        'diff': diff.map((d) => d.toJson()).toList(),
      };
}

/// Entry in `refine.diff` — human-readable "what changed on this day"
/// before/after refine. Keys are compact (e.g. `exId:3x6-12@7`) and meant
/// to be rendered as chips, not parsed back into exercise rows.
class DayDiffModel {
  final int dayIndex;
  final List<String> added;
  final List<String> removed;

  const DayDiffModel({
    required this.dayIndex,
    required this.added,
    required this.removed,
  });

  factory DayDiffModel.fromJson(Map<String, dynamic> j) => DayDiffModel(
        dayIndex: (j['dayIndex'] as num?)?.toInt() ?? 0,
        added: ((j['added'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        removed: ((j['removed'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'dayIndex': dayIndex,
        'added': added,
        'removed': removed,
      };
}

/// Return shape of `POST /api/plan/{id}/validate`.
class ValidationResultModel {
  final List<ViolationModel> warnings;
  final List<ViolationModel> errors;

  const ValidationResultModel({required this.warnings, required this.errors});

  factory ValidationResultModel.fromJson(Map<String, dynamic> j) =>
      ValidationResultModel(
        warnings: _violations(j['warnings']),
        errors: _violations(j['errors']),
      );

  Map<String, dynamic> toJson() => {
        'warnings': warnings.map((v) => v.toJson()).toList(),
        'errors': errors.map((v) => v.toJson()).toList(),
      };
}

/// Return shape of `POST /api/plan/{id}/materialize`.
class MaterializeResultModel {
  final String planId;
  final int workoutsCreated;
  final DateTime scheduledFrom;
  final DateTime scheduledTo;

  const MaterializeResultModel({
    required this.planId,
    required this.workoutsCreated,
    required this.scheduledFrom,
    required this.scheduledTo,
  });

  factory MaterializeResultModel.fromJson(Map<String, dynamic> j) {
    final window = j['scheduledWindow'] as Map<String, dynamic>? ?? const {};
    return MaterializeResultModel(
      planId: j['planId'] as String? ?? '',
      workoutsCreated: (j['workoutsCreated'] as num?)?.toInt() ?? 0,
      scheduledFrom: DateTime.parse(window['from'] as String).toUtc(),
      scheduledTo: DateTime.parse(window['to'] as String).toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
        'planId': planId,
        'workoutsCreated': workoutsCreated,
        'scheduledWindow': {
          'from': scheduledFrom.toIso8601String(),
          'to': scheduledTo.toIso8601String(),
        },
      };
}

/// Return shape of `GET /api/plan/{id}/explanation`.
class PlanExplanationModel {
  final String planId;
  final String language;
  final String explanation;

  const PlanExplanationModel({
    required this.planId,
    required this.language,
    required this.explanation,
  });

  factory PlanExplanationModel.fromJson(Map<String, dynamic> j) =>
      PlanExplanationModel(
        planId: j['planId'] as String? ?? '',
        language: j['language'] as String? ?? 'en',
        explanation: j['explanation'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'planId': planId,
        'language': language,
        'explanation': explanation,
      };
}

List<ViolationModel> _violations(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .map((e) => ViolationModel.fromJson(e as Map<String, dynamic>))
      .toList();
}
