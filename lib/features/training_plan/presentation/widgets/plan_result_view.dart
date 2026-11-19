import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/training_plan/data/models/plan_results.dart';
import 'package:flutter_application_1/features/training_plan/data/models/training_plan_model.dart';
import 'package:flutter_application_1/features/training_plan/data/models/violation_model.dart';

/// Step 3 of the generate wizard: the saved plan, its predicted progress
/// score, candidate comparison (when >1), and warning / error badges from
/// the validator. "Open editor" is deliberately a stub here — the real
/// editor lands in F3; for F2 we show a snackbar so the flow is honest
/// about what is implemented.
class PlanResultView extends StatelessWidget {
  final GenerateResultModel result;
  final VoidCallback onRestart;
  final VoidCallback onOpenEditor;

  const PlanResultView({
    super.key,
    required this.result,
    required this.onRestart,
    required this.onOpenEditor,
  });

  @override
  Widget build(BuildContext context) {
    final plan = result.plan;
    return ListView(
      padding: const EdgeInsets.all(DT.s5),
      children: [
        _ResultHeader(
          plan: plan,
          predictedScore: result.predictedScore,
          usedPredictor: result.usedPredictor,
        ),
        const SizedBox(height: DT.s4),
        if (result.errors.isNotEmpty) ...[
          _ViolationsCard(
            title: 'Hibák (${result.errors.length})',
            color: DT.cardRed,
            violations: result.errors,
          ),
          const SizedBox(height: DT.s3),
        ],
        if (result.warnings.isNotEmpty) ...[
          _ViolationsCard(
            title: 'Figyelmeztetések (${result.warnings.length})',
            color: DT.cardOrange,
            violations: result.warnings,
          ),
          const SizedBox(height: DT.s3),
        ],
        _DaysPreview(plan: plan),
        if (result.candidates.length > 1) ...[
          const SizedBox(height: DT.s4),
          _CandidatesSection(candidates: result.candidates),
        ],
        const SizedBox(height: DT.s5),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.refresh),
                label: const Text('Újragenerálás'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DT.metricBlue,
                  side: const BorderSide(color: DT.metricBlue),
                  padding: const EdgeInsets.symmetric(vertical: DT.s3),
                ),
              ),
            ),
            const SizedBox(width: DT.s3),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onOpenEditor,
                icon: const Icon(Icons.edit),
                label: const Text('Szerkesztő'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DT.metricBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: DT.s3),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: DT.s8),
      ],
    );
  }
}

class _ResultHeader extends StatelessWidget {
  final TrainingPlanModel plan;
  final double predictedScore;
  final bool usedPredictor;

  const _ResultHeader({
    required this.plan,
    required this.predictedScore,
    required this.usedPredictor,
  });

  @override
  Widget build(BuildContext context) {
    final splitLabel = PlanSplits.labels[plan.split] ?? plan.split;
    return Container(
      padding: const EdgeInsets.all(DT.s5),
      decoration: BoxDecoration(
        color: DT.of(context).cardSurface,
        borderRadius: BorderRadius.circular(DT.rCard),
        boxShadow: [
          BoxShadow(
              color: DT.of(context).shadowLight,
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.title,
                  style: TextStyle(
                    fontSize: DT.s5,
                    fontWeight: FontWeight.w700,
                    color: DT.of(context).textPrimary,
                  ),
                ),
              ),
              _StatusChip(status: plan.status),
            ],
          ),
          const SizedBox(height: DT.s2),
          Wrap(
            spacing: DT.s2,
            runSpacing: DT.s2,
            children: [
              _MetaPill(icon: Icons.view_week, text: '${plan.weeks} hét'),
              _MetaPill(icon: Icons.calendar_today, text: splitLabel),
              _MetaPill(
                  icon: Icons.fitness_center,
                  text: '${plan.days.length} nap / hét'),
              _MetaPill(
                  icon: Icons.format_list_numbered,
                  text: '${plan.totalExercises} gyakorlat'),
            ],
          ),
          const SizedBox(height: DT.s3),
          Row(
            children: [
              Icon(usedPredictor ? Icons.auto_graph : Icons.calculate,
                  size: 18, color: DT.metricBlue),
              const SizedBox(width: DT.s2),
              Expanded(
                child: Text(
                  usedPredictor
                      ? 'Előrejelzett fejlődés: ${predictedScore.toStringAsFixed(2)}'
                      : 'Pontszám (CP-SAT objektum): ${predictedScore.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: DT.of(context).textSecondary,
                    fontSize: DT.s3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == PlanStatuses.draft
        ? DT.cardOrange
        : status == PlanStatuses.accepted
            ? DT.cardTeal
            : status == PlanStatuses.materialized
                ? DT.metricBlue
                : DT.of(context).iconLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DT.s2, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DT.rChip),
      ),
      child: Text(
        PlanStatuses.labels[status] ?? status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: DT.s2, vertical: DT.s1),
      decoration: BoxDecoration(
        color: DT.of(context).bg,
        borderRadius: BorderRadius.circular(DT.rChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: DT.of(context).iconLight),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: DT.of(context).textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViolationsCard extends StatelessWidget {
  final String title;
  final Color color;
  final List<ViolationModel> violations;

  const _ViolationsCard({
    required this.title,
    required this.color,
    required this.violations,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DT.s4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: DT.s3),
          ),
          const SizedBox(height: DT.s2),
          ...violations.map((v) => Padding(
                padding: const EdgeInsets.only(bottom: DT.s1),
                child: Text(
                  v.dayIndex != null
                      ? '• ${v.dayIndex! + 1}. nap — ${v.message}'
                      : '• ${v.message}',
                  style: TextStyle(
                      color: DT.of(context).textPrimary, fontSize: DT.s3),
                ),
              )),
        ],
      ),
    );
  }
}

class _DaysPreview extends StatelessWidget {
  final TrainingPlanModel plan;
  const _DaysPreview({required this.plan});

