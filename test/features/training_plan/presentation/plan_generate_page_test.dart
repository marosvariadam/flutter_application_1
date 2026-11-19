import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_application_1/features/athlete_profile/data/models/athlete_profile_model.dart';
import 'package:flutter_application_1/features/athlete_profile/data/repositories/athlete_profile_repository.dart';
import 'package:flutter_application_1/features/training_block/bloc/training_block_bloc.dart';
import 'package:flutter_application_1/features/training_block/data/models/training_block_model.dart';
import 'package:flutter_application_1/features/training_block/data/repositories/training_block_repository.dart';
import 'package:flutter_application_1/features/training_plan/data/models/plan_results.dart';
import 'package:flutter_application_1/features/training_plan/data/models/training_plan_model.dart';
import 'package:flutter_application_1/features/training_plan/data/repositories/training_plan_repository.dart';
import 'package:flutter_application_1/features/training_plan/presentation/plan_generate_page.dart';

class _MockProfiles extends Mock implements AthleteProfileRepository {}

class _MockPlans extends Mock implements TrainingPlanRepository {}

class _MockBlocks extends Mock implements TrainingBlockRepository {}

const _profile = AthleteProfileModel(
  athleteId: 'a1',
  goal: AthleteProfileGoals.hypertrophy,
  experienceLevel: AthleteProfileExperienceLevels.intermediate,
  daysPerWeek: 4,
  sessionMinutes: 60,
);

final _block = TrainingBlockModel(
  id: 'b1',
  athleteId: 'a1',
  focus: 'Upper',
  startDate: DateTime.utc(2026, 11, 2),
  endDate: DateTime.utc(2026, 11, 29),
);

GenerateResultModel _result() => GenerateResultModel(
      plan: TrainingPlanModel(
        id: 'p1',
        trainerId: 't1',
        athleteId: 'a1',
        title: 'Felső/alsó – 4 hét',
        goal: 'Hypertrophy',
        weeks: 4,
        split: PlanSplits.upperLower,
        status: PlanStatuses.draft,
        days: const [],
        progression: PlanProgressionSchemes.doubleProgression,
        source: PlanGenerationSources.hybrid,
        createdAt: DateTime.utc(2026, 11, 19),
      ),
      predictedScore: 0.7,
      usedPredictor: true,
      warnings: const [],
      errors: const [],
      candidates: const [],
    );

void main() {
  late _MockProfiles profiles;
  late _MockPlans plans;
  late _MockBlocks blocks;

  setUp(() {
    profiles = _MockProfiles();
    plans = _MockPlans();
    blocks = _MockBlocks();
    when(() => profiles.getForAthlete('a1')).thenAnswer((_) async => _profile);
    when(() => blocks.getForAthlete('a1')).thenAnswer((_) async => [_block]);
  });

  void stubGenerate(Future<GenerateResultModel> Function() answer) {
    when(() => plans.generate(
          athleteId: any(named: 'athleteId'),
          mode: any(named: 'mode'),
          weeks: any(named: 'weeks'),
          trainingBlockId: any(named: 'trainingBlockId'),
        )).thenAnswer((_) => answer());
  }

  Future<void> pump(WidgetTester tester, {String athleteId = 'a1'}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AthleteProfileRepository>.value(value: profiles),
        RepositoryProvider<TrainingPlanRepository>.value(value: plans),
      ],
      child: BlocProvider(
        create: (_) => TrainingBlockBloc(blocks),
        child: MaterialApp(home: PlanGeneratePage(athleteId: athleteId)),
      ),
    ));
    await tester.pumpAndSettle();
  }

  // ElevatedButton.icon builds a private subclass, so match by supertype.
  ButtonStyleButton generateButton(WidgetTester tester) =>
      tester.widget<ButtonStyleButton>(find.ancestor(
          of: find.text('Generálás'),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton)));

  testWidgets('without an athlete id it explains where to start from',
      (tester) async {
    await pump(tester, athleteId: '');
    expect(find.text('Nincs kiválasztott sportoló'), findsOneWidget);
    verifyNever(() => profiles.getForAthlete(any()));
  });

  testWidgets('a ready profile enables generation and lists blocks',
      (tester) async {
    await pump(tester);
    expect(find.text('Izomépítés'), findsOneWidget);
    // The dropdown starts on its explicit "Nincs" (no block) item.
    expect(find.text('Nincs'), findsOneWidget);
    expect(generateButton(tester).onPressed, isNotNull);
  });

  testWidgets('a missing profile disables generation with a hint',
      (tester) async {
    when(() => profiles.getForAthlete('a1')).thenAnswer((_) async => null);
    await pump(tester);

    expect(find.textContaining('még nincs profilja'), findsOneWidget);
    expect(find.textContaining('előbb töltsd ki a sportoló profilját'),
        findsOneWidget);
    expect(generateButton(tester).onPressed, isNull);
  });

  testWidgets('a failed profile load can be retried', (tester) async {
    when(() => profiles.getForAthlete('a1')).thenThrow(Exception('boom'));
    await pump(tester);

    expect(find.text('Nem sikerült betölteni a profilt.'), findsOneWidget);
    expect(generateButton(tester).onPressed, isNull);

    when(() => profiles.getForAthlete('a1')).thenAnswer((_) async => _profile);
    await tester.tap(find.text('Újra'));
    await tester.pumpAndSettle();
    expect(find.text('Izomépítés'), findsOneWidget);
    expect(generateButton(tester).onPressed, isNotNull);
  });

  testWidgets('a failed training-block load says so and can be retried',
      (tester) async {
    when(() => blocks.getForAthlete('a1')).thenThrow(Exception('boom'));
    await pump(tester);

    expect(find.text('Nem sikerült betölteni a tréningblokkokat.'),
        findsOneWidget);

    when(() => blocks.getForAthlete('a1')).thenAnswer((_) async => []);
    await tester.tap(find.text('Újra'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nincs tréningblokk ehhez a sportolóhoz.'),
        findsOneWidget);
  });

  testWidgets('a backend 400 shows Hungarian copy inline', (tester) async {
    stubGenerate(() => Future.error(
        const PlanValidationException('Invalid trainingBlockId.')));
    await pump(tester);

    await tester.tap(find.text('Generálás'));
    await tester.pumpAndSettle();

    expect(
        find.text(
            'A kiválasztott tréningblokk nem ehhez a sportolóhoz tartozik.'),
        findsOneWidget);
    expect(find.textContaining('Invalid'), findsNothing);
  });

  testWidgets('an unavailable AI suggests the rule-based mode',
      (tester) async {
    stubGenerate(() => Future.error(
        const PlanLlmUnavailableException('No candidate plan could be produced.')));
    await pump(tester);

    await tester.tap(find.text('Generálás'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Csak szabályalapú'), findsWidgets);
    expect(find.textContaining('No candidate'), findsNothing);
  });

  testWidgets('success shows the generated plan', (tester) async {
    stubGenerate(() async => _result());
    await pump(tester);

    await tester.tap(find.text('Generálás'));
    await tester.pumpAndSettle();

    expect(find.text('Felső/alsó – 4 hét'), findsOneWidget);
    expect(find.text('Szerkesztő'), findsOneWidget);
    verify(() => plans.generate(
        athleteId: 'a1', mode: 'Hybrid', weeks: 4, trainingBlockId: null))
        .called(1);
  });
}
