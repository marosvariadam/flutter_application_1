import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/features/trainer/data/models/trainer_request_model.dart';
import 'package:flutter_application_1/features/trainer/data/repositories/trainer_request_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class TrainerRequestEvent {}

class LoadPendingRequests extends TrainerRequestEvent {}

class LoadMyRequests extends TrainerRequestEvent {}

class AcceptRequest extends TrainerRequestEvent {
  final String requestId;
  AcceptRequest(this.requestId);
}

class RejectRequest extends TrainerRequestEvent {
  final String requestId;
  RejectRequest(this.requestId);
}

class SendTrainerRequest extends TrainerRequestEvent {
  final String trainerEmail;
  final String? note;
  SendTrainerRequest(this.trainerEmail, {this.note});
}

// ── States ────────────────────────────────────────────────────────────────────
abstract class TrainerRequestState {}

class TrainerRequestInitial extends TrainerRequestState {}

class TrainerRequestLoading extends TrainerRequestState {}

class TrainerRequestsLoaded extends TrainerRequestState {
  final List<TrainerRequestModel> requests;
  TrainerRequestsLoaded(this.requests);
}

class TrainerRequestError extends TrainerRequestState {
  final String message;
  TrainerRequestError(this.message);
}

class TrainerRequestSuccess extends TrainerRequestState {
  final String message;
  TrainerRequestSuccess(this.message);
}

// ── BLoC ──────────────────────────────────────────────────────────────────────
class TrainerRequestBloc
    extends Bloc<TrainerRequestEvent, TrainerRequestState> {
  final TrainerRequestRepository _repo;
  List<TrainerRequestModel> _requests = [];

  TrainerRequestBloc(this._repo) : super(TrainerRequestInitial()) {
    on<LoadPendingRequests>(_onLoadPending);
    on<LoadMyRequests>(_onLoadMine);
    on<AcceptRequest>(_onAccept);
    on<RejectRequest>(_onReject);
    on<SendTrainerRequest>(_onSend);
  }

  Future<void> _onLoadPending(
      LoadPendingRequests event, Emitter<TrainerRequestState> emit) async {
    emit(TrainerRequestLoading());
    try {
      _requests = await _repo.getPendingRequests();
      emit(TrainerRequestsLoaded(_requests));
    } catch (_) {
      emit(TrainerRequestError('Nem sikerült betölteni a kéréseket.'));
    }
  }

  Future<void> _onLoadMine(
      LoadMyRequests event, Emitter<TrainerRequestState> emit) async {
    emit(TrainerRequestLoading());
    try {
      _requests = await _repo.getMyRequests();
      emit(TrainerRequestsLoaded(_requests));
    } catch (_) {
      emit(TrainerRequestError('Nem sikerült betölteni a kéréseket.'));
    }
  }

  Future<void> _onAccept(
      AcceptRequest event, Emitter<TrainerRequestState> emit) async {
    try {
      await _repo.acceptRequest(event.requestId);
      _requests =
          _requests.where((r) => r.id != event.requestId).toList();
      emit(TrainerRequestsLoaded(_requests));
    } catch (_) {
      emit(TrainerRequestError('Nem sikerült elfogadni a kérést.'));
    }
  }

  Future<void> _onReject(
      RejectRequest event, Emitter<TrainerRequestState> emit) async {
    try {
      await _repo.rejectRequest(event.requestId);
      _requests =
          _requests.where((r) => r.id != event.requestId).toList();
      emit(TrainerRequestsLoaded(_requests));
    } catch (_) {
      emit(TrainerRequestError('Nem sikerült elutasítani a kérést.'));
    }
  }

  Future<void> _onSend(
      SendTrainerRequest event, Emitter<TrainerRequestState> emit) async {
    emit(TrainerRequestLoading());
    try {
      await _repo.sendRequest(event.trainerEmail, note: event.note);
      emit(TrainerRequestSuccess('A csatlakozási kérés sikeresen elküldve.'));
    } catch (_) {
      emit(TrainerRequestError(
          'Nem sikerült elküldeni a kérést. Ellenőrizd az edzői email címet.'));
    }
  }
}
