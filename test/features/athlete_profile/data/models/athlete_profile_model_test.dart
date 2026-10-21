import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/athlete_profile/data/models/athlete_profile_model.dart';

void main() {
  group('AthleteProfileModel', () {
    test('fromJson parses the full server shape', () {
      final p = AthleteProfileModel.fromJson({
        'id': 'p1',
        'athleteId': 'a1',
        'goal': 'Hypertrophy',
        'experienceLevel': 'Intermediate',
        'daysPerWeek': 4,
        'sessionMinutes': 75,
        'availableEquipment': ['Barbell', 'Dumbbell'],
        'avoidStressTags': ['knee'],
        'excludedExerciseIds': ['e1'],
        'muscleGroupPriority': {'Chest': 1.2, 'Back': 1.0},
        'weightKg': 82.5,
        'sportHistory': 'Soccer 8y',
        'createdAt': '2026-10-01T12:00:00Z',
        'updatedAt': '2026-10-15T12:00:00Z',
      });

      expect(p.id, 'p1');
      expect(p.athleteId, 'a1');
      expect(p.goal, AthleteProfileGoals.hypertrophy);
      expect(p.experienceLevel, AthleteProfileExperienceLevels.intermediate);
      expect(p.daysPerWeek, 4);
      expect(p.sessionMinutes, 75);
      expect(p.availableEquipment,
          [AthleteProfileEquipment.barbell, AthleteProfileEquipment.dumbbell]);
      expect(p.avoidStressTags, [AthleteProfileStressTags.knee]);
      expect(p.excludedExerciseIds, ['e1']);
      expect(p.muscleGroupPriority, {'Chest': 1.2, 'Back': 1.0});
      expect(p.weightKg, 82.5);
      expect(p.sportHistory, 'Soccer 8y');
      expect(p.createdAt, isNotNull);
      expect(p.updatedAt, isNotNull);
    });

    test('fromJson falls back to defaults for missing fields', () {
      final p = AthleteProfileModel.fromJson({'athleteId': 'a1'});

      expect(p.goal, AthleteProfileGoals.generalFitness);
      expect(p.experienceLevel, AthleteProfileExperienceLevels.beginner);
      expect(p.daysPerWeek, 3);
      expect(p.sessionMinutes, 60);
      expect(p.availableEquipment, isEmpty);
      expect(p.avoidStressTags, isEmpty);
      expect(p.excludedExerciseIds, isEmpty);
      expect(p.muscleGroupPriority, isEmpty);
      expect(p.weightKg, isNull);
      expect(p.sportHistory, isNull);
    });

    test('toRequestJson omits server-owned fields', () {
      final p = AthleteProfileModel.fromJson({
        'id': 'p1',
        'athleteId': 'a1',
        'goal': 'Strength',
        'experienceLevel': 'Advanced',
        'daysPerWeek': 5,
        'sessionMinutes': 90,
        'availableEquipment': ['Barbell'],
        'avoidStressTags': ['lower_back'],
        'muscleGroupPriority': {'Legs': 1.5},
        'weightKg': 100.0,
        'sportHistory': 'Rugby',
        'createdAt': '2026-10-01T12:00:00Z',
      });

      final json = p.toRequestJson();

      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('athleteId'), isFalse);
      expect(json.containsKey('createdAt'), isFalse);
      expect(json.containsKey('updatedAt'), isFalse);
      expect(json['goal'], 'Strength');
      expect(json['availableEquipment'], ['Barbell']);
      expect(json['muscleGroupPriority'], {'Legs': 1.5});
      expect(json['weightKg'], 100.0);
      expect(json['sportHistory'], 'Rugby');
    });

    test('round-trip (fromJson → toRequestJson → fromJson) is stable', () {
      final original = AthleteProfileModel.fromJson({
        'athleteId': 'a1',
        'goal': 'FatLoss',
        'experienceLevel': 'Beginner',
        'daysPerWeek': 3,
        'sessionMinutes': 45,
        'availableEquipment': ['Dumbbell', 'Bodyweight'],
        'avoidStressTags': ['shoulder', 'wrist'],
        'muscleGroupPriority': {'Core': 1.3},
        'weightKg': 65.0,
      });

      final serialized = {
        'athleteId': original.athleteId,
        ...original.toRequestJson(),
      };
      final round = AthleteProfileModel.fromJson(serialized);

      expect(round.goal, original.goal);
      expect(round.experienceLevel, original.experienceLevel);
      expect(round.daysPerWeek, original.daysPerWeek);
      expect(round.sessionMinutes, original.sessionMinutes);
      expect(round.availableEquipment, original.availableEquipment);
      expect(round.avoidStressTags, original.avoidStressTags);
      expect(round.muscleGroupPriority, original.muscleGroupPriority);
      expect(round.weightKg, original.weightKg);
    });
  });
}
