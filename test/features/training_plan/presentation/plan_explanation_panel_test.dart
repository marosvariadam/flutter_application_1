import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_application_1/features/training_plan/data/models/plan_results.dart';
import 'package:flutter_application_1/features/training_plan/data/repositories/training_plan_repository.dart';
import 'package:flutter_application_1/features/training_plan/presentation/widgets/plan_explanation_panel.dart';

class _MockRepo extends Mock implements TrainingPlanRepository {}

void main() {
  late _MockRepo repo;

  setUp(() => repo = _MockRepo());

  Future<void> pumpPanel(WidgetTester tester) async {
    await tester.pumpWidget(RepositoryProvider<TrainingPlanRepository>.value(
      value: repo,
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: PlanExplanationPanel(planId: 'p1')),
        ),
      ),
    ));
  }

  void stub(Future<PlanExplanationModel> Function() answer) {
    when(() => repo.explanation(
          planId: any(named: 'planId'),
          language: any(named: 'language'),
        )).thenAnswer((_) => answer());
  }

  testWidgets('fetches nothing until asked, then renders the markdown',
      (tester) async {
    final pending = Completer<PlanExplanationModel>();
    stub(() => pending.future);
    await pumpPanel(tester);

    expect(find.text('Magyarázat kérése'), findsOneWidget);
    verifyNever(() => repo.explanation(
        planId: any(named: 'planId'), language: any(named: 'language')));

    await tester.tap(find.text('Magyarázat kérése'));
    await tester.pump();
    expect(find.textContaining('Magyarázat készítése'), findsOneWidget);

    pending.complete(const PlanExplanationModel(
      planId: 'p1',
      language: 'hu',
      explanation: 'A terv **hetente négyszer** dolgozik.',
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('hetente négyszer', findRichText: true),
        findsOneWidget);
    // Markdown markers are rendered, not shown literally.
    expect(find.textContaining('**', findRichText: true), findsNothing);
    expect(find.byTooltip('Új magyarázat'), findsOneWidget);
  });

  testWidgets('rate limit shows a retry that asks again', (tester) async {
    stub(() => Future.error(const PlanRateLimitedException()));
    await pumpPanel(tester);

    await tester.tap(find.text('Magyarázat kérése'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Túl sok kérés'), findsOneWidget);

    stub(() async => const PlanExplanationModel(
        planId: 'p1', language: 'hu', explanation: 'Most már megy.'));
    await tester.tap(find.text('Újra'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Most már megy.', findRichText: true),
        findsOneWidget);
  });
}
