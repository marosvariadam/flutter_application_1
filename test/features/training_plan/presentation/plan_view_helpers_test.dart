import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/training_plan/data/models/training_plan_model.dart';
import 'package:flutter_application_1/features/training_plan/presentation/widgets/my_plan_section.dart';
import 'package:flutter_application_1/features/training_plan/presentation/widgets/plan_editor_accept_sheet.dart';
import 'package:flutter_application_1/features/training_plan/presentation/widgets/plan_read_only_days.dart';

void main() {
  group('nextMondayAfter', () {
    test('jumps to the coming Monday at midnight', () {
      // 2026-11-19 is a Thursday.
      expect(nextMondayAfter(DateTime(2026, 11, 19, 15, 30)),
          DateTime(2026, 11, 23));
      expect(nextMondayAfter(DateTime(2026, 11, 22, 23, 59)),
          DateTime(2026, 11, 23));
    });

    test('on a Monday it moves a full week ahead', () {
      expect(nextMondayAfter(DateTime(2026, 11, 23, 8)),
          DateTime(2026, 11, 30));
    });

    test('crosses month and year boundaries', () {
      expect(nextMondayAfter(DateTime(2026, 12, 31)), DateTime(2027, 1, 4));
    });

    test('stays on Monday across the October DST change', () {
      // Europe/Budapest leaves DST on 2026-10-25; a 24h-duration based
      // implementation could land on Sunday 23:00 here.
      final next = nextMondayAfter(DateTime(2026, 10, 24, 0, 30));
      expect(next, DateTime(2026, 10, 26));
      expect(next.weekday, DateTime.monday);
    });
  });

  test('formatRest reads naturally in Hungarian', () {
    expect(formatRest(45), '45 mp');
    expect(formatRest(60), '1 perc');
    expect(formatRest(120), '2 perc');
    expect(formatRest(150), '2 p 30 mp');
  });

  test('planSummaryLine shows weeks, days and status', () {
    final plan = TrainingPlanModel(
      id: 'p1',
      trainerId: 't1',
      athleteId: 'a1',
      title: 'T',
      goal: 'Strength',
      weeks: 6,
      split: PlanSplits.fullBody,
      status: PlanStatuses.materialized,
      progression: PlanProgressionSchemes.linear,
      source: PlanGenerationSources.constraint,
      createdAt: DateTime.utc(2026, 11, 1),
      days: const [
        PlanDayModel(dayIndex: 0, label: 'A', exercises: []),
        PlanDayModel(dayIndex: 2, label: 'B', exercises: []),
        PlanDayModel(dayIndex: 4, label: 'C', exercises: []),
      ],
    );
    expect(planSummaryLine(plan), '6 hét · 3 nap / hét · Ütemezve');
  });
}
