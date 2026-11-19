import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/core/api/api_error_messages.dart';
import 'package:flutter_application_1/features/training_plan/data/models/plan_results.dart';
import 'package:flutter_application_1/features/training_plan/data/repositories/training_plan_repository.dart';

// States
abstract class PlanExplanationState {
  const PlanExplanationState();
}

/// Nothing requested yet. The explanation is LLM-generated and
/// rate-limited, so it is only fetched when the user asks for it.
class PlanExplanationIdle extends PlanExplanationState {
  const PlanExplanationIdle();
}

class PlanExplanationLoading extends PlanExplanationState {
  const PlanExplanationLoading();
}

class PlanExplanationLoaded extends PlanExplanationState {
  final PlanExplanationModel explanation;
  const PlanExplanationLoaded(this.explanation);
}

class PlanExplanationRateLimited extends PlanExplanationState {
  const PlanExplanationRateLimited();
}

class PlanExplanationUnavailable extends PlanExplanationState {
  const PlanExplanationUnavailable();
}

/// Athletes may only read explanations of their own non-draft plans.
class PlanExplanationForbidden extends PlanExplanationState {
  const PlanExplanationForbidden();
}

class PlanExplanationError extends PlanExplanationState {
  final String message;
  const PlanExplanationError(this.message);
}

// Cubit
class PlanExplanationCubit extends Cubit<PlanExplanationState> {
  final TrainingPlanRepository _repo;

  /// UI copy is Hungarian, so explanations are requested in Hungarian.
  final String language;

  PlanExplanationCubit(this._repo, {this.language = 'hu'})
      : super(const PlanExplanationIdle());

  Future<void> load(String planId) async {
    // A second tap while the LLM is still working would only burn quota.
    if (state is PlanExplanationLoading) return;
    emit(const PlanExplanationLoading());
    try {
      final result =
          await _repo.explanation(planId: planId, language: language);
      if (isClosed) return;
      emit(PlanExplanationLoaded(result));
    } on PlanRateLimitedException {
      if (!isClosed) emit(const PlanExplanationRateLimited());
    } on PlanLlmUnavailableException {
      if (!isClosed) emit(const PlanExplanationUnavailable());
    } on PlanForbiddenException {
      if (!isClosed) emit(const PlanExplanationForbidden());
    } on PlanNotFoundException {
      if (!isClosed) emit(const PlanExplanationError('A terv nem található.'));
    } catch (e) {
      if (!isClosed) {
        emit(PlanExplanationError(friendlyErrorMessage(e,
            fallback: 'Nem sikerült betölteni a magyarázatot.')));
      }
    }
  }
}