  @override
  Widget build(BuildContext context) {
    if (plan.days.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(DT.s4),
        decoration: BoxDecoration(
          color: DT.of(context).cardSurface,
          borderRadius: BorderRadius.circular(DT.rCardSmall),
        ),
        child: Text('A terv üres.',
            style: TextStyle(color: DT.of(context).textSecondary)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Napok',
            style: TextStyle(
                fontSize: DT.s4,
                fontWeight: FontWeight.w700,
                color: DT.of(context).textPrimary)),
        const SizedBox(height: DT.s2),
        ...plan.days.map((d) => _DayCard(day: d)),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  final PlanDayModel day;
  const _DayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DT.s2),
      padding: const EdgeInsets.all(DT.s3),
      decoration: BoxDecoration(
        color: DT.of(context).cardSurface,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        boxShadow: [
          BoxShadow(
              color: DT.of(context).shadowLight,
              blurRadius: 6,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${day.dayIndex + 1}. nap · ${day.label}',
            style: TextStyle(
                fontSize: DT.s3,
                fontWeight: FontWeight.w700,
                color: DT.of(context).textPrimary),
          ),
          const SizedBox(height: DT.s1),
          ...day.exercises.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.name,
                        style: TextStyle(
                            color: DT.of(context).textPrimary,
                            fontSize: DT.s3),
                      ),
                    ),
                    Text(
                      e.prescription,
                      style: TextStyle(
                          color: DT.of(context).textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _CandidatesSection extends StatelessWidget {
  final List<CandidateSummaryModel> candidates;
  const _CandidatesSection({required this.candidates});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alternatívák (${candidates.length})',
          style: TextStyle(
              fontSize: DT.s4,
              fontWeight: FontWeight.w700,
              color: DT.of(context).textPrimary),
        ),
        const SizedBox(height: DT.s1),
        Text(
          'A mentett változat a legjobb pontszámot kapta. Az alternatívák '
          'csak összehasonlításhoz jelennek meg.',
          style: TextStyle(
              color: DT.of(context).textSecondary, fontSize: DT.s3),
        ),
        const SizedBox(height: DT.s2),
        ...candidates.asMap().entries.map((entry) {
          final i = entry.key;
          final c = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: DT.s2),
            padding: const EdgeInsets.all(DT.s3),
            decoration: BoxDecoration(
              color: DT.of(context).cardSurface,
              borderRadius: BorderRadius.circular(DT.rCardSmall),
              border: i == 0
                  ? Border.all(
                      color: DT.metricBlue.withValues(alpha: 0.4), width: 1.5)
                  : null,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: i == 0
                      ? DT.metricBlue
                      : DT.of(context).borderGrey,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                        color: i == 0
                            ? Colors.white
                            : DT.of(context).textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: DT.s2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.title,
                        style: TextStyle(
                            color: DT.of(context).textPrimary,
                            fontSize: DT.s3,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${c.daysCount} nap · ${c.usedPredictor ? 'ML pontszám' : 'CP-SAT pontszám'}',
                        style: TextStyle(
                            color: DT.of(context).textSecondary,
                            fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Text(
                  c.score.toStringAsFixed(2),
                  style: TextStyle(
                      color: i == 0 ? DT.metricBlue : DT.of(context).textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: DT.s3),
                ),
                if (i == 0) ...[
                  const SizedBox(width: DT.s2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: DT.s2, vertical: 2),
                    decoration: BoxDecoration(
                      color: DT.metricBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(DT.rChip),
                    ),
                    child: const Text(
                      'mentett',
                      style: TextStyle(
                        color: DT.metricBlue,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}
