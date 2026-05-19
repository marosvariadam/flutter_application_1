import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/features/onboarding/data/repositories/onboarding_repository.dart';
import 'package:flutter_application_1/features/trainer/data/repositories/trainer_request_repository.dart';

// States

abstract class AthleteStatusState {}

/// Not yet checked - shown briefly on app start.
class AthleteStatusInitial extends AthleteStatusState {}

/// Actively loading status from the API.
class AthleteStatusLoading extends AthleteStatusState {}

/// No accepted trainer request yet - athlete must wait.
class AthleteStatusPending extends AthleteStatusState {}

/// Trainer accepted, a form exists, and the athlete hasn't filled it yet.
class AthleteStatusNeedsForm extends AthleteStatusState {}

/// All good - athlete may access the main app.
class AthleteStatusReady extends AthleteStatusState {}

// Cubit

class AthleteStatusCubit extends Cubit<AthleteStatusState> {
  final TrainerRequestRepository _requestRepo;
  final OnboardingRepository _onboardingRepo;

  AthleteStatusCubit(this._requestRepo, this._onboardingRepo)
      : super(AthleteStatusInitial());

  /// Load trainer-acceptance + onboarding form status from the API.
  Future<void> check() async {
    emit(AthleteStatusLoading());
    try {
      final requests = await _requestRepo.getMyRequests();
      final hasAccepted = requests.any((r) => r.isAccepted);

      if (!hasAccepted) {
        emit(AthleteStatusPending());
        return;
      }

      // Accepted - check whether the trainer has a form and it's not yet filled.
      final form = await _onboardingRepo.getMyTrainerForm();
      if (form == null || form.questions.isEmpty) {
        emit(AthleteStatusReady());
        return;
      }

      final response = await _onboardingRepo.getMyResponse();
      if (response != null) {
        emit(AthleteStatusReady());
        return;
      }

      emit(AthleteStatusNeedsForm());
    } catch (_) {
      // Fail open so a network hiccup doesn't lock the athlete out.
      emit(AthleteStatusReady());
    }
  }

  /// Called when the athlete skips or submits the survey.
  void markReady() => emit(AthleteStatusReady());

  /// Reset when the user logs out.
  void reset() => emit(AthleteStatusInitial());
}
