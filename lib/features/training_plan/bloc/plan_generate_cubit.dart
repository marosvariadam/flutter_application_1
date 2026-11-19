import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/core/api/api_error_messages.dart';
import 'package:flutter_application_1/features/training_plan/bloc/plan_messages.dart';
import 'package:flutter_application_1/features/training_plan/data/models/plan_results.dart';
import 'package:flutter_application_1/features/training_plan/data/models/training_plan_model.dart';
import 'package:flutter_application_1/features/training_plan/data/repositories/training_plan_repository.dart';

/// Progress hint for the generation spinner. The real request is one round
/// trip; the three stages are a UI affordance that the page renders with a
/// local ticker. They live on an enum here (rather than inside the page)
/// so both the page and anyone embedding the generate flow stay aligned.
enum PlanGenerateStage { candidates, scoring, validating }

// States
abstract class PlanGenerateState {
  const PlanGenerateState();
}

class PlanGenerateInitial extends PlanGenerateState {
  const PlanGenerateInitial();
}

/// Single "working" state; the page cycles [PlanGenerateStage] labels on
/// top of it with its own timer so the cubit stays testable without async
/// racing between the animation and the mocked response.
class PlanGenerateRunning extends PlanGenerateState {
  const PlanGenerateRunning();
}

class PlanGenerateSuccess extends PlanGenerateState {
  final GenerateResultModel result;
  const PlanGenerateSuccess(this.result);
}

/// Backend 400 — usually "Athlete has no AthleteProfile" or "Invalid
/// trainingBlockId". The wizard shows the server's message inline on the
/// form so the trainer can fix it without leaving the screen.
class PlanGenerateValidationError extends PlanGenerateState {
  final String message;
  const PlanGenerateValidationError(this.message);
}

class PlanGenerateRateLimited extends PlanGenerateState {
  const PlanGenerateRateLimited();
}

class PlanGenerateLlmUnavailable extends PlanGenerateState {
  final String message;
  const PlanGenerateLlmUnavailable(this.message);
}

class PlanGenerateForbidden extends PlanGenerateState {
  const PlanGenerateForbidden();
}

class PlanGenerateError extends PlanGenerateState {
  final String message;
  const PlanGenerateError(this.message);
}

/// Owns the generate wizard's state: form submit → running → either a
/// success with the saved plan + candidates, or a typed error the UI can
/// label precisely.
class PlanGenerateCubit extends Cubit<PlanGenerateState> {
  final TrainingPlanRepository _repo;

  PlanGenerateCubit(this._repo) : super(const PlanGenerateInitial());

  Future<void> generate({
    required String athleteId,
    required String mode,
    required int weeks,
    String? trainingBlockId,
  }) async {
    emit(const PlanGenerateRunning());
    try {
      final result = await _repo.generate(
        athleteId: athleteId,
        mode: mode,
        weeks: weeks,
        trainingBlockId: trainingBlockId,
      );
      emit(PlanGenerateSuccess(result));
    } on PlanValidationException catch (e) {
      emit(PlanGenerateValidationError(planServerMessageHu(e.message,
          fallback: 'A szerver elutasította a kérést.')));
    } on PlanForbiddenException {
      emit(const PlanGenerateForbidden());
    } on PlanRateLimitedException {
      emit(const PlanGenerateRateLimited());
    } on PlanLlmUnavailableException catch (e) {
      emit(PlanGenerateLlmUnavailable(e.message));
    } catch (e) {
      emit(PlanGenerateError(friendlyErrorMessage(e,
          fallback: 'Nem sikerült a terv generálása.')));
    }
  }

  void reset() => emit(const PlanGenerateInitial());

  /// Convenience for tests and any UI that wants to show the saved plan
  /// without re-running generate.
  TrainingPlanModel? get currentPlan =>
      state is PlanGenerateSuccess ? (state as PlanGenerateSuccess).result.plan : null;
}
