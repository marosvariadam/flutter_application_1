import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/features/training_block/data/models/training_block_model.dart';
import 'package:flutter_application_1/features/training_block/data/repositories/training_block_repository.dart';

// Events
abstract class TrainingBlockEvent {}

class LoadTrainingBlocks extends TrainingBlockEvent {
  final String athleteId;
  LoadTrainingBlocks(this.athleteId);
}

class CreateTrainingBlock extends TrainingBlockEvent {
  final String athleteId;
  final String focus;
  final DateTime startDate;
  final DateTime endDate;
  final String? notes;
  CreateTrainingBlock({
    required this.athleteId,
    required this.focus,
    required this.startDate,
    required this.endDate,
    this.notes,
  });
}

class UpdateTrainingBlock extends TrainingBlockEvent {
  final String id;
  final String athleteId; // for reloading the list after update
  final String focus;
  final DateTime startDate;
  final DateTime endDate;
  final String? notes;
  UpdateTrainingBlock({
    required this.id,
    required this.athleteId,
    required this.focus,
    required this.startDate,
    required this.endDate,
    this.notes,
  });
}

class DeleteTrainingBlock extends TrainingBlockEvent {
  final String id;
  final String athleteId; // for reloading the list after delete
  DeleteTrainingBlock({required this.id, required this.athleteId});
}

// States
abstract class TrainingBlockState {
  const TrainingBlockState();
}

class TrainingBlockInitial extends TrainingBlockState {
  const TrainingBlockInitial();
}

class TrainingBlockLoading extends TrainingBlockState {
  const TrainingBlockLoading();
}

class TrainingBlocksLoaded extends TrainingBlockState {
  final String athleteId;
  final List<TrainingBlockModel> blocks;
  const TrainingBlocksLoaded(this.athleteId, this.blocks);
}

class TrainingBlockForbidden extends TrainingBlockState {
  const TrainingBlockForbidden();
}

class TrainingBlockError extends TrainingBlockState {
  final String message;
  const TrainingBlockError(this.message);
}

/// Emitted transiently after a mutation reports an overlap (409). The list
/// state that preceded this is re-emitted right after so the screen shows the
/// snackbar without losing the form/data.
class TrainingBlockOverlap extends TrainingBlockState {
  final String message;
  const TrainingBlockOverlap(this.message);
}

/// Emitted transiently after a mutation reports a validation error (400). Same
/// re-emit pattern as overlap.
class TrainingBlockValidation extends TrainingBlockState {
  final String message;
  const TrainingBlockValidation(this.message);
}

// BLoC
class TrainingBlockBloc
    extends Bloc<TrainingBlockEvent, TrainingBlockState> {
  final TrainingBlockRepository _repo;
  // Cache last successful list so we can re-emit it after a transient error.
  List<TrainingBlockModel> _last = const [];
  String? _lastAthleteId;

  TrainingBlockBloc(this._repo) : super(const TrainingBlockInitial()) {
    on<LoadTrainingBlocks>(_onLoad);
    on<CreateTrainingBlock>(_onCreate);
    on<UpdateTrainingBlock>(_onUpdate);
    on<DeleteTrainingBlock>(_onDelete);
  }

  Future<void> _onLoad(
      LoadTrainingBlocks event, Emitter<TrainingBlockState> emit) async {
    emit(const TrainingBlockLoading());
    try {
      final list = await _repo.getForAthlete(event.athleteId);
      _last = list;
      _lastAthleteId = event.athleteId;
      emit(TrainingBlocksLoaded(event.athleteId, list));
    } on TrainingBlockForbiddenException {
      emit(const TrainingBlockForbidden());
    } catch (_) {
      emit(const TrainingBlockError(
          'Nem sikerült betölteni a tréningblokkokat.'));
    }
  }

  Future<void> _onCreate(
      CreateTrainingBlock event, Emitter<TrainingBlockState> emit) async {
    try {
      await _repo.create(
        athleteId: event.athleteId,
        focus: event.focus,
        startDate: event.startDate,
        endDate: event.endDate,
        notes: event.notes,
      );
      add(LoadTrainingBlocks(event.athleteId));
    } on TrainingBlockOverlapException catch (e) {
      emit(TrainingBlockOverlap(e.message));
      // Re-emit list so the form/screen returns to a sensible state.
      _reemitLast(emit);
    } on TrainingBlockValidationException catch (e) {
      emit(TrainingBlockValidation(e.message));
      _reemitLast(emit);
    } on TrainingBlockForbiddenException {
      emit(const TrainingBlockForbidden());
    } catch (_) {
      emit(const TrainingBlockError(
          'Nem sikerült létrehozni a tréningblokkot.'));
      _reemitLast(emit);
    }
  }

  Future<void> _onUpdate(
      UpdateTrainingBlock event, Emitter<TrainingBlockState> emit) async {
    try {
      await _repo.update(
        event.id,
        focus: event.focus,
        startDate: event.startDate,
        endDate: event.endDate,
        notes: event.notes,
      );
      add(LoadTrainingBlocks(event.athleteId));
    } on TrainingBlockOverlapException catch (e) {
      emit(TrainingBlockOverlap(e.message));
      _reemitLast(emit);
    } on TrainingBlockValidationException catch (e) {
      emit(TrainingBlockValidation(e.message));
      _reemitLast(emit);
    } on TrainingBlockForbiddenException {
      emit(const TrainingBlockForbidden());
    } catch (_) {
      emit(const TrainingBlockError(
          'Nem sikerült frissíteni a tréningblokkot.'));
      _reemitLast(emit);
    }
  }

  Future<void> _onDelete(
      DeleteTrainingBlock event, Emitter<TrainingBlockState> emit) async {
    try {
      await _repo.delete(event.id);
      add(LoadTrainingBlocks(event.athleteId));
    } on TrainingBlockForbiddenException {
      emit(const TrainingBlockForbidden());
    } catch (_) {
      emit(const TrainingBlockError(
          'Nem sikerült törölni a tréningblokkot.'));
      _reemitLast(emit);
    }
  }

  void _reemitLast(Emitter<TrainingBlockState> emit) {
    if (_lastAthleteId != null) {
      emit(TrainingBlocksLoaded(_lastAthleteId!, _last));
    }
  }
}
