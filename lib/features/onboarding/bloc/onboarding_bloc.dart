import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/features/onboarding/data/models/onboarding_models.dart';
import 'package:flutter_application_1/features/onboarding/data/repositories/onboarding_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class OnboardingEvent {}

// Trainer events
class LoadMyOnboardingForm extends OnboardingEvent {}

class SaveOnboardingForm extends OnboardingEvent {
  final String title;
  final String? description;
  final List<OnboardingQuestion> questions;
  SaveOnboardingForm(
      {required this.title, this.description, required this.questions});
}

class LoadAllResponses extends OnboardingEvent {}

class LoadAthleteResponse extends OnboardingEvent {
  final String athleteId;
  LoadAthleteResponse(this.athleteId);
}

// Athlete events
class LoadMyTrainerForm extends OnboardingEvent {}

class SubmitSurveyAnswers extends OnboardingEvent {
  final List<OnboardingAnswer> answers;
  SubmitSurveyAnswers(this.answers);
}

class LoadMyOnboardingResponse extends OnboardingEvent {}

// ── States ────────────────────────────────────────────────────────────────────
abstract class OnboardingState {}

class OnboardingInitial extends OnboardingState {}

class OnboardingLoading extends OnboardingState {}

class OnboardingFormLoaded extends OnboardingState {
  final OnboardingFormModel? form; // null means no form created yet
  OnboardingFormLoaded(this.form);
}

class OnboardingResponsesLoaded extends OnboardingState {
  final List<OnboardingResponse> responses;
  OnboardingResponsesLoaded(this.responses);
}

class OnboardingSingleResponseLoaded extends OnboardingState {
  final OnboardingResponse response;
  OnboardingSingleResponseLoaded(this.response);
}

class OnboardingSuccess extends OnboardingState {
  final String message;
  OnboardingSuccess(this.message);
}

class OnboardingError extends OnboardingState {
  final String message;
  OnboardingError(this.message);
}

// ── BLoC ──────────────────────────────────────────────────────────────────────
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final OnboardingRepository _repo;

  OnboardingBloc(this._repo) : super(OnboardingInitial()) {
    on<LoadMyOnboardingForm>(_onLoadMyForm);
    on<SaveOnboardingForm>(_onSaveForm);
    on<LoadAllResponses>(_onLoadAllResponses);
    on<LoadAthleteResponse>(_onLoadAthleteResponse);
    on<LoadMyTrainerForm>(_onLoadTrainerForm);
    on<SubmitSurveyAnswers>(_onSubmit);
    on<LoadMyOnboardingResponse>(_onLoadMyResponse);
  }

  Future<void> _onLoadMyForm(
      LoadMyOnboardingForm event, Emitter<OnboardingState> emit) async {
    emit(OnboardingLoading());
    try {
      final form = await _repo.getMyForm();
      emit(OnboardingFormLoaded(form));
    } catch (_) {
      emit(OnboardingError('Nem sikerült betölteni az űrlapot.'));
    }
  }

  Future<void> _onSaveForm(
      SaveOnboardingForm event, Emitter<OnboardingState> emit) async {
    emit(OnboardingLoading());
    try {
      final form = await _repo.saveForm(
        title: event.title,
        description: event.description,
        questions: event.questions,
      );
      emit(OnboardingFormLoaded(form));
    } catch (_) {
      emit(OnboardingError('Nem sikerült menteni az űrlapot.'));
    }
  }

  Future<void> _onLoadAllResponses(
      LoadAllResponses event, Emitter<OnboardingState> emit) async {
    emit(OnboardingLoading());
    try {
      final responses = await _repo.getAllResponses();
      emit(OnboardingResponsesLoaded(responses));
    } catch (_) {
      emit(OnboardingError('Nem sikerült betölteni a válaszokat.'));
    }
  }

  Future<void> _onLoadAthleteResponse(
      LoadAthleteResponse event, Emitter<OnboardingState> emit) async {
    emit(OnboardingLoading());
    try {
      final response = await _repo.getAthleteResponse(event.athleteId);
      emit(OnboardingSingleResponseLoaded(response));
    } catch (_) {
      emit(OnboardingError('Nem sikerült betölteni a választ.'));
    }
  }

  Future<void> _onLoadTrainerForm(
      LoadMyTrainerForm event, Emitter<OnboardingState> emit) async {
    emit(OnboardingLoading());
    try {
      final form = await _repo.getMyTrainerForm();
      emit(OnboardingFormLoaded(form));
    } catch (_) {
      emit(OnboardingError('Nincs elérhető felmérő.'));
    }
  }

  Future<void> _onSubmit(
      SubmitSurveyAnswers event, Emitter<OnboardingState> emit) async {
    emit(OnboardingLoading());
    try {
      await _repo.submitAnswers(event.answers);
      emit(OnboardingSuccess('Felmérő sikeresen elküldve!'));
    } catch (_) {
      emit(OnboardingError('Nem sikerült elküldeni a felmérőt.'));
    }
  }

  Future<void> _onLoadMyResponse(
      LoadMyOnboardingResponse event,
      Emitter<OnboardingState> emit) async {
    emit(OnboardingLoading());
    try {
      final response = await _repo.getMyResponse();
      if (response != null) {
        emit(OnboardingSingleResponseLoaded(response));
      } else {
        emit(OnboardingError('Még nem töltötted ki a felmérőt.'));
      }
    } catch (_) {
      emit(OnboardingError('Nem sikerült betölteni a választ.'));
    }
  }
}
