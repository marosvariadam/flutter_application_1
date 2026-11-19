import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/athlete_profile/data/models/athlete_profile_model.dart';
import 'package:flutter_application_1/features/training_plan/data/models/training_plan_model.dart';
import 'package:flutter_application_1/features/training_plan/data/plan_volume_landmarks.dart';
import 'package:flutter_application_1/app/design/dt_text.dart';

/// Per-muscle-group weekly set count bar chart with MEV / MRV reference
/// lines. Secondary-muscle contributions aren't drawn — we only have the
/// denormalized `muscleGroup` on `PlannedExerciseModel`, not the exercise's
/// `secondaryMuscleGroups`, so this matches the server's "primary-only"
/// total for a partial view.
class PlanEditorVolumeChart extends StatelessWidget {
  final TrainingPlanModel plan;
  final AthleteProfileModel? profile;
  const PlanEditorVolumeChart({
    super.key,
    required this.plan,
    this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final sets = weeklySetsPerMuscleGroup(plan);
    final level = profile?.experienceLevel ??
        AthleteProfileExperienceLevels.beginner;
    final maxValue = _computeChartMax(sets, level);

    return Container(
      padding: const EdgeInsets.all(DT.s4),
      decoration: BoxDecoration(
        color: DT.of(context).cardSurface,
        borderRadius: BorderRadius.circular(DT.rCard),
        boxShadow: [
          BoxShadow(
              color: DT.of(context).shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: DT.s2,
            children: [
              Text(
                'Heti volumen',
                style: TextStyle(
                  color: DT.of(context).textPrimary,
                  fontSize: DT.s4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '(szett / izomcsoport)',
                style: DTText.of(context).caption,
              ),
            ],
          ),
          const SizedBox(height: DT.s3),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: maxValue,
                minY: 0,
                alignment: BarChartAlignment.spaceEvenly,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: DT.of(context).borderLight,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 5,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: TextStyle(
                          color: DT.of(context).textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= kChartMuscleGroups.length) {
                          return const SizedBox.shrink();
                        }
                        final label =
                            kChartMuscleGroupLabels[kChartMuscleGroups[i]] ??
                                kChartMuscleGroups[i];
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: DT.of(context).textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: _buildBars(context, sets, level),
                extraLinesData: _buildReferenceLines(context, level),
              ),
            ),
          ),
          const SizedBox(height: DT.s2),
          _Legend(level: level),
        ],
      ),
    );
  }

  double _computeChartMax(Map<String, int> sets, String level) {
    double max = 20;
    for (final g in kChartMuscleGroups) {
      final v = (sets[g] ?? 0).toDouble();
      if (v > max) max = v;
      final r = rangeFor(g, level);
      if (r.mrv.toDouble() > max) max = r.mrv.toDouble();
    }
    // Round up to the next multiple of 5 so the gridlines look clean.
    return (((max / 5).ceil()) * 5).toDouble();
  }

  List<BarChartGroupData> _buildBars(
      BuildContext context, Map<String, int> sets, String level) {
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < kChartMuscleGroups.length; i++) {
      final g = kChartMuscleGroups[i];
      final value = (sets[g] ?? 0).toDouble();
      final range = rangeFor(g, level);
      final color = value < range.mev
          ? DT.of(context).accentOrange
          : value > range.mrv
              ? DT.of(context).accentDanger
              : DT.of(context).accentPrimary;
      groups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: value,
            color: color,
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      ));
    }
    return groups;
  }

  /// MEV / MRV reference lines. Because each muscle group has its own
  /// range, we draw one line per group as a short horizontal segment
  /// stacked under the bar group (simulated as a colored tick).
  ExtraLinesData _buildReferenceLines(BuildContext context, String level) {
    // Pick the median MEV / MRV values across muscle groups for the global
    // dashed lines; the per-bar color already encodes under-MEV / over-MRV
    // for the specific group.
    final mevValues = <int>[];
    final mrvValues = <int>[];
    for (final g in kChartMuscleGroups) {
      final r = rangeFor(g, level);
      mevValues.add(r.mev);
      mrvValues.add(r.mrv);
    }
    mevValues.sort();
    mrvValues.sort();
    final medianMev = mevValues[mevValues.length ~/ 2].toDouble();
    final medianMrv = mrvValues[mrvValues.length ~/ 2].toDouble();

    return ExtraLinesData(
      horizontalLines: [
        HorizontalLine(
          y: medianMev,
          color: DT.of(context).accentOrange.withValues(alpha: 0.6),
          strokeWidth: 1,
          dashArray: [4, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            padding: const EdgeInsets.only(right: 4, bottom: 2),
            labelResolver: (_) => 'MEV (átl.)',
            style: TextStyle(
                color: DT.of(context).accentOrange, fontSize: 9, fontWeight: FontWeight.w700),
          ),
        ),
        HorizontalLine(
          y: medianMrv,
          color: DT.of(context).accentDanger.withValues(alpha: 0.6),
          strokeWidth: 1,
          dashArray: [4, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            padding: const EdgeInsets.only(right: 4, bottom: 2),
            labelResolver: (_) => 'MRV (átl.)',
            style: TextStyle(
                color: DT.of(context).accentDanger, fontSize: 9, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final String level;
  const _Legend({required this.level});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: DT.s3,
      runSpacing: DT.s1,
      children: [
        _dot(context, DT.of(context).accentOrange, 'MEV alatt'),
        _dot(context, DT.of(context).accentPrimary, 'MEV–MRV'),
        _dot(context, DT.of(context).accentDanger, 'MRV felett'),
      ],
    );
  }

  Widget _dot(BuildContext ctx, Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 4),
          Text(label, style: DTText.of(ctx).caption),
        ],
      );
}
