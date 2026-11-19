import 'package:mocktail/mocktail.dart';
import 'package:flutter_application_1/features/exercise/data/models/exercise_model.dart';
import 'package:flutter_application_1/features/exercise/data/repositories/exercise_repository.dart';

/// In-memory repository serving a fixed exercise list; honours the
/// server-side `search` / `muscleGroup` filters like the real endpoint.
class FakeExerciseRepository extends Fake implements ExerciseRepository {
  final List<ExerciseModel> exercises;
  FakeExerciseRepository(this.exercises);

  List<ExerciseModel> _query(String? search, String? muscleGroup) => exercises
      .where((e) => muscleGroup == null || e.muscleGroup == muscleGroup)
      .where((e) =>
          search == null ||
          e.name.toLowerCase().contains(search.toLowerCase()))
      .toList();

  @override
  Future<PaginatedExercises> getExercises({
    String? search,
    String? muscleGroup,
    int page = 1,
    int pageSize = 20,
  }) async =>
      PaginatedExercises(items: _query(search, muscleGroup));

  @override
  Future<List<ExerciseModel>> getExercisesForAthlete(
    String athleteId, {
    String? search,
    String? muscleGroup,
  }) async =>
      _query(search, muscleGroup);
}

/// Exercises after the typed-metadata migration.
const typedExercises = [
  ExerciseModel(
    id: 'bench',
    name: 'Bench Press',
    muscleGroup: 'Mellizom',
    equipment: 'Barbell',
    equipmentTypes: ['Barbell'],
    movementPattern: 'HorizontalPush',
    isCompound: true,
  ),
  ExerciseModel(
    id: 'fly',
    name: 'Dumbbell Fly',
    muscleGroup: 'Mellizom',
    equipment: 'Dumbbell',
    equipmentTypes: ['Dumbbell'],
    movementPattern: 'Isolation',
    isCompound: false,
  ),
  ExerciseModel(
    id: 'pushup',
    name: 'Push-up',
    muscleGroup: 'Mellizom',
    equipment: 'Bodyweight',
    equipmentTypes: ['Bodyweight'],
    movementPattern: 'HorizontalPush',
    isCompound: true,
  ),
];

/// Exercises from before the migration: free-text equipment only.
const legacyExercises = [
  ExerciseModel(
    id: 'legacy-bench',
    name: 'Fekvenyomás',
    muscleGroup: 'Mellizom',
    equipment: 'Szabadsúly',
  ),
  ExerciseModel(
    id: 'legacy-custom',
    name: 'Saját gyakorlat',
    muscleGroup: 'Hátizom',
    equipment: 'Gép',
    createdByTrainerId: 't1',
  ),
];
