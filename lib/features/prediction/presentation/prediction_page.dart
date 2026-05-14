import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/exercise/bloc/exercise_bloc.dart';
import 'package:flutter_application_1/features/exercise/data/models/exercise_model.dart';
import 'package:flutter_application_1/features/prediction/bloc/prediction_cubit.dart';
import 'package:flutter_application_1/features/prediction/data/models/prediction_models.dart';
import 'package:intl/intl.dart';

/// Progress prediction screen.
///
/// Used in two modes:
///   • athlete-self: [athleteId] == null
///   • trainer view: [athleteId] != null (already-existing athlete-detail flow)
class PredictionPage extends StatefulWidget {
  final String? athleteId;
  final String? athleteName;

  const PredictionPage({super.key, this.athleteId, this.athleteName});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  ExerciseModel? _selected;
  int _weeksAhead = 8; // default per spec

  @override
  void initState() {
    super.initState();
    // Make sure the exercise dropdown has data.
    final state = context.read<ExerciseBloc>().state;
    if (state is! ExercisesLoaded) {
      context.read<ExerciseBloc>().add(LoadExercises());
    }
  }

  void _fetch() {
    if (_selected == null) return;
    context.read<PredictionCubit>().load(
          exerciseName: _selected!.name,
          weeksAhead: _weeksAhead,
          athleteId: widget.athleteId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.athleteName != null
        ? '${widget.athleteName} — Fejlődés'
        : 'Fejlődés (előrejelzés)';

    return Scaffold(
      backgroundColor: DT.of(context).bg,
      appBar: AppBar(
        backgroundColor: DT.of(context).bg,
        elevation: 0,
        title: Text(
          title,
          style: TextStyle(
            color: DT.of(context).textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: DT.of(context).textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DT.s5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ExerciseSelector(
              selected: _selected,
              onChanged: (e) {
                setState(() => _selected = e);
                _fetch();
              },
            ),
            const SizedBox(height: DT.s4),
            _WeeksAheadSelector(
              value: _weeksAhead,
              onChanged: (v) {
                setState(() => _weeksAhead = v);
                _fetch();
              },
            ),
            const SizedBox(height: DT.s5),
            BlocBuilder<PredictionCubit, PredictionState>(
              builder: (context, state) {
                if (state is PredictionInitial) {
                  return const _Placeholder(
                    icon: Icons.timeline,
                    message: 'Válassz egy gyakorlatot az előrejelzéshez.',
                  );
                }
                if (state is PredictionLoading) {
                  return const SizedBox(
                    height: 280,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (state is PredictionEmpty) {
                  return const _Placeholder(
                    icon: Icons.show_chart,
                    // Exact string from spec
                    message:
                        'No completed sessions for this exercise yet.',
                  );
                }
                if (state is PredictionForbidden) {
                  return const _Placeholder(
                    icon: Icons.lock_outline,
                    // Exact string from spec
                    message: 'Not authorized',
                  );
                }
                if (state is PredictionError) {
                  return _Placeholder(
                    icon: Icons.error_outline,
                    message: state.message,
                  );
                }
                final loaded = state as PredictionLoaded;
                return _PredictionContent(result: loaded.result);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Exercise selector ────────────────────────────────────────────────────────

class _ExerciseSelector extends StatelessWidget {
  final ExerciseModel? selected;
  final ValueChanged<ExerciseModel> onChanged;

  const _ExerciseSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExerciseBloc, ExerciseState>(
      builder: (context, state) {
        final exercises =
            state is ExercisesLoaded ? state.exercises : <ExerciseModel>[];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: DT.s4),
          decoration: BoxDecoration(
            color: DT.gbWhite,
            borderRadius: BorderRadius.circular(DT.rCardSmall),
            boxShadow: [
              BoxShadow(
                color: DT.of(context).shadowLight,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ExerciseModel>(
              isExpanded: true,
              hint: Text(
                'Válassz gyakorlatot',
                style: TextStyle(color: DT.of(context).textSecondary),
              ),
              value: selected != null &&
                      exercises.any((e) => e.id == selected!.id)
                  ? exercises.firstWhere((e) => e.id == selected!.id)
                  : null,
              icon:
                  Icon(Icons.expand_more, color: DT.of(context).textSecondary),
              items: exercises
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        e.name,
                        style:
                            TextStyle(color: DT.of(context).textPrimary),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (e) {
                if (e != null) onChanged(e);
              },
            ),
          ),
        );
      },
    );
  }
}

// ── weeksAhead selector ──────────────────────────────────────────────────────

class _WeeksAheadSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _WeeksAheadSelector({required this.value, required this.onChanged});

  static const _options = [4, 8, 12, 26];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: DT.s2,
      children: _options.map((v) {
        final isActive = v == value;
        return ChoiceChip(
          label: Text('$v hét'),
          selected: isActive,
          selectedColor: DT.gbBlack,
          labelStyle: TextStyle(
            color: isActive ? DT.gbWhite : DT.of(context).textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: DT.s3,
          ),
          backgroundColor: DT.gbWhite,
          side: BorderSide(color: DT.of(context).borderGrey),
          onSelected: (_) => onChanged(v),
        );
      }).toList(),
    );
  }
}

// ── Loaded content ───────────────────────────────────────────────────────────

class _PredictionContent extends StatelessWidget {
  final PredictionResult result;
  const _PredictionContent({required this.result});

  @override
  Widget build(BuildContext context) {
    if (!result.hasActual && !result.hasPrediction) {
      return const _Placeholder(
        icon: Icons.show_chart,
        message: 'No completed sessions for this exercise yet.',
      );
    }

    final modelStillTraining = !result.modelLoaded || result.predicted.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetaHeader(result: result),
        const SizedBox(height: DT.s3),
        _PredictionChart(result: result),
        if (modelStillTraining) ...[
          const SizedBox(height: DT.s3),
          Text(
            // Exact string from spec
            'Forecast unavailable — model is still training.',
            style: TextStyle(
              fontSize: DT.s3,
              fontStyle: FontStyle.italic,
              color: DT.of(context).textSecondary,
            ),
          ),
        ] else ...[
          const SizedBox(height: DT.s3),
          _Legend(),
        ],
      ],
    );
  }
}

class _MetaHeader extends StatelessWidget {
  final PredictionResult result;
  const _MetaHeader({required this.result});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    if (result.muscleGroup != null && result.muscleGroup!.isNotEmpty) {
      items.add(_metaChip(context, Icons.accessibility_new, result.muscleGroup!));
    }
    if (result.focus != null && result.focus!.isNotEmpty) {
      items.add(_metaChip(context, Icons.center_focus_strong, 'Fókusz: ${result.focus}'));
    }
    if (result.modelRmseKg != null) {
      items.add(_metaChip(
        context,
        Icons.straighten,
        'RMSE: ${result.modelRmseKg!.toStringAsFixed(2)} kg',
      ));
    }
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: DT.s2, runSpacing: DT.s2, children: items);
  }

  Widget _metaChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: DT.s3, vertical: DT.s1),
      decoration: BoxDecoration(
        color: DT.gbWhite,
        borderRadius: BorderRadius.circular(DT.rChip),
        border: Border.all(color: DT.of(context).borderGrey),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: DT.of(context).iconLight),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: DT.of(context).textSecondary, fontSize: DT.s3)),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _LegendDot(
          color: DT.metricBlue,
          label: 'Tényleges',
          dashed: false,
        ),
        const SizedBox(width: DT.s4),
        _LegendDot(
          color: DT.metricBlue,
          label: 'Előrejelzés',
          dashed: true,
        ),
        const SizedBox(width: DT.s4),
        _LegendBand(color: DT.metricBlue.withValues(alpha: 0.2)),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;
  const _LegendDot({
    required this.color,
    required this.label,
    required this.dashed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(22, 2),
          painter: _LinePainter(color: color, dashed: dashed),
        ),
        const SizedBox(width: 4),
        Text(label,
            style:
                TextStyle(fontSize: 10, color: DT.of(context).textSecondary)),
      ],
    );
  }
}

