import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_application_1/features/athlete_profile/bloc/athlete_profile_cubit.dart';
import 'package:flutter_application_1/features/athlete_profile/data/models/athlete_profile_model.dart';
import 'package:flutter_application_1/features/athlete_profile/data/repositories/athlete_profile_repository.dart';

class _MockRepo extends Mock implements AthleteProfileRepository {}

AthleteProfileModel _profile({int days = 4}) => AthleteProfileModel(
      athleteId: 'a1',
      goal: AthleteProfileGoals.strength,
      experienceLevel: AthleteProfileExperienceLevels.intermediate,
      daysPerWeek: days,
      sessionMinutes: 60,
    );

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    registerFallbackValue(_profile());
  });

  group('loadForAthlete', () {
    blocTest<AthleteProfileCubit, AthleteProfileState>(
      'emits Loaded for an existing profile',
      setUp: () =>
          when(() => repo.getForAthlete('a1')).thenAnswer((_) async => _profile()),
      build: () => AthleteProfileCubit(repo),
      act: (c) => c.loadForAthlete('a1'),
      expect: () => [
        isA<AthleteProfileLoading>(),
        isA<AthleteProfileLoaded>(),
      ],
    );

    blocTest<AthleteProfileCubit, AthleteProfileState>(
      'emits Missing when the athlete has none',
      setUp: () =>
          when(() => repo.getForAthlete('a1')).thenAnswer((_) async => null),
      build: () => AthleteProfileCubit(repo),
      act: (c) => c.loadForAthlete('a1'),
      expect: () => [isA<AthleteProfileLoading>(), isA<AthleteProfileMissing>()],
    );

    blocTest<AthleteProfileCubit, AthleteProfileState>(
      'a timeout becomes a Hungarian error',
      setUp: () => when(() => repo.getForAthlete('a1')).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.receiveTimeout)),
      build: () => AthleteProfileCubit(repo),
      act: (c) => c.loadForAthlete('a1'),
      expect: () => [
        isA<AthleteProfileLoading>(),
        isA<AthleteProfileError>().having((s) => s.message, 'message',
            'A szerver nem válaszolt időben. Próbáld újra.'),
      ],
    );
  });

  group('saveForAthlete', () {
    blocTest<AthleteProfileCubit, AthleteProfileState>(
      'emits the stored profile on success',
      setUp: () => when(() => repo.upsertForAthlete('a1', any()))
          .thenAnswer((_) async => _profile(days: 5)),
      build: () => AthleteProfileCubit(repo),
      act: (c) => c.saveForAthlete('a1', _profile(days: 5)),
      expect: () => [
        isA<AthleteProfileSaving>()
            .having((s) => s.pending.daysPerWeek, 'pending', 5),
        isA<AthleteProfileLoaded>()
            .having((s) => s.profile.daysPerWeek, 'days', 5),
      ],
    );

    blocTest<AthleteProfileCubit, AthleteProfileState>(
      'a failed save keeps showing the last stored profile',
      setUp: () {
        when(() => repo.getForAthlete('a1')).thenAnswer((_) async => _profile());
        when(() => repo.upsertForAthlete('a1', any()))
            .thenThrow(Exception('boom'));
      },
      build: () => AthleteProfileCubit(repo),
      act: (c) async {
        await c.loadForAthlete('a1');
        await c.saveForAthlete('a1', _profile(days: 6));
      },
      skip: 2,
      expect: () => [
        isA<AthleteProfileSaving>(),
        isA<AthleteProfileSaveFailed>()
            .having((s) => s.profile?.daysPerWeek, 'stored days', 4)
            .having((s) => s.visibleProfile?.daysPerWeek, 'visible', 4)
            .having((s) => s.message, 'message',
                'Nem sikerült menteni a profilt.'),
      ],
    );

    blocTest<AthleteProfileCubit, AthleteProfileState>(
      'forbidden save emits Forbidden',
      setUp: () => when(() => repo.upsertForAthlete('a1', any()))
          .thenThrow(const AthleteProfileForbiddenException()),
      build: () => AthleteProfileCubit(repo),
      act: (c) => c.saveForAthlete('a1', _profile()),
      expect: () =>
          [isA<AthleteProfileSaving>(), isA<AthleteProfileForbidden>()],
    );
  });

  blocTest<AthleteProfileCubit, AthleteProfileState>(
    'saveMine asks to sign in again when the session expired',
    setUp: () => when(() => repo.upsertMine(any()))
        .thenThrow(const AthleteProfileUnauthorizedException()),
    build: () => AthleteProfileCubit(repo),
    act: (c) => c.saveMine(_profile()),
    expect: () => [
      isA<AthleteProfileSaving>(),
      isA<AthleteProfileSaveFailed>().having((s) => s.message, 'message',
          'A profil mentéséhez jelentkezz be újra.'),
    ],
  );

  test('visibleProfile is null for states without a profile', () {
    expect(const AthleteProfileInitial().visibleProfile, isNull);
    expect(const AthleteProfileLoading().visibleProfile, isNull);
    expect(const AthleteProfileMissing().visibleProfile, isNull);
    expect(const AthleteProfileForbidden().visibleProfile, isNull);
    expect(const AthleteProfileError('x').visibleProfile, isNull);
    expect(AthleteProfileSaving(_profile(days: 3)).visibleProfile?.daysPerWeek,
        3);
  });
}
