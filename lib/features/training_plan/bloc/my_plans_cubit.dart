import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/features/training_plan/data/models/training_plan_model.dart';
import 'package:flutter_application_1/features/training_plan/data/repositories/training_plan_repository.dart';

// States
abstract class MyPlansState {
  const MyPlansState();
}

class MyPlansInitial extends MyPlansState {
  const MyPlansInitial();
}

class MyPlansLoading extends MyPlansState {
  const MyPlansLoading();
}

/// The athlete has no accepted plan yet.
class MyPlansEmpty extends MyPlansState {
  const MyPlansEmpty();
}

class MyPlansLoaded extends MyPlansState {
  /// Newest first; never empty.
  final List<TrainingPlanModel> plans;
  const MyPlansLoaded(this.plans);

  /// The plan to show by default: the newest one that isn't archived.
  TrainingPlanModel get current => plans.firstWhere(
        (p) => p.status != PlanStatuses.archived,
        orElse: () => plans.first,
      );
}

class MyPlansError extends MyPlansState {
  final String message;
  const MyPlansError(this.message);
}

/// Athlete-side list of accepted plans (`GET /api/plan/me`). The backend
/// never returns drafts here.
class MyPlansCubit extends Cubit<MyPlansState> {
  final TrainingPlanRepository _repo;

  MyPlansCubit(this._repo) : super(const MyPlansInitial());

  /// Reloading over an already shown plan skips the Loading state so the
  /// section doesn't disappear during a pull-to-refresh.
  Future<void> load() async {
    if (state is! MyPlansLoaded) emit(const MyPlansLoading());
    try {
      final plans = List<TrainingPlanModel>.from(await _repo.mine())
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (isClosed) return;
      emit(plans.isEmpty ? const MyPlansEmpty() : MyPlansLoaded(plans));
    } catch (_) {
      if (!isClosed) {
        emit(const MyPlansError('Nem sikerült betölteni az edzéstervet.'));
      }
    }
  }
}
