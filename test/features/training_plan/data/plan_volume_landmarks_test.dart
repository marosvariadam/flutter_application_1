import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/athlete_profile/data/models/athlete_profile_model.dart';
import 'package:flutter_application_1/features/training_plan/data/models/training_plan_model.dart';
import 'package:flutter_application_1/features/training_plan/data/plan_volume_landmarks.dart';

PlannedExerciseModel _ex(String muscle, int sets) => PlannedExerciseModel(
      name: muscle,
      muscleGroup: muscle,
      sets: sets,
      repMin: 8,
      repMax: 12,
      targetRpe: 8,
      restSeconds: 90,
      order: 0,
    );

void main() {
  group('rangeFor', () {
    test('matches the backend table for each level', () {
      final chestBeginner =
          rangeFor('Chest', AthleteProfileExperienceLevels.beginner);
      expect([chestBeginner.mev, chestBeginner.mav, chestBeginner.mrv],
          [6, 10, 16]);
      final backIntermediate =
          rangeFor('Back', AthleteProfileExperienceLevels.intermediate);
      expect([backIntermediate.mev, backIntermediate.mav, backIntermediate.mrv],
          [10, 16, 25]);
      final legsAdvanced =
          rangeFor('Legs', AthleteProfileExperienceLevels.advanced);
      expect([legsAdvanced.mev, legsAdvanced.mav, legsAdvanced.mrv],
          [12, 20, 30]);
    });

    test('every chart muscle group has a range at every level', () {
      for (final level in AthleteProfileExperienceLevels.all) {
        for (final g in kChartMuscleGroups) {
          final r = rangeFor(g, level);
          expect(r.mev <= r.mav && r.mav <= r.mrv, isTrue,
              reason: '$g / $level');
          expect(r.mrv, lessThan(999), reason: '$g / $level');
        }
      }
    });

    test('unknown muscles and levels are permissive', () {
      final custom = rangeFor('Forearms', AthleteProfileExperienceLevels.advanced);
      expect([custom.mev, custom.mrv], [0, 999]);
      expect(rangeFor('Chest', 'Elite').mrv,
          rangeFor('Chest', AthleteProfileExperienceLevels.beginner).mrv);
    });
  });

  test('weeklySetsPerMuscleGroup sums primary sets across days', () {
    final plan = TrainingPlanModel(
      id: 'p1',
      trainerId: 't1',
      athleteId: 'a1',
      title: 'T',
      goal: 'Hypertrophy',
      weeks: 4,
      split: PlanSplits.upperLower,
      status: PlanStatuses.draft,
      progression: PlanProgressionSchemes.linear,
      source: PlanGenerationSources.manual,
      createdAt: DateTime.utc(2026, 11, 1),
      days: [
        PlanDayModel(
            dayIndex: 0,
            label: 'A',
            exercises: [_ex('Chest', 3), _ex('Back', 4), _ex('Chest', 2)]),
        PlanDayModel(dayIndex: 1, label: 'B', exercises: [_ex('Chest', 4)]),
        const PlanDayModel(dayIndex: 2, label: 'Rest', exercises: []),
      ],
    );
    expect(weeklySetsPerMuscleGroup(plan), {'Chest': 9, 'Back': 4});
  });
}
