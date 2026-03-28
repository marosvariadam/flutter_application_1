import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/features/trainer/data/models/trainer_request_model.dart';
import 'package:flutter_application_1/features/trainer/data/repositories/roster_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class RosterEvent {}

class LoadRoster extends RosterEvent {
  final int page;
  final int pageSize;
  LoadRoster({this.page = 1, this.pageSize = 20});
}

class LoadMoreRoster extends RosterEvent {}

class DeleteAthlete extends RosterEvent {
  final String athleteId;
  DeleteAthlete(this.athleteId);
}

class ResetAthletePassword extends RosterEvent {
  final String athleteId;
  final String newPassword;
  ResetAthletePassword(this.athleteId, this.newPassword);
}

// ── States ────────────────────────────────────────────────────────────────────
abstract class RosterState {}

class RosterInitial extends RosterState {}

class RosterLoading extends RosterState {}

class RosterLoaded extends RosterState {
  final List<AthleteModel> athletes;
  final bool hasMore;
  final int currentPage;
  RosterLoaded(this.athletes,
      {required this.hasMore, required this.currentPage});
}

class RosterError extends RosterState {
  final String message;
  RosterError(this.message);
}

// ── BLoC ──────────────────────────────────────────────────────────────────────
class RosterBloc extends Bloc<RosterEvent, RosterState> {
  final RosterRepository _repo;
  List<AthleteModel> _athletes = [];
  int _page = 1;
  bool _hasMore = false;

  RosterBloc(this._repo) : super(RosterInitial()) {
    on<LoadRoster>(_onLoad);
    on<LoadMoreRoster>(_onLoadMore);
    on<DeleteAthlete>(_onDelete);
    on<ResetAthletePassword>(_onResetPassword);
  }

  Future<void> _onLoad(LoadRoster event, Emitter<RosterState> emit) async {
    emit(RosterLoading());
    try {
      final result = await _repo.getAthletes(
          page: event.page, pageSize: event.pageSize);
      _athletes = result.items;
      _page = event.page;
      _hasMore = result.hasMore;
      emit(RosterLoaded(_athletes,
          hasMore: _hasMore, currentPage: _page));
    } catch (_) {
      emit(RosterError('Nem sikerült betölteni a sportolókat.'));
    }
  }

  Future<void> _onLoadMore(
      LoadMoreRoster event, Emitter<RosterState> emit) async {
    if (!_hasMore) return;
    try {
      final result = await _repo.getAthletes(page: _page + 1);
      _page++;
      _athletes = [..._athletes, ...result.items];
      _hasMore = result.hasMore;
      emit(RosterLoaded(_athletes,
          hasMore: _hasMore, currentPage: _page));
    } catch (_) {}
  }

  Future<void> _onDelete(
      DeleteAthlete event, Emitter<RosterState> emit) async {
    try {
      await _repo.removeAthlete(event.athleteId);
      _athletes =
          _athletes.where((a) => a.id != event.athleteId).toList();
      emit(RosterLoaded(_athletes,
          hasMore: _hasMore, currentPage: _page));
    } catch (_) {
      emit(RosterError('Nem sikerült eltávolítani a sportolót.'));
    }
  }

  Future<void> _onResetPassword(
      ResetAthletePassword event, Emitter<RosterState> emit) async {
    try {
      await _repo.resetAthletePassword(event.athleteId, event.newPassword);
    } catch (_) {
      emit(RosterError('Nem sikerült visszaállítani a jelszót.'));
    }
  }
}
