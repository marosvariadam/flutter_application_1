import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/dt_colors.dart';

/// Design tokens: spacing, radii, shadows, motion, tap size and color
/// access.
///
/// Colors: always `DT.of(context).x` — those flip with light/dark. The
/// static color constants at the bottom are light-only leftovers and are
/// deprecated; each message names its theme-aware replacement.
/// Typography lives in `DTText`.
class DT {
  // Spacing
  static const s1 = 4.0,
      s2 = 8.0,
      s3 = 12.0,
      s4 = 16.0,
      s5 = 20.0,
      s6 = 24.0,
      s8 = 32.0,
      s9 = 36.0;

  // Border radius — the only radii to use.
  static const rXs = 6.0;
  static const rCardSmall = 12.0;
  static const rChip = 16.0;
  static const rCard = 20.0;
  static const rCardLarge = 24.0;

  /// Fully rounded ends (pills, handles, chips).
  static const rPill = 999.0;

  /// Minimum size of any tappable target.
  static const minTap = 44.0;

  // Motion
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);

  // Theme-aware accessor
  static DTColors of(BuildContext context) => DTColors.of(context);

  /// Resting card shadow.
  static List<BoxShadow> shadowCard(BuildContext context) => [
        BoxShadow(
          color: DTColors.of(context).shadowLight,
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  /// Shadow for floating surfaces (bottom nav, FAB-like elements).
  static List<BoxShadow> shadowFloating(BuildContext context) => [
        BoxShadow(
          color: DTColors.of(context).shadowMedium,
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  // Deprecated light-only colors. They do not switch in dark mode.

  @Deprecated('use DT.of(context).bg')
  static const bg = Color(0xFFF5F3FA);

  @Deprecated('use DT.of(context).text')
  static const gbBlack = Color(0xFF0F1115);
  @Deprecated('use DT.of(context).cardSurface (or .textOnAccent for text)')
  static const gbWhite = Color(0xFFFFFFFF);

  @Deprecated('use DT.of(context).text')
  static const text = Color(0xFF0F1115);
  @Deprecated('use DT.of(context).textPrimary')
  static const textPrimary = Color(0xFF14181F);
  @Deprecated('use DT.of(context).textSecondary')
  static const textSecondary = Color(0xFF5A6068);
  @Deprecated('use DT.of(context).textOnAccent')
  static const textWhite = Color(0xFFFFFFFF);
  @Deprecated('use DT.of(context).textGrey')
  static const textGrey = Color(0xFFB8BCC4);

  @Deprecated('use DT.of(context).accentYellow')
  static const cardYellow = Color(0xFFFFC85D);
  @Deprecated('use DT.of(context).accentBlueSoft')
  static const cardBlue = Color(0xFFBBD2FF);
  @Deprecated('use DT.of(context).accentDanger')
  static const cardRed = Color(0xFFFF6B6B);
  @Deprecated('use DT.of(context).accentTeal')
  static const cardTeal = Color(0xFF4ECDC4);
  @Deprecated('use DT.of(context).accentOrange')
  static const cardOrange = Color(0xFFFF6B35);

  @Deprecated('use DT.of(context).challengeCardGradientStart')
  static const challengeCardGradientStart = Color(0xFFE8E2F3);
  @Deprecated('use DT.of(context).challengeCardGradientEnd')
  static const challengeCardGradientEnd = Color(0xFFF0EBF7);

  @Deprecated('use DT.of(context).successSoft')
  static const metricGreen = Color(0xFFE7F8ED);
  @Deprecated('use DT.of(context).accentPrimary')
  static const metricBlue = Color(0xFF3D7AE5);
  @Deprecated('use DT.of(context).warningSoft (or .accentYellow)')
  static const metricOrange = Color(0xFFF8DFBD);

  @Deprecated('use DT.of(context).difficultyEasy')
  static const difficultyLight = Color(0xFF22A06B);
  @Deprecated('use DT.of(context).difficultyHard (Nehéz, orange) or '
      '.difficultyIntense (Intenzív, red) — or DT.of(context).difficulty(level)')
  static const difficultyHard = Color(0xFFE04D4D);
  @Deprecated('use DT.of(context).difficultyMedium')
  static const difficultyMedium = Color(0xFFE08530);

  @Deprecated('use DT.of(context).shadowLight or DT.shadowCard(context)')
  static const shadowLight = Color(0x14000000);
  @Deprecated('use DT.of(context).shadowMedium or DT.shadowFloating(context)')
  static const shadowMedium = Color(0x26000000);
  @Deprecated('use DT.of(context).bottomNavBg')
  static const bottomNavBG = Color(0xFF0F1115);

  @Deprecated('use DT.of(context).borderLight')
  static const borderLight = Color(0xFFEAEAF0);
  @Deprecated('use DT.of(context).borderGrey')
  static const borderGrey = Color(0xFFD9D9E0);

  @Deprecated('use DT.of(context).iconLight')
  static const iconLight = Color(0xFF5A6068);
  @Deprecated('use DT.of(context).iconLightGrey')
  static const iconLightGrey = Color(0xFFD9D9E0);
}
