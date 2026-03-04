import 'models/athlete_model.dart';
import 'package:flutter_application_1/features/workout/data/workout_mock_data.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';

class CoachMockData {
  static List<AthleteModel> getAthletes() {
    return const [
      AthleteModel(
        id: 'a1',
        firstName: 'Péter',
        lastName: 'Nagy',
        goal: 'Erő növelés',
        workoutCount: 28,
        streakDays: 5,
        lastWorkoutDate: '2024.11.15',
      ),
      AthleteModel(
        id: 'a2',
        firstName: 'Anna',
        lastName: 'Kiss',
        goal: 'Fogyás',
        workoutCount: 45,
        streakDays: 12,
        lastWorkoutDate: '2024.11.16',
      ),
      AthleteModel(
        id: 'a3',
        firstName: 'Balázs',
        lastName: 'Tóth',
        goal: 'Izomtömeg növelés',
        workoutCount: 15,
        streakDays: 3,
        lastWorkoutDate: '2024.11.14',
      ),
      AthleteModel(
        id: 'a4',
        firstName: 'Eszter',
        lastName: 'Varga',
        goal: 'Állóképesség',
        workoutCount: 67,
        streakDays: 21,
        lastWorkoutDate: '2024.11.16',
      ),
    ];
  }

  static AthleteModel? getAthleteById(String id) {
    try {
      return getAthletes().firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<WorkoutModel> getWorkoutsForAthlete(String athleteId) {
    return WorkoutMockData.getAthleteWorkouts(athleteId);
  }
}
