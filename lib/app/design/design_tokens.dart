import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/dt_colors.dart';

/// Design tokens - spacing, radii, and color access.
///
/// Color usage rule:
///  - In build methods, prefer `DT.of(context).colorName` - those flip with the
///    light/dark theme.
///  - Static `DT.colorName` constants below are LIGHT-scheme values, kept for
///    const contexts (constructor defaults, decorative accents that don't need
///    to flip). They will NOT switch in dark mode - migrate to `DT.of(...)`
///    where the surface needs to react.
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

  // Border radius
  static const rChip = 16.0;
  static const rCard = 20.0;
  static const rCardSmall = 12.0;
  static const rCardLarge = 24.0;

  // Theme-aware accessor
  static DTColors of(BuildContext context) => DTColors.of(context);

  // Static fallback colors (LIGHT scheme defaults)
  // These exist for const contexts and back-compat. Do not assume they switch.

  /// Soft lavender app background (light scheme).
  static const bg = Color(0xFFF5F3FA);

  static const gbBlack = Color(0xFF0F1115);
  static const gbWhite = Color(0xFFFFFFFF);

  static const text = Color(0xFF0F1115);
  static const textPrimary = Color(0xFF14181F);
  static const textSecondary = Color(0xFF5A6068);
  static const textWhite = Color(0xFFFFFFFF);
  static const textGrey = Color(0xFFB8BCC4);

  // Decorative card / accent colors - these stay roughly the same in both
  // themes because they're brand accents, not surfaces. The theme-aware
  // `accentX` tokens in DTColors are the preferred way to consume them.
  static const cardYellow = Color(0xFFFFC85D);
  static const cardBlue = Color(0xFFBBD2FF);
  static const cardRed = Color(0xFFFF6B6B);
  static const cardTeal = Color(0xFF4ECDC4);
  static const cardOrange = Color(0xFFFF6B35);

  static const challengeCardGradientStart = Color(0xFFE8E2F3);
  static const challengeCardGradientEnd = Color(0xFFF0EBF7);

  static const metricGreen = Color(0xFFE7F8ED);
  static const metricBlue = Color(0xFF3D7AE5);
  static const metricOrange = Color(0xFFF8DFBD);

  static const difficultyLight = Color(0xFF22A06B);
  static const difficultyHard = Color(0xFFE04D4D);
  static const difficultyMedium = Color(0xFFE08530);

  static const shadowLight = Color(0x14000000); // 8% - light scheme
  static const shadowMedium = Color(0x26000000);
  static const bottomNavBG = Color(0xFF0F1115);

  static const borderLight = Color(0xFFEAEAF0);
  static const borderGrey = Color(0xFFD9D9E0);

  static const iconLight = Color(0xFF5A6068);
  static const iconLightGrey = Color(0xFFD9D9E0);
}
