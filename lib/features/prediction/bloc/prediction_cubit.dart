import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/features/prediction/data/models/prediction_models.dart';
import 'package:flutter_application_1/features/prediction/data/repositories/prediction_repository.dart';

// States
abstract class PredictionState {
  const PredictionState();
}

class PredictionInitial extends PredictionState {
  const PredictionInitial();
}

class PredictionLoading extends PredictionState {
  const PredictionLoading();
}

/// Empty state - backend returned 404 (no completed sessions for this exercise).
class PredictionEmpty extends PredictionState {
  final String exerciseName;
  const PredictionEmpty(this.exerciseName);
}

/// Trainer is not authorised to view this athlete's data (backend 403).
class PredictionForbidden extends PredictionState {
  const PredictionForbidden();
}

class PredictionLoaded extends PredictionState {
  final PredictionResult result;
  const PredictionLoaded(this.result);
}

class PredictionError extends PredictionState {
  final String message;
  const PredictionError(this.message);
}

// Cubit
class PredictionCubit extends Cubit<PredictionState> {
  final PredictionRepository _repo;

  PredictionCubit(this._repo) : super(const PredictionInitial());

  /// [athleteId] non-null switches to the trainer endpoint.
  Future<void> load({
    required String exerciseName,
    int weeksAhead = 8,
    String? focus,
    String? athleteId,
  }) async {
    emit(const PredictionLoading());
    try {
      final result = athleteId != null
          ? await _repo.getPredictionForAthlete(
              athleteId: athleteId,
              exerciseName: exerciseName,
              weeksAhead: weeksAhead,
              focus: focus,
            )
          : await _repo.getMyPrediction(
              exerciseName: exerciseName,
              weeksAhead: weeksAhead,
              focus: focus,
            );
      emit(PredictionLoaded(result));
    } on PredictionEmptyException {
      emit(PredictionEmpty(exerciseName));
    } on PredictionForbiddenException {
      emit(const PredictionForbidden());
    } catch (_) {
      emit(const PredictionError('Nem sikerült betölteni az előrejelzést.'));
    }
  }

  void reset() => emit(const PredictionInitial());
}