class _LegendBand extends StatelessWidget {
  final Color color;
  const _LegendBand({required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text('Bizonyossági sáv',
            style:
                TextStyle(fontSize: 10, color: DT.of(context).textSecondary)),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  final Color color;
  final bool dashed;
  _LinePainter({required this.color, required this.dashed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    if (!dashed) {
      canvas.drawLine(Offset(0, size.height / 2),
          Offset(size.width, size.height / 2), paint);
      return;
    }
    const dashWidth = 4.0;
    const dashGap = 3.0;
    var startX = 0.0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.color != color || old.dashed != dashed;
}

// ── Chart ────────────────────────────────────────────────────────────────────

class _PredictionChart extends StatelessWidget {
  final PredictionResult result;
  const _PredictionChart({required this.result});

  @override
  Widget build(BuildContext context) {
    // Build a single x-axis indexed by week. Actual: [0 .. n-1]. Predicted
    // continues at n and is joined to the last actual point so the curve is
    // continuous (the connector segment lives in the dotted series only — the
    // join point itself is the last actual data point, drawn as a solid dot).
    final actuals = result.actual;
    final predicted = result.predicted;

    final hasActual = actuals.isNotEmpty;
    final hasPredicted = predicted.isNotEmpty && result.modelLoaded;

    // Combined ordered week list for x labels.
    final allWeeks = <DateTime>[
      ...actuals.map((p) => p.weekStart),
      ...predicted.map((p) => p.weekStart),
    ];

    final actualSpots = <FlSpot>[];
    for (var i = 0; i < actuals.length; i++) {
      actualSpots.add(FlSpot(i.toDouble(), actuals[i].est1Rm));
    }

    // Predicted series — prepend the last-actual point so it joins continuously.
    final predSpots = <FlSpot>[];
    final lowSpots = <FlSpot>[];
    final highSpots = <FlSpot>[];
    if (hasPredicted) {
      if (hasActual) {
        final last = actuals.last;
        predSpots.add(FlSpot((actuals.length - 1).toDouble(), last.est1Rm));
        lowSpots.add(FlSpot((actuals.length - 1).toDouble(), last.est1Rm));
        highSpots.add(FlSpot((actuals.length - 1).toDouble(), last.est1Rm));
      }
      for (var i = 0; i < predicted.length; i++) {
        final p = predicted[i];
        final x = (actuals.length + i).toDouble();
        predSpots.add(FlSpot(x, p.est1Rm));
        lowSpots.add(FlSpot(x, p.confidenceLowKg ?? p.est1Rm));
        highSpots.add(FlSpot(x, p.confidenceHighKg ?? p.est1Rm));
      }
    }

    final allYValues = <double>[
      ...actuals.map((p) => p.est1Rm),
      ...predicted.map((p) => p.confidenceLowKg ?? p.est1Rm),
      ...predicted.map((p) => p.confidenceHighKg ?? p.est1Rm),
    ];
    final yMin = allYValues.isEmpty
        ? 0.0
        : (allYValues.reduce((a, b) => a < b ? a : b) - 5)
            .clamp(0, double.infinity)
            .toDouble();
    final yMax = allYValues.isEmpty
        ? 1.0
        : allYValues.reduce((a, b) => a > b ? a : b) + 5;

    final color = DT.metricBlue;
    final bandColor = color.withValues(alpha: 0.20);

    return Container(
      height: 300,
      padding: const EdgeInsets.fromLTRB(DT.s2, DT.s4, DT.s4, DT.s4),
      decoration: BoxDecoration(
        color: DT.gbWhite,
        borderRadius: BorderRadius.circular(DT.rCard),
        boxShadow: [
          BoxShadow(
            color: DT.of(context).shadowLight,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          minY: yMin,
          maxY: yMax,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: DT.of(context).borderLight,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: _xInterval(allWeeks.length),
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= allWeeks.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: DT.s2),
                    child: Text(
                      DateFormat('MM.dd').format(allWeeks[idx].toLocal()),
                      style: TextStyle(
                        fontSize: 10,
                        color: DT.of(context).textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toStringAsFixed(0)} kg',
                    style: TextStyle(
                      fontSize: 10,
                      color: DT.of(context).textSecondary,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              maxContentWidth: 220,
              getTooltipItems: (touched) {
                // De-duplicate by x — the band lines stack on the same point.
                final seenX = <double>{};
                final items = <LineTooltipItem?>[];
                for (final s in touched) {
                  if (seenX.contains(s.x)) {
                    items.add(null);
                    continue;
                  }
                  seenX.add(s.x);
                  final idx = s.x.toInt();
                  if (idx < 0 || idx >= allWeeks.length) {
                    items.add(null);
                    continue;
                  }
                  final dateStr =
                      DateFormat('yyyy.MM.dd').format(allWeeks[idx].toLocal());

                  final isPredicted = hasActual && idx >= actuals.length;
                  String text;
                  if (isPredicted) {
                    final p = predicted[idx - actuals.length];
                    final low = p.confidenceLowKg?.toStringAsFixed(1);
                    final high = p.confidenceHighKg?.toStringAsFixed(1);
                    text =
                        '$dateStr\n${p.est1Rm.toStringAsFixed(1)} kg (előrejelzés)';
                    if (low != null && high != null) {
                      text += '\nsáv: $low – $high kg';
                    }
                  } else {
                    final a = actuals[idx];
                    text =
                        '$dateStr\n${a.est1Rm.toStringAsFixed(1)} kg';
                  }

                  items.add(LineTooltipItem(
                    text,
                    TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: DT.s3,
                    ),
                  ));
                }
                return items;
              },
            ),
          ),
          lineBarsData: [
            // Confidence band: high line (transparent) with belowBarData
            // shaded down to the matching low line — gives the band fill.
            if (hasPredicted && predicted.first.hasBand)
              LineChartBarData(
                spots: highSpots,
                color: Colors.transparent,
                barWidth: 0,
                isCurved: false,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: bandColor,
                  cutOffY: 0,
                  applyCutOffY: false,
                  spotsLine: const BarAreaSpotsLine(show: false),
                ),
              ),
            if (hasPredicted && predicted.first.hasBand)
              LineChartBarData(
                spots: lowSpots,
                color: Colors.transparent,
                barWidth: 0,
                isCurved: false,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: DT.gbWhite,
                  cutOffY: 0,
                  applyCutOffY: false,
                ),
              ),
            // Actual — solid
            if (hasActual)
              LineChartBarData(
                spots: actualSpots,
                isCurved: false,
                color: color,
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 3.5,
                    color: color,
                    strokeColor: Colors.white,
                    strokeWidth: 1.5,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: color.withValues(alpha: 0.06),
                ),
              ),
            // Predicted — dotted/dashed (only when model has predictions)
            if (hasPredicted)
              LineChartBarData(
                spots: predSpots,
                isCurved: false,
                color: color,
                barWidth: 3,
                dashArray: const [6, 4],
                dotData: FlDotData(
                  show: true,
                  // Suppress the join dot (it's already drawn by the actual
                  // series); show dots only for true predicted points.
                  checkToShowDot: (spot, barData) {
                    return spot.x >= actuals.length.toDouble();
                  },
                  getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 3,
                    color: DT.gbWhite,
                    strokeColor: color,
                    strokeWidth: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _xInterval(int count) {
    if (count <= 1) return 1;
    if (count <= 8) return 1;
    if (count <= 14) return 2;
    if (count <= 26) return 4;
    return (count / 6).ceilToDouble();
  }
}

// ── Placeholder ──────────────────────────────────────────────────────────────

class _Placeholder extends StatelessWidget {
  final IconData icon;
  final String message;
  const _Placeholder({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        color: DT.gbWhite,
        borderRadius: BorderRadius.circular(DT.rCard),
        boxShadow: [
          BoxShadow(
            color: DT.of(context).shadowLight,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(DT.s5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: DT.of(context).borderGrey),
              const SizedBox(height: DT.s3),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: DT.of(context).textSecondary,
                  fontSize: DT.s3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
