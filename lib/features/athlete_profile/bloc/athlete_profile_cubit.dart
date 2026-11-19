import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/core/api/api_error_messages.dart';
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

/// A save was rejected. [profile] is the last stored version (null if none
/// was ever loaded), so the UI keeps showing it while reporting [message].
class AthleteProfileSaveFailed extends AthleteProfileState {
  final AthleteProfileModel? profile;
  final String message;
  const AthleteProfileSaveFailed(this.profile, this.message);
}

extension AthleteProfileStateX on AthleteProfileState {
  /// The profile the UI should display in this state, if any.
  AthleteProfileModel? get visibleProfile {
    final s = this;
    if (s is AthleteProfileLoaded) return s.profile;
    if (s is AthleteProfileSaving) return s.pending;
    if (s is AthleteProfileSaveFailed) return s.profile;
    return null;
  }
}

/// Thin cubit over the profile endpoints. Trainer vs. athlete is selected per
/// call so one instance can be reused when swapping between contexts (e.g.
/// after switching athletes in the detail page).
class AthleteProfileCubit extends Cubit<AthleteProfileState> {
  final AthleteProfileRepository _repo;

  /// Last profile the server confirmed; shown again after a failed save.
  AthleteProfileModel? _lastStored;

  AthleteProfileCubit(this._repo) : super(const AthleteProfileInitial());

  void _emitStored(AthleteProfileModel? profile) {
    _lastStored = profile;
    emit(profile == null
        ? const AthleteProfileMissing()
        : AthleteProfileLoaded(profile));
  }

  Future<void> loadMine() async {
    emit(const AthleteProfileLoading());
    try {
      _emitStored(await _repo.getMine());
    } on AthleteProfileUnauthorizedException {
      // The caller will usually be behind the auth gate, so we treat this as
      // "no profile yet" to keep the UX quiet.
      emit(const AthleteProfileMissing());
    } catch (e) {
      emit(AthleteProfileError(friendlyErrorMessage(e,
          fallback: 'Nem sikerült betölteni a profilt.')));
    }
  }

  Future<void> loadForAthlete(String athleteId) async {
    emit(const AthleteProfileLoading());
    try {
      _emitStored(await _repo.getForAthlete(athleteId));
    } on AthleteProfileForbiddenException {
      emit(const AthleteProfileForbidden());
    } catch (e) {
      emit(AthleteProfileError(friendlyErrorMessage(e,
          fallback: 'Nem sikerült betölteni a profilt.')));
    }
  }

  Future<void> saveMine(AthleteProfileModel profile) async {
    emit(AthleteProfileSaving(profile));
    try {
      _emitStored(await _repo.upsertMine(profile));
    } on AthleteProfileUnauthorizedException {
      emit(AthleteProfileSaveFailed(
          _lastStored, 'A profil mentéséhez jelentkezz be újra.'));
    } catch (e) {
      emit(AthleteProfileSaveFailed(
          _lastStored,
          friendlyErrorMessage(e,
              fallback: 'Nem sikerült menteni a profilt.')));
    }
  }

  Future<void> saveForAthlete(
      String athleteId, AthleteProfileModel profile) async {
    emit(AthleteProfileSaving(profile));
    try {
      _emitStored(await _repo.upsertForAthlete(athleteId, profile));
    } on AthleteProfileForbiddenException {
      emit(const AthleteProfileForbidden());
    } catch (e) {
      emit(AthleteProfileSaveFailed(
          _lastStored,
          friendlyErrorMessage(e,
              fallback: 'Nem sikerült menteni a profilt.')));
    }
  }
}
