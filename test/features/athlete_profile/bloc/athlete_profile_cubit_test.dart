import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_application_1/features/athlete_profile/bloc/athlete_profile_cubit.dart';
import 'package:flutter_application_1/features/athlete_profile/data/models/athlete_profile_model.dart';
import 'package:flutter_application_1/features/athlete_profile/data/repositories/athlete_profile_repository.dart';

class _MockRepo extends Mock implements AthleteProfileRepository {}

AthleteProfileModel _profile({
  String goal = AthleteProfileGoals.hypertrophy,
  String experience = AthleteProfileExperienceLevels.intermediate,
}) =>
    AthleteProfileModel(
      athleteId: 'a1',
      goal: goal,
      experienceLevel: experience,
      daysPerWeek: 4,
      sessionMinutes: 60,
      availableEquipment: const [AthleteProfileEquipment.barbell],
      avoidStressTags: const [AthleteProfileStressTags.knee],
    );

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    registerFallbackValue(_profile());
  });

  group('AthleteProfileCubit.loadMine', () {
    blocTest<AthleteProfileCubit, AthleteProfileState>(
      'emits Loaded when the repo returns a profile',
      build: () {
        when(() => repo.getMine()).thenAnswer((_) async => _profile());
        return AthleteProfileCubit(repo);
      },
      act: (c) => c.loadMine(),
      expect: () => [
        isA<AthleteProfileLoading>(),
        isA<AthleteProfileLoaded>()
            .having((s) => s.profile.goal, 'goal',
                AthleteProfileGoals.hypertrophy),
      ],
    );

    blocTest<AthleteProfileCubit, AthleteProfileState>(
      'emits Missing when the repo returns null (404)',
      build: () {
        when(() => repo.getMine()).thenAnswer((_) async => null);
        return AthleteProfileCubit(repo);
      },
      act: (c) => c.loadMine(),
      expect: () => [
        isA<AthleteProfileLoading>(),
        isA<AthleteProfileMissing>(),
      ],
    );

    blocTest<AthleteProfileCubit, AthleteProfileState>(
      'treats unauthorized as Missing so the gate stays quiet',
      build: () {
        when(() => repo.getMine())
            .thenThrow(const AthleteProfileUnauthorizedException());
        return AthleteProfileCubit(repo);
      },
      act: (c) => c.loadMine(),
      expect: () => [
        isA<AthleteProfileLoading>(),
        isA<AthleteProfileMissing>(),
      ],
    );

    blocTest<AthleteProfileCubit, AthleteProfileState>(
      'emits Error on an unexpected failure',
      build: () {
        when(() => repo.getMine()).thenThrow(Exception('boom'));
        return AthleteProfileCubit(repo);
      },
      act: (c) => c.loadMine(),
      expect: () => [
        isA<AthleteProfileLoading>(),
        isA<AthleteProfileError>(),
      ],
    );
  });

  group('AthleteProfileCubit.loadForAthlete', () {
    blocTest<AthleteProfileCubit, AthleteProfileState>(
      'emits Forbidden on 403',
      build: () {
        when(() => repo.getForAthlete('a1'))
            .thenThrow(const AthleteProfileForbiddenException());
        return AthleteProfileCubit(repo);
      },
      act: (c) => c.loadForAthlete('a1'),
      expect: () => [
        isA<AthleteProfileLoading>(),
        isA<AthleteProfileForbidden>(),
      ],
    );
  });

  group('AthleteProfileCubit.saveMine', () {
    blocTest<AthleteProfileCubit, AthleteProfileState>(
      'emits Saving then Loaded with the server response',
      build: () {
        when(() => repo.upsertMine(any())).thenAnswer(
            (_) async => _profile(experience: AthleteProfileExperienceLevels.advanced));
        return AthleteProfileCubit(repo);
      },
      act: (c) => c.saveMine(_profile()),
      expect: () => [
        isA<AthleteProfileSaving>(),
        isA<AthleteProfileLoaded>().having(
          (s) => s.profile.experienceLevel,
          'experienceLevel',
          AthleteProfileExperienceLevels.advanced,
        ),
      ],
    );

    blocTest<AthleteProfileCubit, AthleteProfileState>(
      'emits SaveFailed when the server rejects the save',
      build: () {
        when(() => repo.upsertMine(any())).thenThrow(Exception('boom'));
        return AthleteProfileCubit(repo);
      },
      act: (c) => c.saveMine(_profile()),
      expect: () => [
        isA<AthleteProfileSaving>(),
        isA<AthleteProfileSaveFailed>()
            .having((s) => s.profile, 'profile', isNull)
            .having((s) => s.message, 'message',
                'Nem sikerült menteni a profilt.'),
      ],
    );
  });
}
