import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/features/exercise/data/models/exercise_model.dart';
import 'package:flutter_application_1/features/exercise/data/repositories/exercise_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class ExerciseEvent {}

class LoadExercises extends ExerciseEvent {
  final String? search;
  final String? muscleGroup;
  final int page;
  LoadExercises({this.search, this.muscleGroup, this.page = 1});
}

class LoadMoreExercises extends ExerciseEvent {}

class SearchExercises extends ExerciseEvent {
  final String query;
  final String? muscleGroup;
  SearchExercises(this.query, {this.muscleGroup});
}

class DeleteExercise extends ExerciseEvent {
  final String id;
  DeleteExercise(this.id);
}

// ── States ────────────────────────────────────────────────────────────────────
abstract class ExerciseState {}

class ExerciseInitial extends ExerciseState {}

class ExerciseLoading extends ExerciseState {}

class ExercisesLoaded extends ExerciseState {
  final List<ExerciseModel> exercises;
  final bool hasMore;
  ExercisesLoaded(this.exercises, {required this.hasMore});
}

class ExerciseError extends ExerciseState {
  final String message;
  ExerciseError(this.message);
}

// ── BLoC ──────────────────────────────────────────────────────────────────────
class ExerciseBloc extends Bloc<ExerciseEvent, ExerciseState> {
  final ExerciseRepository _repo;
  List<ExerciseModel> _exercises = [];
  int _page = 1;
  bool _hasMore = false;
  String? _lastSearch;
  String? _lastMuscleGroup;

  ExerciseBloc(this._repo) : super(ExerciseInitial()) {
    on<LoadExercises>(_onLoad);
    on<LoadMoreExercises>(_onLoadMore);
    on<SearchExercises>(_onSearch);
    on<DeleteExercise>(_onDelete);
  }

  Future<void> _onLoad(
      LoadExercises event, Emitter<ExerciseState> emit) async {
    emit(ExerciseLoading());
    _lastSearch = event.search;
    _lastMuscleGroup = event.muscleGroup;
    try {
      final result = await _repo.getExercises(
        search: event.search,
        muscleGroup: event.muscleGroup,
        page: event.page,
      );
      _exercises = result.items;
      _page = event.page;
      _hasMore = result.hasMore;
      emit(ExercisesLoaded(_exercises, hasMore: _hasMore));
    } catch (_) {
      emit(ExerciseError('Nem sikerült betölteni a gyakorlatokat.'));
    }
  }

  Future<void> _onLoadMore(
      LoadMoreExercises event, Emitter<ExerciseState> emit) async {
    if (!_hasMore) return;
    try {
      final result = await _repo.getExercises(
        search: _lastSearch,
        muscleGroup: _lastMuscleGroup,
        page: _page + 1,
      );
      _page++;
      _exercises = [..._exercises, ...result.items];
      _hasMore = result.hasMore;
      emit(ExercisesLoaded(_exercises, hasMore: _hasMore));
    } catch (_) {}
  }

  Future<void> _onSearch(
      SearchExercises event, Emitter<ExerciseState> emit) async {
    emit(ExerciseLoading());
    _lastSearch = event.query;
    _lastMuscleGroup = event.muscleGroup;
    try {
      final result = await _repo.getExercises(
        search: event.query,
        muscleGroup: event.muscleGroup,
        page: 1,
      );
      _exercises = result.items;
      _page = 1;
      _hasMore = result.hasMore;
      emit(ExercisesLoaded(_exercises, hasMore: _hasMore));
    } catch (_) {
      emit(ExerciseError('Nem sikerült keresni.'));
    }
  }

  Future<void> _onDelete(
      DeleteExercise event, Emitter<ExerciseState> emit) async {
    try {
      await _repo.deleteExercise(event.id);
      _exercises = _exercises.where((e) => e.id != event.id).toList();
      emit(ExercisesLoaded(_exercises, hasMore: _hasMore));
    } catch (_) {
      emit(ExerciseError('Nem sikerült törölni a gyakorlatot.'));
    }
  }
}
