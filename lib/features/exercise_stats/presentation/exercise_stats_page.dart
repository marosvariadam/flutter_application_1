import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/exercise/bloc/exercise_bloc.dart';
import 'package:flutter_application_1/features/exercise/data/models/exercise_model.dart';
import 'package:flutter_application_1/features/exercise_stats/bloc/exercise_stats_cubit.dart';
import 'package:flutter_application_1/features/exercise_stats/data/models/exercise_stat_point.dart';
import 'package:intl/intl.dart';

/// Metric shown on the chart.
enum _ChartMetric { weight, reps, sets }

class ExerciseStatsPage extends StatefulWidget {
  /// If non-null the cubit fetches stats for this athlete (trainer view).
  final String? athleteId;
  final String? athleteName;

  const ExerciseStatsPage({super.key, this.athleteId, this.athleteName});

  @override
  State<ExerciseStatsPage> createState() => _ExerciseStatsPageState();
}

class _ExerciseStatsPageState extends State<ExerciseStatsPage> {
  ExerciseModel? _selectedExercise;
  late DateTimeRange _range;
  _ChartMetric _metric = _ChartMetric.weight;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(
      start: now.subtract(const Duration(days: 30)),
      end: now,
    );
    // Load exercise library for the dropdown.
    context.read<ExerciseBloc>().add(LoadExercises());
  }

  void _fetch() {
    if (_selectedExercise == null) return;
    context.read<ExerciseStatsCubit>().loadStats(
          exerciseName: _selectedExercise!.name,
          from: _range.start,
          to: _range.end,
          athleteId: widget.athleteId,
        );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _range,
    );
    if (picked != null) {
      setState(() => _range = picked);
      _fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.athleteName != null
        ? '${widget.athleteName} — Statisztikák'
        : 'Gyakorlat statisztikák';

    return Scaffold(
      backgroundColor: DT.of(context).bg,
      appBar: AppBar(
        backgroundColor: DT.of(context).bg,
        elevation: 0,
        title: Text(title,
            style: TextStyle(
                color: DT.of(context).textPrimary,
                fontWeight: FontWeight.w600)),
        iconTheme: IconThemeData(color: DT.of(context).textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DT.s5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise selector
            _ExerciseSelector(
              selected: _selectedExercise,
              onChanged: (e) {
                setState(() => _selectedExercise = e);
                _fetch();
              },
            ),
            const SizedBox(height: DT.s4),

            // Date range
            GestureDetector(
              onTap: _pickDateRange,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: DT.s4, vertical: DT.s3),
                decoration: BoxDecoration(
                  color: DT.of(context).cardSurface,
                  borderRadius: BorderRadius.circular(DT.rCardSmall),
                  boxShadow: [
                    BoxShadow(
                      color: DT.of(context).shadowLight,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.date_range,
                        size: 20, color: DT.of(context).iconLight),
                    const SizedBox(width: DT.s2),
                    Expanded(
                      child: Text(
                        '${DateFormat('yyyy.MM.dd').format(_range.start)} – ${DateFormat('yyyy.MM.dd').format(_range.end)}',
                        style: TextStyle(
                            color: DT.of(context).textPrimary, fontSize: DT.s3),
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: DT.of(context).textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DT.s4),

            // Metric toggle
            _MetricToggle(
              selected: _metric,
              onChanged: (m) => setState(() => _metric = m),
            ),
            const SizedBox(height: DT.s5),

            // Chart
            BlocBuilder<ExerciseStatsCubit, ExerciseStatsState>(
              builder: (context, state) {
                if (state is ExerciseStatsInitial) {
                  return _Placeholder(
                      message: 'Válassz egy gyakorlatot a kezdéshez.');
                }
                if (state is ExerciseStatsLoading) {
                  return const SizedBox(
                    height: 250,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (state is ExerciseStatsError) {
                  return _Placeholder(message: state.message);
                }
                final loaded = state as ExerciseStatsLoaded;
                if (loaded.points.isEmpty) {
                  return _Placeholder(
                      message:
                          'Nincs adat a kiválasztott időszakban.');
                }
                return _StatsChart(
                  points: loaded.points,
                  metric: _metric,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Exercise selector

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
            color: DT.of(context).cardSurface,
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
              hint: Text('Válassz gyakorlatot',
                  style: TextStyle(color: DT.of(context).textSecondary)),
              value: selected,
              icon: Icon(Icons.expand_more,
                  color: DT.of(context).textSecondary),
              items: exercises
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.name,
                            style: TextStyle(
                                color: DT.of(context).textPrimary)),
                      ))
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

// Metric toggle

class _MetricToggle extends StatelessWidget {
  final _ChartMetric selected;
  final ValueChanged<_ChartMetric> onChanged;

  const _MetricToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _ChartMetric.values.map((m) {
        final isActive = m == selected;
        final label = switch (m) {
          _ChartMetric.weight => 'Súly',
          _ChartMetric.reps => 'Ismétlés',
          _ChartMetric.sets => 'Sorozat',
        };
        return Padding(
          padding: const EdgeInsets.only(right: DT.s2),
          child: ChoiceChip(
            label: Text(label),
            selected: isActive,
            selectedColor: DT.of(context).accentPrimary,
            labelStyle: TextStyle(
              color: isActive
                  ? DT.of(context).textOnAccent
                  : DT.of(context).textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: DT.s3,
            ),
            backgroundColor: DT.of(context).cardSurface,
            side: BorderSide(color: DT.of(context).borderGrey),
            onSelected: (_) => onChanged(m),
          ),
        );
      }).toList(),
    );
  }
}

// Chart

class _StatsChart extends StatelessWidget {
  final List<ExerciseStatPoint> points;
  final _ChartMetric metric;

  const _StatsChart({required this.points, required this.metric});

  double _actual(ExerciseStatPoint p) => switch (metric) {
        _ChartMetric.weight => p.actualWeightKg,
        _ChartMetric.reps => p.actualReps.toDouble(),
        _ChartMetric.sets => p.actualSets.toDouble(),
      };

  double _target(ExerciseStatPoint p) => switch (metric) {
        _ChartMetric.weight => p.targetWeightKg,
        _ChartMetric.reps => p.targetReps.toDouble(),
        _ChartMetric.sets => 0, // no target sets from API
      };

  String get _yLabel => switch (metric) {
        _ChartMetric.weight => 'kg',
        _ChartMetric.reps => 'ism.',
        _ChartMetric.sets => 'sor.',
      };

  @override
  Widget build(BuildContext context) {
    final sorted = [...points]..sort((a, b) => a.date.compareTo(b.date));

    final actualSpots = <FlSpot>[];
    final targetSpots = <FlSpot>[];
    for (var i = 0; i < sorted.length; i++) {
      actualSpots.add(FlSpot(i.toDouble(), _actual(sorted[i])));
      final t = _target(sorted[i]);
      if (t > 0) targetSpots.add(FlSpot(i.toDouble(), t));
    }

    final showTarget = targetSpots.isNotEmpty && metric != _ChartMetric.sets;

    return Container(
      height: 280,
      padding: const EdgeInsets.all(DT.s4),
      decoration: BoxDecoration(
        color: DT.of(context).cardSurface,
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
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: DT.of(context).borderLight,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: _xInterval(sorted.length),
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= sorted.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: DT.s2),
                    child: Text(
                      DateFormat('MM.dd').format(sorted[idx].date),
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
                    '${value.toInt()} $_yLabel',
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
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) {
                final color =
                    s.barIndex == 0 ? DT.metricBlue : DT.cardTeal;
                final idx = s.x.toInt();
                final dateStr = idx >= 0 && idx < sorted.length
                    ? DateFormat('MM.dd').format(sorted[idx].date)
                    : '';
                return LineTooltipItem(
                  '$dateStr\n${s.y.toStringAsFixed(1)} $_yLabel',
                  TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: DT.s3),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            _line(actualSpots, DT.metricBlue),
            if (showTarget) _line(targetSpots, DT.cardTeal, dashed: true),
          ],
        ),
      ),
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color,
      {bool dashed = false}) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      preventCurveOverShooting: true,
      color: color,
      barWidth: 3,
      dotData: FlDotData(
        show: true,
        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
          radius: 3,
          color: color,
          strokeColor: Colors.white,
          strokeWidth: 1.5,
        ),
      ),
      dashArray: dashed ? [8, 4] : null,
      belowBarData: BarAreaData(
        show: !dashed,
        color: color.withValues(alpha: 0.08),
      ),
    );
  }

  double _xInterval(int count) {
    if (count <= 7) return 1;
    if (count <= 14) return 2;
    if (count <= 30) return 5;
    return (count / 6).ceilToDouble();
  }
}

// Placeholder

class _Placeholder extends StatelessWidget {
  final String message;
  const _Placeholder({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: DT.of(context).cardSurface,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart,
                size: 48, color: DT.of(context).borderGrey),
            const SizedBox(height: DT.s3),
            Text(
              message,
              style: TextStyle(
                color: DT.of(context).textSecondary,
                fontSize: DT.s3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
