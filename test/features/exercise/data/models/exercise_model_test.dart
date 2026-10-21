import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/exercise/data/models/exercise_model.dart';

void main() {
  group('ExerciseModel', () {
    test('fromJson parses the full Phase 0 shape', () {
      final e = ExerciseModel.fromJson({
        'id': 'e1',
        'name': 'Bench Press',
        'muscleGroup': 'Chest',
        'secondaryMuscleGroups': ['Shoulders', 'Arms'],
        'description': 'Barbell bench press',
        'equipment': ['Barbell', 'Bench'],
        'movementPattern': 'HorizontalPush',
        'isCompound': true,
        'minLevel': 'Beginner',
        'stressTags': ['shoulder'],
        'createdByTrainerId': null,
      });

      expect(e.id, 'e1');
      expect(e.name, 'Bench Press');
      expect(e.muscleGroup, 'Chest');
      expect(e.secondaryMuscleGroups, ['Shoulders', 'Arms']);
      expect(e.equipmentTypes, ['Barbell', 'Bench']);
      expect(e.equipment, 'Barbell, Bench');
      expect(e.movementPattern, 'HorizontalPush');
      expect(e.isCompound, true);
      expect(e.minLevel, 'Beginner');
      expect(e.stressTags, ['shoulder']);
      expect(e.isCustom, isFalse);
    });

    test('fromJson keeps the legacy equipment string', () {
      final e = ExerciseModel.fromJson({
        'id': 'e2',
        'name': 'Dumbbell Curl',
        'muscleGroup': 'Arms',
        'equipment': 'Dumbbell',
      });

      expect(e.equipment, 'Dumbbell');
      expect(e.equipmentTypes, isEmpty);
      expect(e.secondaryMuscleGroups, isEmpty);
      expect(e.stressTags, isEmpty);
      expect(e.movementPattern, isNull);
      expect(e.isCompound, isNull);
    });

    test('fromJson/toJson round-trip preserves Phase 0 fields', () {
      final original = ExerciseModel.fromJson({
        'id': 'e3',
        'name': 'Pull-up',
        'muscleGroup': 'Back',
        'secondaryMuscleGroups': ['Arms'],
        'equipment': ['Bodyweight'],
        'movementPattern': 'VerticalPull',
        'isCompound': true,
        'minLevel': 'Intermediate',
        'stressTags': ['elbow', 'shoulder'],
        'createdByTrainerId': 't1',
        'usageCount': 7,
      });

      final round = ExerciseModel.fromJson(original.toJson());

      expect(round.id, original.id);
      expect(round.name, original.name);
      expect(round.muscleGroup, original.muscleGroup);
      expect(round.secondaryMuscleGroups, original.secondaryMuscleGroups);
      expect(round.equipmentTypes, original.equipmentTypes);
      expect(round.movementPattern, original.movementPattern);
      expect(round.isCompound, original.isCompound);
      expect(round.minLevel, original.minLevel);
      expect(round.stressTags, original.stressTags);
      expect(round.createdByTrainerId, original.createdByTrainerId);
      expect(round.usageCount, original.usageCount);
    });

    test('fromJson treats missing collections as empty lists', () {
      final e = ExerciseModel.fromJson({
        'id': 'e4',
        'name': 'Plank',
        'muscleGroup': 'Core',
      });

      expect(e.secondaryMuscleGroups, isEmpty);
      expect(e.equipmentTypes, isEmpty);
      expect(e.stressTags, isEmpty);
      expect(e.equipment, isNull);
    });
  });
}
