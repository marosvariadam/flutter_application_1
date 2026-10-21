import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/features/athlete_profile/data/models/athlete_profile_model.dart';
import 'package:flutter_application_1/features/athlete_profile/data/repositories/athlete_profile_repository.dart';

// States
abstract class AthleteProfileState {
  const AthleteProfileState();
}

class AthleteProfileInitial extends AthleteProfileState {
  const AthleteProfileInitial();
}

class AthleteProfileLoading extends AthleteProfileState {
  const AthleteProfileLoading();
}

/// Backend returned 404 — the athlete hasn't filled in the survey. The UI
/// renders a "set up profile" CTA in this case.
class AthleteProfileMissing extends AthleteProfileState {
  const AthleteProfileMissing();
}

class AthleteProfileLoaded extends AthleteProfileState {
  final AthleteProfileModel profile;
  const AthleteProfileLoaded(this.profile);
}

class AthleteProfileSaving extends AthleteProfileState {
  final AthleteProfileModel pending;
  const AthleteProfileSaving(this.pending);
}

class AthleteProfileForbidden extends AthleteProfileState {
  const AthleteProfileForbidden();
}

class AthleteProfileError extends AthleteProfileState {
  final String message;
  const AthleteProfileError(this.message);
}

/// Thin cubit over the profile endpoints. Trainer vs. athlete is selected per
/// call so one instance can be reused when swapping between contexts (e.g.
/// after switching athletes in the detail page).
class AthleteProfileCubit extends Cubit<AthleteProfileState> {
  final AthleteProfileRepository _repo;

  AthleteProfileCubit(this._repo) : super(const AthleteProfileInitial());

  Future<void> loadMine() async {
    emit(const AthleteProfileLoading());
    try {
      final p = await _repo.getMine();
      emit(p == null
          ? const AthleteProfileMissing()
          : AthleteProfileLoaded(p));
    } on AthleteProfileUnauthorizedException {
      // The caller will usually be behind the auth gate, so we treat this as
      // "no profile yet" to keep the UX quiet.
      emit(const AthleteProfileMissing());
    } catch (_) {
      emit(const AthleteProfileError('Nem sikerült betölteni a profilt.'));
    }
  }

  Future<void> loadForAthlete(String athleteId) async {
    emit(const AthleteProfileLoading());
    try {
      final p = await _repo.getForAthlete(athleteId);
      emit(p == null
          ? const AthleteProfileMissing()
          : AthleteProfileLoaded(p));
    } on AthleteProfileForbiddenException {
      emit(const AthleteProfileForbidden());
    } catch (_) {
      emit(const AthleteProfileError('Nem sikerült betölteni a profilt.'));
    }
  }

  Future<void> saveMine(AthleteProfileModel profile) async {
    emit(AthleteProfileSaving(profile));
    try {
      final saved = await _repo.upsertMine(profile);
      emit(AthleteProfileLoaded(saved));
    } on AthleteProfileUnauthorizedException {
      emit(const AthleteProfileError(
          'A profil mentéséhez jelentkezz be újra.'));
    } catch (_) {
      emit(const AthleteProfileError('Nem sikerült menteni a profilt.'));
    }
  }

  Future<void> saveForAthlete(
      String athleteId, AthleteProfileModel profile) async {
    emit(AthleteProfileSaving(profile));
    try {
      final saved = await _repo.upsertForAthlete(athleteId, profile);
      emit(AthleteProfileLoaded(saved));
    } on AthleteProfileForbiddenException {
      emit(const AthleteProfileForbidden());
    } catch (_) {
      emit(const AthleteProfileError('Nem sikerült menteni a profilt.'));
    }
  }
}
