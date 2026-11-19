import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/features/autoregulation/data/models/autoregulation_model.dart';
import 'package:flutter_application_1/features/autoregulation/data/repositories/autoregulation_repository.dart';

// States
abstract class AutoregulationState {
  const AutoregulationState();
}

/// No athlete selected yet.
class AutoregulationInitial extends AutoregulationState {
  const AutoregulationInitial();
}

class AutoregulationLoading extends AutoregulationState {
  final String athleteId;
  const AutoregulationLoading(this.athleteId);
}

/// Also covers "no accepted plan" — check `result.hasPlan`.
class AutoregulationLoaded extends AutoregulationState {
  final String athleteId;
  final NextWeekAutoregulationModel result;
  const AutoregulationLoaded(this.athleteId, this.result);
}

class AutoregulationForbidden extends AutoregulationState {
  final String athleteId;
  const AutoregulationForbidden(this.athleteId);
}

class AutoregulationError extends AutoregulationState {
  final String athleteId;
  final String message;
  const AutoregulationError(this.athleteId, this.message);
}

// Cubit
class AutoregulationCubit extends Cubit<AutoregulationState> {
  final AutoregulationRepository _repo;

  /// Bumped on every load/reset so a slow response for a previously
  /// selected athlete can't overwrite the current one.
  int _requestSeq = 0;

  AutoregulationCubit(this._repo) : super(const AutoregulationInitial());

  Future<void> load(String athleteId) async {
    final request = ++_requestSeq;
    emit(AutoregulationLoading(athleteId));
    try {
      final result = await _repo.nextWeek(athleteId);
      if (_isStale(request)) return;
      emit(AutoregulationLoaded(athleteId, result));
    } on AutoregulationForbiddenException {
      if (_isStale(request)) return;
      emit(AutoregulationForbidden(athleteId));
    } on AutoregulationNotFoundException {
      if (_isStale(request)) return;
      emit(AutoregulationError(athleteId, 'A sportoló nem található.'));
    } catch (_) {
      if (_isStale(request)) return;
      emit(AutoregulationError(
          athleteId, 'Az autoregulációs javaslatok nem tölthetők be.'));
    }
  }

  void reset() {
    _requestSeq++;
    emit(const AutoregulationInitial());
  }

  bool _isStale(int request) => isClosed || request != _requestSeq;
}
