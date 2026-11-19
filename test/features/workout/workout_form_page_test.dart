import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/features/workout/presentation/workout_form_page.dart';

import '../../a11y/page_fixtures.dart';
import '../../a11y/page_harness.dart';
import '../../helpers/fake_http.dart';

String _shown(DateTime d) => '${d.year}. ${d.month}. ${d.day}.';

void main() {
  setUpAll(loadRealFonts);

  testWidgets('a missed planned workout can be rescheduled', (tester) async {
    final now = DateTime.now();
    final past = DateTime(now.year, now.month, now.day - 3);
    await pumpAppPage(
      tester,
      const WorkoutFormPage(workoutId: 'w-old'),
      role: Role.trainer,
      textScale: 1,
      adapter: FakeHttpAdapter((r) => r.method == 'GET' &&
              r.path == '/api/workout/w-old'
          ? FakeResponse(200, workoutJson('w-old', -3))
          : fixtureApi(r)),
    );
    expect(find.text(_shown(past)), findsOneWidget);

    await tester.ensureVisible(find.text('Tervezett dátum'));
    await tester.tap(find.text('Tervezett dátum'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(DatePickerDialog), findsOneWidget);

    // The picker opens on today, the earliest day it allows.
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text(_shown(now)), findsOneWidget);
  });
}
