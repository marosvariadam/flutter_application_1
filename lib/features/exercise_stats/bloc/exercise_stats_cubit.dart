import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/features/exercise_stats/data/models/exercise_stat_point.dart';
import 'package:flutter_application_1/features/exercise_stats/data/repositories/exercise_stats_repository.dart';

// States
abstract class ExerciseStatsState {}

class ExerciseStatsInitial extends ExerciseStatsState {}

class ExerciseStatsLoading extends ExerciseStatsState {}

class ExerciseStatsLoaded extends ExerciseStatsState {
  final List<ExerciseStatPoint> points;
  final String exerciseName;
  final DateTime from;
  final DateTime to;

  ExerciseStatsLoaded({
    required this.points,
    required this.exerciseName,
    required this.from,
    required this.to,
  });
}

class ExerciseStatsError extends ExerciseStatsState {
  final String message;
  ExerciseStatsError(this.message);
}

// Cubit
class ExerciseStatsCubit extends Cubit<ExerciseStatsState> {
  final ExerciseStatsRepository _repo;

  ExerciseStatsCubit(this._repo) : super(ExerciseStatsInitial());

  Future<void> loadStats({
    required String exerciseName,
    DateTime? from,
    DateTime? to,
    String? athleteId,
  }) async {
    emit(ExerciseStatsLoading());
    final now = DateTime.now();
    final rawEnd = to ?? now;
    final rawStart = from ?? rawEnd.subtract(const Duration(days: 30));
    // Normalize: from -> start of day, to -> end of day so same-day workouts
    // (and workouts scheduled later today) are included in the range.
    final start = DateTime(rawStart.year, rawStart.month, rawStart.day);
    final end = DateTime(
        rawEnd.year, rawEnd.month, rawEnd.day, 23, 59, 59, 999);
    try {
      final points = athleteId != null
          ? await _repo.getStatsForAthlete(
              athleteId: athleteId,
              exerciseName: exerciseName,
              from: start,
              to: end,
            )
          : await _repo.getStats(
              exerciseName: exerciseName,
              from: start,
              to: end,
            );
      emit(ExerciseStatsLoaded(
        points: points,
        exerciseName: exerciseName,
        from: start,
        to: end,
      ));
    } catch (e) {
      emit(ExerciseStatsError('Nem sikerült betölteni a statisztikákat.'));
    }
  }
}
