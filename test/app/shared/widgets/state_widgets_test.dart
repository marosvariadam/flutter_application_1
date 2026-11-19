import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/design/theme.dart';
import 'package:flutter_application_1/app/shared/widgets/empty_state.dart';
import 'package:flutter_application_1/app/shared/widgets/error_state.dart';

Widget _host(Widget child, {bool dark = false}) => MaterialApp(
      theme: buildTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(body: child),
    );

void main() {
  for (final dark in [false, true]) {
    final theme = dark ? 'dark' : 'light';

    testWidgets('EmptyState shows its copy and action ($theme)',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(
        EmptyState(
          icon: Icons.event_note,
          title: 'Nincs adat',
          message: 'Később visszanézhetsz.',
          actionLabel: 'Frissítés',
          onAction: () => taps++,
        ),
        dark: dark,
      ));

      expect(find.byIcon(Icons.event_note), findsOneWidget);
      expect(find.text('Nincs adat'), findsOneWidget);
      expect(find.text('Később visszanézhetsz.'), findsOneWidget);
      await tester.tap(find.text('Frissítés'));
      expect(taps, 1);
    });

    testWidgets('ErrorState offers a retry only when given one ($theme)',
        (tester) async {
      var retries = 0;
      await tester.pumpWidget(_host(
        ErrorState(message: 'Nincs kapcsolat.', onRetry: () => retries++),
        dark: dark,
      ));
      expect(find.text('Hiba történt'), findsOneWidget);
      expect(find.text('Nincs kapcsolat.'), findsOneWidget);
      await tester.tap(find.text('Újra'));
      expect(retries, 1);

      await tester.pumpWidget(_host(
        const ErrorState(message: 'Nincs jogosultság.'),
        dark: dark,
      ));
      expect(find.text('Újra'), findsNothing);
    });
  }

  testWidgets('EmptyState without action shows no button', (tester) async {
    await tester.pumpWidget(_host(
      const EmptyState(icon: Icons.inbox, title: 'Üres'),
    ));
    expect(find.byType(OutlinedButton), findsNothing);
  });
}
