import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';
import 'package:flutter_application_1/features/workout/data/repositories/workout_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class WorkoutEvent {}

// List events
class LoadMyWorkouts extends WorkoutEvent {
  final int page;
  LoadMyWorkouts({this.page = 1});
}

class LoadMoreWorkouts extends WorkoutEvent {}

class LoadTrainerWorkouts extends WorkoutEvent {
  final int page;
  LoadTrainerWorkouts({this.page = 1});
}

class LoadMoreTrainerWorkouts extends WorkoutEvent {}

// Detail events
class LoadWorkoutDetail extends WorkoutEvent {
  final String workoutId;
  LoadWorkoutDetail(this.workoutId);
}

class StartWorkout extends WorkoutEvent {
  final String workoutId;
  StartWorkout(this.workoutId);
}

class LogExercise extends WorkoutEvent {
  final String workoutId;
  final int index;
  final int? actualSets;
  final int? actualReps;
  final double? actualWeightKg;
  final String? exerciseNotes;
  LogExercise({
    required this.workoutId,
    required this.index,
    this.actualSets,
    this.actualReps,
    this.actualWeightKg,
    this.exerciseNotes,
  });
}

class CompleteWorkout extends WorkoutEvent {
  final String workoutId;
  final String? feedback;
  CompleteWorkout(this.workoutId, {this.feedback});
}

class DeleteWorkout extends WorkoutEvent {
  final String workoutId;
  DeleteWorkout(this.workoutId);
}

// ── States ────────────────────────────────────────────────────────────────────
abstract class WorkoutState {}

class WorkoutInitial extends WorkoutState {}

class WorkoutLoading extends WorkoutState {}

class WorkoutsLoaded extends WorkoutState {
  final List<WorkoutModel> workouts;
  final bool hasMore;
  final int currentPage;
  WorkoutsLoaded(this.workouts,
      {required this.hasMore, required this.currentPage});
}

class WorkoutDetailLoaded extends WorkoutState {
  final WorkoutModel workout;
  WorkoutDetailLoaded(this.workout);
}

class WorkoutActionSuccess extends WorkoutState {
  final String message;
  final WorkoutModel? workout;
  WorkoutActionSuccess(this.message, {this.workout});
}

class WorkoutError extends WorkoutState {
  final String message;
  WorkoutError(this.message);
}

// ── BLoC ──────────────────────────────────────────────────────────────────────
class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  final WorkoutRepository _repo;
  List<WorkoutModel> _workouts = [];
  int _page = 1;
  bool _hasMore = false;

  WorkoutBloc(this._repo) : super(WorkoutInitial()) {
    on<LoadMyWorkouts>(_onLoadMine);
    on<LoadMoreWorkouts>(_onLoadMore);
    on<LoadTrainerWorkouts>(_onLoadTrainer);
    on<LoadMoreTrainerWorkouts>(_onLoadMoreTrainer);
    on<LoadWorkoutDetail>(_onLoadDetail);
    on<StartWorkout>(_onStart);
    on<LogExercise>(_onLogExercise);
    on<CompleteWorkout>(_onComplete);
    on<DeleteWorkout>(_onDelete);
  }

  Future<void> _onLoadMine(
      LoadMyWorkouts event, Emitter<WorkoutState> emit) async {
    emit(WorkoutLoading());
    try {
      final result = await _repo.getMyWorkouts(page: event.page);
      _workouts = result.items;
      _page = event.page;
      _hasMore = result.hasMore;
      emit(WorkoutsLoaded(_workouts,
          hasMore: _hasMore, currentPage: _page));
    } catch (_) {
      emit(WorkoutError('Nem sikerült betölteni az edzéseket.'));
    }
  }

  Future<void> _onLoadMore(
      LoadMoreWorkouts event, Emitter<WorkoutState> emit) async {
    if (!_hasMore) return;
    try {
      final result = await _repo.getMyWorkouts(page: _page + 1);
      _page++;
      _workouts = [..._workouts, ...result.items];
      _hasMore = result.hasMore;
      emit(WorkoutsLoaded(_workouts,
          hasMore: _hasMore, currentPage: _page));
    } catch (_) {
      emit(WorkoutError('Nem sikerült betölteni a további edzéseket.'));
    }
  }

  Future<void> _onLoadTrainer(
      LoadTrainerWorkouts event, Emitter<WorkoutState> emit) async {
    emit(WorkoutLoading());
    try {
      final result = await _repo.getTrainerCreated(page: event.page);
      _workouts = result.items;
      _page = event.page;
      _hasMore = result.hasMore;
      emit(WorkoutsLoaded(_workouts,
          hasMore: _hasMore, currentPage: _page));
    } catch (_) {
      emit(WorkoutError('Nem sikerült betölteni az edzéseket.'));
    }
  }

  Future<void> _onLoadMoreTrainer(
      LoadMoreTrainerWorkouts event, Emitter<WorkoutState> emit) async {
    if (!_hasMore) return;
    try {
      final result = await _repo.getTrainerCreated(page: _page + 1);
      _page++;
      _workouts = [..._workouts, ...result.items];
      _hasMore = result.hasMore;
      emit(WorkoutsLoaded(_workouts,
          hasMore: _hasMore, currentPage: _page));
    } catch (_) {
      emit(WorkoutError('Nem sikerült betölteni a további edzéseket.'));
    }
  }

  Future<void> _onLoadDetail(
      LoadWorkoutDetail event, Emitter<WorkoutState> emit) async {
    emit(WorkoutLoading());
    try {
      final workout = await _repo.getWorkout(event.workoutId);
      emit(WorkoutDetailLoaded(workout));
    } catch (_) {
      emit(WorkoutError('Nem sikerült betölteni az edzést.'));
    }
  }

  Future<void> _onStart(
      StartWorkout event, Emitter<WorkoutState> emit) async {
    try {
      final workout = await _repo.startWorkout(event.workoutId);
      emit(WorkoutDetailLoaded(workout));
    } catch (_) {
      emit(WorkoutError('Nem sikerült elindítani az edzést.'));
    }
  }

  Future<void> _onLogExercise(
      LogExercise event, Emitter<WorkoutState> emit) async {
    try {
      await _repo.logExercise(
        event.workoutId,
        event.index,
        actualSets: event.actualSets,
        actualReps: event.actualReps,
        actualWeightKg: event.actualWeightKg,
        exerciseNotes: event.exerciseNotes,
      );
      // Local UI tracks set state; no state change needed
    } catch (_) {
      emit(WorkoutError('Nem sikerült menteni a gyakorlatot.'));
    }
  }

  Future<void> _onComplete(
      CompleteWorkout event, Emitter<WorkoutState> emit) async {
    try {
      final workout =
          await _repo.completeWorkout(event.workoutId, feedback: event.feedback);
      emit(WorkoutActionSuccess('Edzés befejezve!', workout: workout));
    } catch (_) {
      emit(WorkoutError('Nem sikerült befejezni az edzést.'));
    }
  }

  Future<void> _onDelete(
      DeleteWorkout event, Emitter<WorkoutState> emit) async {
    try {
      await _repo.deleteWorkout(event.workoutId);
      _workouts =
          _workouts.where((w) => w.id != event.workoutId).toList();
      emit(WorkoutsLoaded(_workouts,
          hasMore: _hasMore, currentPage: _page));
    } catch (_) {
      emit(WorkoutError('Nem sikerült törölni az edzést.'));
    }
  }
}
