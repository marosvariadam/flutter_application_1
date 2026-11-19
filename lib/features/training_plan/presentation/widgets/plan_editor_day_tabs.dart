import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/exercise/data/models/exercise_model.dart';
import 'package:flutter_application_1/features/exercise/data/repositories/exercise_repository.dart';
import 'package:flutter_application_1/features/exercise/presentation/widgets/exercise_picker.dart';
import 'package:flutter_application_1/features/training_plan/bloc/plan_editor_bloc.dart';
import 'package:flutter_application_1/features/training_plan/data/models/training_plan_model.dart';
import 'package:flutter_application_1/features/training_plan/data/models/violation_model.dart';
import 'package:flutter_application_1/features/training_plan/presentation/widgets/plan_editor_exercise_row.dart';

/// Horizontal tab bar for the plan's days + the day's content. Keeps all
/// day-switching state inside this widget so the page doesn't have to
/// juggle a TabController alongside the bloc.
class PlanEditorDayTabs extends StatefulWidget {
  final TrainingPlanModel plan;
  final List<ViolationModel> allViolations;
  final Set<int> highlightedDays;
  const PlanEditorDayTabs({
    super.key,
    required this.plan,
    required this.allViolations,
    required this.highlightedDays,
  });

  @override
  State<PlanEditorDayTabs> createState() => _PlanEditorDayTabsState();
}

class _PlanEditorDayTabsState extends State<PlanEditorDayTabs>
    with SingleTickerProviderStateMixin {
  TabController? _controller;
  int _lastLength = 0;

  @override
  void initState() {
    super.initState();
    _rebuildController();
  }

  @override
  void didUpdateWidget(covariant PlanEditorDayTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.plan.days.length != _lastLength) {
      _rebuildController();
    }
  }

  void _rebuildController() {
    final old = _controller;
    _lastLength = widget.plan.days.length;
    if (_lastLength == 0) {
      _controller = null;
      old?.dispose();
      return;
    }
    final preserveIndex =
        (old != null && old.index < _lastLength) ? old.index : 0;
    _controller = TabController(
      length: _lastLength,
      vsync: this,
      initialIndex: preserveIndex,
    );
    old?.dispose();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.plan.days.isEmpty || _controller == null) {
      return Container(
        padding: const EdgeInsets.all(DT.s5),
        decoration: BoxDecoration(
          color: DT.of(context).cardSurface,
          borderRadius: BorderRadius.circular(DT.rCardSmall),
        ),
        child: Text(
          'A terv üres. Használd a finomítást alul, vagy adj hozzá napokat.',
          style: TextStyle(color: DT.of(context).textSecondary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DayTabBar(
          controller: _controller!,
          days: widget.plan.days,
          errorsByDay: _errorsByDay(),
          warningsByDay: _warningsByDay(),
        ),
        const SizedBox(height: DT.s3),
        AnimatedBuilder(
          animation: _controller!,
          builder: (context, _) {
            final day = widget.plan.days[_controller!.index];
            return _DayContent(
              day: day,
              violations: widget.allViolations,
              highlighted: widget.highlightedDays.contains(day.dayIndex),
            );
          },
        ),
      ],
    );
  }

  Map<int, int> _errorsByDay() {
    final m = <int, int>{};
    for (final v in widget.allViolations.where((v) => v.isError)) {
      final k = v.dayIndex;
      if (k != null) m.update(k, (c) => c + 1, ifAbsent: () => 1);
    }
    return m;
  }

  Map<int, int> _warningsByDay() {
    final m = <int, int>{};
    for (final v in widget.allViolations.where((v) => v.isWarning)) {
      final k = v.dayIndex;
      if (k != null) m.update(k, (c) => c + 1, ifAbsent: () => 1);
    }
    return m;
  }
}

class _DayTabBar extends StatelessWidget {
  final TabController controller;
  final List<PlanDayModel> days;
  final Map<int, int> errorsByDay;
  final Map<int, int> warningsByDay;

  const _DayTabBar({
    required this.controller,
    required this.days,
    required this.errorsByDay,
    required this.warningsByDay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DT.of(context).cardSurface,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        indicatorColor: DT.metricBlue,
        labelColor: DT.metricBlue,
        unselectedLabelColor: DT.of(context).textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: [
          for (final d in days)
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${d.dayIndex + 1}. ${d.label}'),
                  if ((errorsByDay[d.dayIndex] ?? 0) > 0) ...[
                    const SizedBox(width: 6),
                    _CountDot(
                      count: errorsByDay[d.dayIndex]!,
                      color: DT.cardRed,
                    ),
                  ],
                  if ((warningsByDay[d.dayIndex] ?? 0) > 0) ...[
                    const SizedBox(width: 4),
                    _CountDot(
                      count: warningsByDay[d.dayIndex]!,
                      color: DT.cardOrange,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CountDot extends StatelessWidget {
  final int count;
  final Color color;
  const _CountDot({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DT.rChip),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DayContent extends StatelessWidget {
  final PlanDayModel day;
  final List<ViolationModel> violations;
  final bool highlighted;

  const _DayContent({
    required this.day,
    required this.violations,
    required this.highlighted,
  });

  List<ViolationModel> _forRow(int dayIndex, String? exerciseId) =>
      violations
          .where((v) =>
              v.dayIndex == dayIndex &&
              (exerciseId == null || v.exerciseId == exerciseId))
          .toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...day.exercises.asMap().entries.map((e) {
          final i = e.key;
          final ex = e.value;
          return PlanEditorExerciseRow(
            dayIndex: day.dayIndex,
            exerciseIndex: i,
            exercise: ex,
            rowViolations: _forRow(day.dayIndex, ex.exerciseId),
            highlighted: highlighted,
          );
        }),
        const SizedBox(height: DT.s2),
        _AddExerciseButton(dayIndex: day.dayIndex),
      ],
    );
  }
}

class _AddExerciseButton extends StatelessWidget {
  final int dayIndex;
  const _AddExerciseButton({required this.dayIndex});

  Future<void> _open(BuildContext context) async {
    final repo = context.read<ExerciseRepository>();
    final bloc = context.read<PlanEditorBloc>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DT.of(context).cardSurfaceElevated,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(DT.rCard))),
      builder: (sheet) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, ctrl) => ExercisePicker(
          exerciseRepo: repo,
          athleteId: null,
          scrollController: ctrl,
          onSelect: (ExerciseModel ex) {
            bloc.add(
                PlanEditorAddExercise(dayIndex: dayIndex, exercise: ex));
            Navigator.of(sheet).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _open(context),
        icon: const Icon(Icons.add),
        label: const Text('Gyakorlat hozzáadása'),
        style: OutlinedButton.styleFrom(
          foregroundColor: DT.metricBlue,
          side: const BorderSide(color: DT.metricBlue),
          padding: const EdgeInsets.symmetric(vertical: DT.s2),
        ),
      ),
    );
  }
}
