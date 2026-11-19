import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/design/dt_colors.dart';
import 'package:flutter_application_1/app/design/theme.dart';
import 'package:flutter_application_1/app/shared/widgets/status_chip.dart';

Widget _host(Widget child, {required bool dark}) => MaterialApp(
      theme: buildTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(body: Center(child: child)),
    );

Color _background(WidgetTester tester) {
  final box = tester.widget<Container>(find
      .descendant(of: find.byType(StatusChip), matching: find.byType(Container))
      .first);
  return (box.decoration! as BoxDecoration).color!;
}

Color? _textColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style?.color;

void main() {
  for (final dark in [false, true]) {
    final theme = dark ? 'dark' : 'light';
    final c = dark ? DTColors.dark : DTColors.light;

    final expected = {
      StatusTone.success: (c.successSoft, c.accentSuccess),
      StatusTone.warning: (c.warningSoft, c.accentWarning),
      StatusTone.danger: (c.dangerSoft, c.accentDanger),
      StatusTone.info: (c.primarySoft, c.accentPrimary),
      StatusTone.neutral: (c.borderLight, c.textSecondary),
    };

    expected.forEach((tone, colors) {
      testWidgets('${tone.name} uses its soft background and accent text '
          '($theme)', (tester) async {
        await tester.pumpWidget(
            _host(StatusChip('Állapot', tone: tone), dark: dark));

        expect(find.text('Állapot'), findsOneWidget);
        expect(_background(tester), colors.$1);
        expect(_textColor(tester, 'Állapot'), colors.$2);
        expect(StatusChip.toneColors(c, tone).background, colors.$1);
        expect(StatusChip.toneColors(c, tone).foreground, colors.$2);
      });
    });

    testWidgets('custom color tints its own background ($theme)',
        (tester) async {
      final hard = c.difficulty(3);
      await tester.pumpWidget(_host(
          StatusChip.custom('Nehéz', color: hard, icon: Icons.bolt),
          dark: dark));

      expect(_textColor(tester, 'Nehéz'), hard);
      expect(_background(tester), hard.withValues(alpha: 0.15));
      expect(tester.widget<Icon>(find.byIcon(Icons.bolt)).color, hard);
    });
  }

  testWidgets('chip text is caption size, never below 12 px', (tester) async {
    await tester.pumpWidget(
        _host(const StatusChip('Tervezett', tone: StatusTone.info), dark: false));
    final style = tester.widget<Text>(find.text('Tervezett')).style!;
    expect(style.fontSize, 12);
    expect(style.fontWeight, FontWeight.w700);
  });

  testWidgets('long labels ellipsize instead of overflowing', (tester) async {
    await tester.pumpWidget(_host(
      const SizedBox(
        width: 80,
        child: StatusChip('Nagyon hosszú állapotcímke', tone: StatusTone.warning),
      ),
      dark: false,
    ));
    expect(tester.takeException(), isNull);
  });
}
