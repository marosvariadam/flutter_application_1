import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_application_1/features/athlete_profile/data/models/athlete_profile_model.dart';
import 'package:flutter_application_1/features/athlete_profile/data/repositories/athlete_profile_repository.dart';
import 'package:flutter_application_1/features/athlete_profile/presentation/widgets/athlete_profile_card.dart';

class _MockRepo extends Mock implements AthleteProfileRepository {}

const _stored = AthleteProfileModel(
  athleteId: 'a1',
  goal: AthleteProfileGoals.strength,
  experienceLevel: AthleteProfileExperienceLevels.intermediate,
  daysPerWeek: 4,
  sessionMinutes: 75,
  availableEquipment: [AthleteProfileEquipment.barbell],
  avoidStressTags: [AthleteProfileStressTags.knee],
  muscleGroupPriority: {'Legs': 1.2},
  weightKg: 82.5,
);

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    registerFallbackValue(_stored);
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(RepositoryProvider<AthleteProfileRepository>.value(
      value: repo,
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TrainerAthleteProfileCard(athleteId: 'a1'),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the stored profile in Hungarian', (tester) async {
    when(() => repo.getForAthlete('a1')).thenAnswer((_) async => _stored);
    await pump(tester);

    expect(find.text('Erőnlét'), findsOneWidget);
    expect(find.text('Haladó'), findsOneWidget);
    expect(find.text('4x · 75 perc'), findsOneWidget);
    expect(find.text('82.5 kg'), findsOneWidget);
    expect(find.text('Rúd + tárcsák'), findsOneWidget);
    expect(find.text('Térd'), findsOneWidget);
    expect(find.text('Legs · 1.20×'), findsOneWidget);
    expect(find.text('Szerkesztés'), findsOneWidget);
  });

  testWidgets('forbidden athletes get a clear message', (tester) async {
    when(() => repo.getForAthlete('a1'))
        .thenThrow(const AthleteProfileForbiddenException());
    await pump(tester);
    expect(find.text('Nincs jogosultságod ehhez a profilhoz.'), findsOneWidget);
  });

  testWidgets('a failed load can be retried', (tester) async {
    when(() => repo.getForAthlete('a1')).thenThrow(Exception('boom'));
    await pump(tester);
    expect(find.text('Nem sikerült betölteni a profilt.'), findsOneWidget);

    when(() => repo.getForAthlete('a1')).thenAnswer((_) async => _stored);
    await tester.tap(find.text('Újra'));
    await tester.pumpAndSettle();
    expect(find.text('Erőnlét'), findsOneWidget);
  });

  testWidgets('a missing profile can be created from defaults',
      (tester) async {
    when(() => repo.getForAthlete('a1')).thenAnswer((_) async => null);
    when(() => repo.upsertForAthlete('a1', any())).thenAnswer((inv) async =>
        inv.positionalArguments[1] as AthleteProfileModel);
    await pump(tester);

    expect(find.textContaining('még nem töltötte ki'), findsOneWidget);
    await tester.tap(find.text('Felvétel'));
    await tester.pumpAndSettle();
    expect(find.text('Profil szerkesztése'), findsOneWidget);

    await tester.tap(find.text('Mentés'));
    await tester.pumpAndSettle();

    final saved = verify(() => repo.upsertForAthlete('a1', captureAny()))
        .captured
        .single as AthleteProfileModel;
    expect(saved.goal, AthleteProfileGoals.generalFitness);
    expect(saved.experienceLevel, AthleteProfileExperienceLevels.beginner);
    expect(saved.daysPerWeek, 3);
    expect(saved.sessionMinutes, 60);
    // Untouched sliders stay at 1.0 and are not sent.
    expect(saved.muscleGroupPriority, isEmpty);

    expect(find.text('Profil szerkesztése'), findsNothing);
    expect(find.text('Profil mentve.'), findsOneWidget);
    expect(find.text('Általános fitness'), findsOneWidget);
  });

  testWidgets('a priority slider change is saved', (tester) async {
    when(() => repo.getForAthlete('a1')).thenAnswer((_) async => _stored);
    when(() => repo.upsertForAthlete('a1', any())).thenAnswer((inv) async =>
        inv.positionalArguments[1] as AthleteProfileModel);
    await pump(tester);

    await tester.tap(find.text('Szerkesztés'));
    await tester.pumpAndSettle();
    // Sliders: days, minutes, then Chest, Back, Shoulders, Legs, Arms, Core.
    await tester.drag(find.byType(Slider).at(2), const Offset(800, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mentés'));
    await tester.pumpAndSettle();

    final saved = verify(() => repo.upsertForAthlete('a1', captureAny()))
        .captured
        .single as AthleteProfileModel;
    expect(saved.muscleGroupPriority, {'Chest': 1.5, 'Legs': 1.2});
  });

  testWidgets('a failed save keeps the sheet open and the old profile shown',
      (tester) async {
    when(() => repo.getForAthlete('a1')).thenAnswer((_) async => _stored);
    when(() => repo.upsertForAthlete('a1', any())).thenThrow(Exception('boom'));
    await pump(tester);

    await tester.tap(find.text('Szerkesztés'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mentés'));
    await tester.pumpAndSettle();

    expect(find.text('Nem sikerült menteni a profilt.'), findsOneWidget);
    expect(find.text('Profil szerkesztése'), findsOneWidget);

    Navigator.of(tester.element(find.text('Profil szerkesztése'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Erőnlét'), findsOneWidget);
    expect(find.text('Nem sikerült betölteni a profilt.'), findsNothing);
  });
}
