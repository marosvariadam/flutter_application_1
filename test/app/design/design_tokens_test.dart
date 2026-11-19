import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/design/dt_colors.dart';
import 'package:flutter_application_1/app/design/dt_text.dart';
import 'package:flutter_application_1/app/design/theme.dart';

Future<BuildContext> _context(WidgetTester tester, {required bool dark}) async {
  late BuildContext captured;
  await tester.pumpWidget(MaterialApp(
    theme: buildTheme(),
    darkTheme: buildDarkTheme(),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    home: Builder(builder: (context) {
      captured = context;
      return const SizedBox();
    }),
  ));
  return captured;
}

void main() {
  test('layout tokens have the documented values', () {
    expect(DT.rXs, 6);
    expect(DT.rPill, 999);
    expect(DT.minTap, 44);
    expect(DT.fast, const Duration(milliseconds: 150));
    expect(DT.normal, const Duration(milliseconds: 250));
  });

  test('DTText follows the type scale', () {
    final t = DTText.fromColors(DTColors.light);
    final scale = {
      'display': (t.display, 28.0, FontWeight.w800),
      'h1': (t.h1, 22.0, FontWeight.w700),
      'h2': (t.h2, 18.0, FontWeight.w700),
      'title': (t.title, 16.0, FontWeight.w600),
      'body': (t.body, 14.0, FontWeight.w400),
      'bodyStrong': (t.bodyStrong, 14.0, FontWeight.w600),
      'label': (t.label, 13.0, FontWeight.w500),
      'caption': (t.caption, 12.0, FontWeight.w500),
      'overline': (t.overline, 12.0, FontWeight.w700),
    };
    scale.forEach((name, spec) {
      expect(spec.$1.fontSize, spec.$2, reason: name);
      expect(spec.$1.fontWeight, spec.$3, reason: name);
    });
    expect(t.overline.letterSpacing, 0.6);
    expect(t.label.color, DTColors.light.textSecondary);
    expect(t.caption.color, DTColors.light.textSecondary);
    expect(t.body.color, DTColors.light.textPrimary);
    expect(DTText.upper('edzéstervem'), 'EDZÉSTERVEM');
  });

  for (final dark in [false, true]) {
    final palette = dark ? DTColors.dark : DTColors.light;
    final theme = dark ? 'dark' : 'light';

    testWidgets('DTText.of and shadows follow the theme ($theme)',
        (tester) async {
      final context = await _context(tester, dark: dark);
      final t = DTText.of(context);
      expect(t.h2.color, palette.textPrimary);
      expect(t.caption.color, palette.textSecondary);

      final card = DT.shadowCard(context).single;
      expect(card.color, palette.shadowLight);
      expect(card.blurRadius, 12);
      expect(card.offset, const Offset(0, 4));
      final floating = DT.shadowFloating(context).single;
      expect(floating.color, palette.shadowMedium);
      expect(floating.blurRadius, 20);
      expect(floating.offset, const Offset(0, 6));
    });

    testWidgets('a bare Text renders with DTText.body ($theme)',
        (tester) async {
      final context = await _context(tester, dark: dark);
      final bodyMedium = Theme.of(context).textTheme.bodyMedium!;
      expect(bodyMedium.fontSize, 14);
      expect(bodyMedium.fontWeight, FontWeight.w400);
      expect(bodyMedium.color, palette.textPrimary);
    });
  }

  group('DTColors', () {
    test('light palette keeps the existing brand values', () {
      const c = DTColors.light;
      expect(c.accentYellow, const Color(0xFFFFC85D));
      expect(c.accentOrange, const Color(0xFFFF6B35));
      expect(c.accentBlueSoft, const Color(0xFFBBD2FF));
      expect(c.difficultyEasy, c.accentSuccess);
      expect(c.difficultyMedium, c.accentWarning);
      expect(c.difficultyHard, c.accentOrange);
      expect(c.difficultyIntense, c.accentDanger);
      // Same six colors the messaging avatars use today.
      expect(c.avatarPalette, const [
        Color(0xFF428AE9),
        Color(0xFF4ECDC4),
        Color(0xFFFF6B35),
        Color(0xFFFFC85D),
        Color(0xFFFF6B6B),
        Color(0xFF9B59B6),
      ]);
    });

    test('both palettes have six avatar colors and distinct soft tints', () {
      for (final c in [DTColors.light, DTColors.dark]) {
        expect(c.avatarPalette, hasLength(6));
        expect(
            {c.successSoft, c.warningSoft, c.dangerSoft, c.primarySoft},
            hasLength(4));
        expect(c.successSoft, isNot(c.cardSurface));
      }
    });

    test('difficulty(level) maps 1–4 and clamps', () {
      const c = DTColors.light;
      expect(c.difficulty(1), c.difficultyEasy);
      expect(c.difficulty(2), c.difficultyMedium);
      expect(c.difficulty(3), c.difficultyHard);
      expect(c.difficulty(4), c.difficultyIntense);
      expect(c.difficulty(0), c.difficultyEasy);
      expect(c.difficulty(9), c.difficultyIntense);
    });

    test('copyWith and lerp carry the new tokens', () {
      final changed = DTColors.light.copyWith(primarySoft: const Color(0xFF000001));
      expect(changed.primarySoft, const Color(0xFF000001));
      expect(changed.accentYellow, DTColors.light.accentYellow);

      final mid = DTColors.light.lerp(DTColors.dark, 0.5);
      expect(mid.avatarPalette, hasLength(6));
      expect(mid.successSoft,
          Color.lerp(DTColors.light.successSoft, DTColors.dark.successSoft, 0.5));
      expect(DTColors.light.lerp(DTColors.dark, 1).dangerSoft,
          DTColors.dark.dangerSoft);
    });
  });
}
