import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/dt_colors.dart';

class DT {
  // Spacing
  static const s1 = 4.0, s2 = 8.0, s3 = 12.0, s4 = 16.0, s5 = 20.0, s6 = 24.0, s8 = 32.0, s9 = 36.0;

  // Border radius
  static const rChip = 16.0;
  static const rCard = 20.0;
  static const rCardSmall = 12.0;
  static const rCardLarge = 24.0;

  // ── Theme-aware colors ─────────────────────────────────────────────────────
  // Use DT.of(context).colorName in build methods instead of DT.colorName.
  static DTColors of(BuildContext context) => DTColors.of(context);

  // ── Static fallback colors (light mode) ────────────────────────────────────
  // These remain for const contexts (e.g. constructor defaults) and for code
  // that has not yet been migrated to DT.of(context).
  static const bg = Color.fromARGB(255, 245, 243, 250);
  static const gbBlack = Colors.black;
  static const gbWhite = Colors.white;

  static const text = Color(0xFF0F1115);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF666666);
  static const textWhite = Colors.white;
  static const textGrey = Color(0xFFCCCCCC);

  // Card / accent colors (same in both themes)
  static const cardYellow = Color(0xFFFFC85D);
  static const cardBlue = Color(0xFFBBD2FF);
  static const cardRed = Color(0xFFFF6B6B);
  static const cardTeal = Color(0xFF4ECDC4);
  static const cardOrange = Color(0xFFFF6B35);

  static const challengeCardGradientStart = Color(0xFFE8E2F3);
  static const challengeCardGradientEnd = Color(0xFFF0EBF7);

  static const metricGreen = Color(0xFFE7F8ED);
  static const metricBlue = Color.fromARGB(255, 66, 138, 233);
  static const metricOrange = Color.fromARGB(255, 248, 223, 189);

  static const difficultyLight = Colors.green;
  static const difficultyHard = Colors.red;
  static const difficultyMedium = Colors.orange;

  static const socialPink = Colors.pink;
  static const socialRed = Colors.red;
  static const socialBlue = Colors.blue;

  static const shadowLight = Color.fromARGB(40, 0, 0, 0);
  static const shadowMedium = Color(0x1A000000);
  static const bottomNavBG = Color(0xFF0F1115);

  static const borderLight = Color(0xFFF0F0F0);
  static const borderGrey = Color(0xFFE0E0E0);

  static const iconLight = Color(0xFF666666);
  static const iconLightGrey = Color(0xFFE0E0E0);
}
