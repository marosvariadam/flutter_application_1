import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/training_plan/presentation/widgets/plan_generating_view.dart';

void main() {
  testWidgets('cycles through the generation stages every 4 s',
      (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PlanGeneratingView())));

    expect(find.text('Jelöltek generálása…'), findsOneWidget);
    expect(find.textContaining('10–30 másodpercet'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    expect(find.text('ML pontozás…'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Ellenőrzés…'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Jelöltek generálása…'), findsOneWidget);

    // Unmount so the periodic timer is cancelled before the test ends.
    await tester.pumpWidget(const SizedBox());
  });
}
