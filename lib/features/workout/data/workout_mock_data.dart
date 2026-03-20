import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'models/workout_model.dart';

class WorkoutMockData {
  static List<WorkoutModel> getAthleteWorkouts(String athleteId) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final wednesday = monday.add(const Duration(days: 2));
    final friday = monday.add(const Duration(days: 4));

    return [
      _buildFullBodyWorkout(id: 'w1-$athleteId', date: monday, athleteId: athleteId),
      _buildUpperBodyWorkout(id: 'w2-$athleteId', date: wednesday, athleteId: athleteId),
      _buildLowerBodyWorkout(id: 'w3-$athleteId', date: friday, athleteId: athleteId),
    ];
  }

  static WorkoutModel? getWorkoutForDate(DateTime date, {String athleteId = 'a1'}) {
    final workouts = getAthleteWorkouts(athleteId);
    try {
      return workouts.firstWhere(
        (w) =>
            w.scheduledDate.year == date.year &&
            w.scheduledDate.month == date.month &&
            w.scheduledDate.day == date.day,
      );
    } catch (_) {
      return null;
    }
  }

  static WorkoutModel _buildFullBodyWorkout({
    required String id,
    required DateTime date,
    required String athleteId,
  }) {
    return WorkoutModel(
      id: id,
      title: 'Teljes test edzés',
      description: 'Az egész testet átfogó edzés, az összes főbb izomcsoport megdolgozásával.',
      scheduledDate: date,
      athleteId: athleteId,
      coachId: 'c1',
      difficulty: WorkoutDifficulty.moderate,
      color: DT.cardBlue,
      estimatedDuration: '60 perc',
      kcal: '450 kcal',
      exercises: [
        const WorkoutExercise(
          exerciseId: 'e1',
          name: 'Fekvenyomás',
          index: 0,
          sets: 3,
          targetReps: 8,
          targetWeightKg: 80,
          instructions: 'Vegyél mély lélegzetet, majd nyomd fel a súlyrudat egyenletesen.',
        ),
        const WorkoutExercise(
          exerciseId: 'e2',
          name: 'Guggolás',
          index: 1,
          sets: 3,
          targetReps: 6,
          targetWeightKg: 100,
          instructions: 'Tartsd egyenesen a hátat, és guggolj le combtőig.',
        ),
        const WorkoutExercise(
          exerciseId: 'e3',
          name: 'Felhúzás',
          index: 2,
          sets: 3,
          targetReps: 5,
          targetWeightKg: 120,
          instructions: 'Tartsd a gerinced semlegesben végig a mozgás során.',
        ),
        const WorkoutExercise(
          exerciseId: 'e4',
          name: 'Húzódzkodás',
          index: 3,
          sets: 3,
          targetReps: 10,
          targetWeightKg: 0,
          instructions: 'Teljes mozgástartományban végezd az ismétléseket.',
        ),
      ],
    );
  }

  static WorkoutModel _buildUpperBodyWorkout({
    required String id,
    required DateTime date,
    required String athleteId,
  }) {
    return WorkoutModel(
      id: id,
      title: 'Felső test edzés',
      description: 'Mellkas, háto, vállak, bicepsz és tricepsz fókuszú edzés.',
      scheduledDate: date,
      athleteId: athleteId,
      coachId: 'c1',
      difficulty: WorkoutDifficulty.moderate,
      color: DT.cardTeal,
      estimatedDuration: '55 perc',
      kcal: '380 kcal',
      exercises: [
        const WorkoutExercise(
          exerciseId: 'e5',
          name: 'Emelkedő fekvenyomás',
          index: 0,
          sets: 3,
          targetReps: 10,
          targetWeightKg: 70,
          instructions: 'Dönts 30–45 fokra a paddot a felső mellkas aktiválásához.',
        ),
        const WorkoutExercise(
          exerciseId: 'e6',
          name: 'Evezés rúddal',
          index: 1,
          sets: 4,
          targetReps: 8,
          targetWeightKg: 80,
          instructions: 'Tartsd a törzset 45 fokos szögben, könyök a test mellett.',
        ),
        const WorkoutExercise(
          exerciseId: 'e7',
          name: 'Bicepsz curl',
          index: 2,
          sets: 3,
          targetReps: 12,
          targetWeightKg: 16,
          instructions: 'Lassan engedd vissza, ne lendítsd a könyököd.',
        ),
        const WorkoutExercise(
          exerciseId: 'e8',
          name: 'Tricepsz nyomás',
          index: 3,
          sets: 3,
          targetReps: 12,
          targetWeightKg: 25,
          instructions: 'Tartsd a könyököt rögzítve, csak az alkar mozogjon.',
        ),
        const WorkoutExercise(
          exerciseId: 'e9',
          name: 'Oldalsó emelés',
          index: 4,
          sets: 3,
          targetReps: 15,
          targetWeightKg: 12,
          instructions: 'Enyhén hajlított könyökkel emeld oldalt vállmagasságig.',
        ),
      ],
    );
  }

  static WorkoutModel _buildLowerBodyWorkout({
    required String id,
    required DateTime date,
    required String athleteId,
  }) {
    return WorkoutModel(
      id: id,
      title: 'Alsó test edzés',
      description: 'Lábak, vádli és farizmok teljes edzése.',
      scheduledDate: date,
      athleteId: athleteId,
      coachId: 'c1',
      difficulty: WorkoutDifficulty.hard,
      color: DT.cardOrange,
      estimatedDuration: '65 perc',
      kcal: '550 kcal',
      exercises: [
        const WorkoutExercise(
          exerciseId: 'e10',
          name: 'Guggolás',
          index: 0,
          sets: 4,
          targetReps: 8,
          targetWeightKg: 100,
          instructions: 'Mély guggolás, combtőig le, egyenes hát.',
        ),
        const WorkoutExercise(
          exerciseId: 'e11',
          name: 'Lábnyomás',
          index: 1,
          sets: 4,
          targetReps: 10,
          targetWeightKg: 150,
          instructions: 'Ne engedd ki teljesen a térdeket, tartsd a feszítést.',
        ),
        const WorkoutExercise(
          exerciseId: 'e12',
          name: 'Lábhajlítás',
          index: 2,
          sets: 3,
          targetReps: 12,
          targetWeightKg: 50,
          instructions: 'Lassan engedd vissza, tartsd a feszítést a combhajlítón.',
        ),
        const WorkoutExercise(
          exerciseId: 'e13',
          name: 'Vádli emelés',
          index: 3,
          sets: 4,
          targetReps: 15,
          targetWeightKg: 80,
          instructions: 'Teljes mozgástartomány, tetőn tartsd 1 másodpercig.',
        ),
      ],
    );
  }

  // Exercise library for workout builder
  static const List<Map<String, String>> exerciseLibrary = [
    {'name': 'Fekvenyomás', 'category': 'Mellkas'},
    {'name': 'Emelkedő fekvenyomás', 'category': 'Mellkas'},
    {'name': 'Tárogatás', 'category': 'Mellkas'},
    {'name': 'Guggolás', 'category': 'Lábak'},
    {'name': 'Lábnyomás', 'category': 'Lábak'},
    {'name': 'Lábhajlítás', 'category': 'Lábak'},
    {'name': 'Vádli emelés', 'category': 'Lábak'},
    {'name': 'Kitörés', 'category': 'Lábak'},
    {'name': 'Felhúzás', 'category': 'Háto'},
    {'name': 'Húzódzkodás', 'category': 'Háto'},
    {'name': 'Evezés rúddal', 'category': 'Háto'},
    {'name': 'Evezés gépen', 'category': 'Háto'},
    {'name': 'Vállnyomás', 'category': 'Vállak'},
    {'name': 'Oldalsó emelés', 'category': 'Vállak'},
    {'name': 'Elülső emelés', 'category': 'Vállak'},
    {'name': 'Bicepsz curl', 'category': 'Bicepsz'},
    {'name': 'Kalapács curl', 'category': 'Bicepsz'},
    {'name': 'Tricepsz nyomás', 'category': 'Tricepsz'},
    {'name': 'Francia nyomás', 'category': 'Tricepsz'},
    {'name': 'Plank', 'category': 'Core'},
    {'name': 'Hasprés', 'category': 'Core'},
    {'name': 'Orosz csavarás', 'category': 'Core'},
  ];
}
