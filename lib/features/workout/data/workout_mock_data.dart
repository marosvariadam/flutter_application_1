import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'models/exercise_model.dart';
import 'models/exercise_set_model.dart';
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
      difficulty: 'Közepes',
      color: DT.cardBlue,
      estimatedDuration: '60 perc',
      kcal: '450 kcal',
      exercises: [
        const ExerciseModel(
          id: 'e1',
          name: 'Fekvenyomás',
          description: 'Vegyél mély lélegzetet, majd nyomd fel a súlyrudat egyenletesen.',
          category: 'Mellkas',
          sets: [
            ExerciseSetModel(setNumber: 1, weight: 80, reps: 8),
            ExerciseSetModel(setNumber: 2, weight: 80, reps: 8),
            ExerciseSetModel(setNumber: 3, weight: 75, reps: 10),
          ],
        ),
        const ExerciseModel(
          id: 'e2',
          name: 'Guggolás',
          description: 'Tartsd egyenesen a hátat, és guggolj le combtőig.',
          category: 'Lábak',
          sets: [
            ExerciseSetModel(setNumber: 1, weight: 100, reps: 6),
            ExerciseSetModel(setNumber: 2, weight: 100, reps: 6),
            ExerciseSetModel(setNumber: 3, weight: 90, reps: 8),
          ],
        ),
        const ExerciseModel(
          id: 'e3',
          name: 'Felhúzás',
          description: 'Tartsd a gerinced semlegesben végig a mozgás során.',
          category: 'Háto',
          sets: [
            ExerciseSetModel(setNumber: 1, weight: 120, reps: 5),
            ExerciseSetModel(setNumber: 2, weight: 120, reps: 5),
            ExerciseSetModel(setNumber: 3, weight: 110, reps: 6),
          ],
        ),
        const ExerciseModel(
          id: 'e4',
          name: 'Húzódzkodás',
          description: 'Teljes mozgástartományban végezd az ismétléseket.',
          category: 'Háto',
          sets: [
            ExerciseSetModel(setNumber: 1, reps: 10),
            ExerciseSetModel(setNumber: 2, reps: 8),
            ExerciseSetModel(setNumber: 3, reps: 8),
          ],
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
      difficulty: 'Közepes',
      color: DT.cardTeal,
      estimatedDuration: '55 perc',
      kcal: '380 kcal',
      exercises: [
        const ExerciseModel(
          id: 'e5',
          name: 'Emelkedő fekvenyomás',
          description: 'Dönts 30–45 fokra a paddot a felső mellkas aktiválásához.',
          category: 'Mellkas',
          sets: [
            ExerciseSetModel(setNumber: 1, weight: 70, reps: 10),
            ExerciseSetModel(setNumber: 2, weight: 70, reps: 10),
            ExerciseSetModel(setNumber: 3, weight: 65, reps: 12),
          ],
        ),
        const ExerciseModel(
          id: 'e6',
          name: 'Evezés rúddal',
          description: 'Tartsd a törzset 45 fokos szögben, könyök a test mellett.',
          category: 'Háto',
          sets: [
            ExerciseSetModel(setNumber: 1, weight: 80, reps: 8),
            ExerciseSetModel(setNumber: 2, weight: 80, reps: 8),
            ExerciseSetModel(setNumber: 3, weight: 75, reps: 10),
            ExerciseSetModel(setNumber: 4, weight: 75, reps: 10),
          ],
        ),
        const ExerciseModel(
          id: 'e7',
          name: 'Bicepsz curl',
          description: 'Lassan engedd vissza, ne lendítsd a könyököd.',
          category: 'Bicepsz',
          sets: [
            ExerciseSetModel(setNumber: 1, weight: 16, reps: 12),
            ExerciseSetModel(setNumber: 2, weight: 16, reps: 12),
            ExerciseSetModel(setNumber: 3, weight: 14, reps: 15),
          ],
        ),
        const ExerciseModel(
          id: 'e8',
          name: 'Tricepsz nyomás',
          description: 'Tartsd a könyököt rögzítve, csak az alkar mozogjon.',
          category: 'Tricepsz',
          sets: [
            ExerciseSetModel(setNumber: 1, weight: 25, reps: 12),
            ExerciseSetModel(setNumber: 2, weight: 25, reps: 12),
            ExerciseSetModel(setNumber: 3, weight: 22, reps: 15),
          ],
        ),
        const ExerciseModel(
          id: 'e9',
          name: 'Oldalsó emelés',
          description: 'Enyhén hajlított könyökkel emeld oldalt vállmagasságig.',
          category: 'Vállak',
          sets: [
            ExerciseSetModel(setNumber: 1, weight: 12, reps: 15),
            ExerciseSetModel(setNumber: 2, weight: 12, reps: 15),
            ExerciseSetModel(setNumber: 3, weight: 10, reps: 15),
          ],
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
      difficulty: 'Nehéz',
      color: DT.cardOrange,
      estimatedDuration: '65 perc',
      kcal: '550 kcal',
      exercises: [
        const ExerciseModel(
          id: 'e10',
          name: 'Guggolás',
          description: 'Mély guggolás, combtőig le, egyenes hát.',
          category: 'Lábak',
          sets: [
            ExerciseSetModel(setNumber: 1, weight: 100, reps: 8),
            ExerciseSetModel(setNumber: 2, weight: 100, reps: 8),
            ExerciseSetModel(setNumber: 3, weight: 95, reps: 10),
            ExerciseSetModel(setNumber: 4, weight: 90, reps: 12),
          ],
        ),
        const ExerciseModel(
          id: 'e11',
          name: 'Lábnyomás',
          description: 'Ne engedd ki teljesen a térdeket, tartsd a feszítést.',
          category: 'Lábak',
          sets: [
            ExerciseSetModel(setNumber: 1, weight: 150, reps: 10),
            ExerciseSetModel(setNumber: 2, weight: 150, reps: 10),
            ExerciseSetModel(setNumber: 3, weight: 140, reps: 12),
            ExerciseSetModel(setNumber: 4, weight: 140, reps: 12),
          ],
        ),
        const ExerciseModel(
          id: 'e12',
          name: 'Lábhajlítás',
          description: 'Lassan engedd vissza, tartsd a feszítést a combhajlítón.',
          category: 'Lábak',
          sets: [
            ExerciseSetModel(setNumber: 1, weight: 50, reps: 12),
            ExerciseSetModel(setNumber: 2, weight: 50, reps: 12),
            ExerciseSetModel(setNumber: 3, weight: 45, reps: 15),
          ],
        ),
        const ExerciseModel(
          id: 'e13',
          name: 'Vádli emelés',
          description: 'Teljes mozgástartomány, tetőn tartsd 1 másodpercig.',
          category: 'Lábak',
          sets: [
            ExerciseSetModel(setNumber: 1, weight: 80, reps: 15),
            ExerciseSetModel(setNumber: 2, weight: 80, reps: 15),
            ExerciseSetModel(setNumber: 3, weight: 80, reps: 15),
            ExerciseSetModel(setNumber: 4, weight: 80, reps: 15),
          ],
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
