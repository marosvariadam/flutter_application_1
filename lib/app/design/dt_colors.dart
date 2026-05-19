import 'package:flutter/material.dart';

/// Theme-aware color tokens. Access via [DTColors.of(context)].
///
/// Layout:
///  - Surfaces are a 3-tier system:    bg -> cardSurface -> cardSurfaceElevated
///  - Text is a 3-tier system:         textPrimary -> textSecondary -> textGrey
///  - Borders are a 2-tier system:     borderLight -> borderGrey
///  - Accents are theme-tuned so they pop on either background.
class DTColors extends ThemeExtension<DTColors> {
  const DTColors({
    // Surfaces
    required this.bg,
    required this.cardSurface,
    required this.cardSurfaceElevated,
    // Text
    required this.text,
    required this.textPrimary,
    required this.textSecondary,
    required this.textGrey,
    required this.textOnAccent,
    // Borders
    required this.borderLight,
    required this.borderGrey,
    // Icons
    required this.iconLight,
    required this.iconLightGrey,
    // Shadows
    required this.shadowLight,
    required this.shadowMedium,
    // Misc surfaces (decorative)
    required this.challengeCardGradientStart,
    required this.challengeCardGradientEnd,
    required this.dialogBg,
    // Bottom nav
    required this.bottomNavBg,
    required this.bottomNavSelectedBg,
    required this.bottomNavSelectedIcon,
    required this.bottomNavSelectedLabel,
    required this.bottomNavUnselected,
    // Accents (theme-tuned)
    required this.accentPrimary,
    required this.accentSuccess,
    required this.accentWarning,
    required this.accentDanger,
    required this.accentInfo,
    required this.accentTeal,
  });

  // Surfaces
  final Color bg;
  final Color cardSurface;
  final Color cardSurfaceElevated;

  // Text
  final Color text;
  final Color textPrimary;
  final Color textSecondary;
  final Color textGrey;
  /// White-ish, used for text/icons on top of accent-colored backgrounds.
  final Color textOnAccent;

  // Borders
  final Color borderLight;
  final Color borderGrey;

  // Icons
  final Color iconLight;
  final Color iconLightGrey;

  // Shadows
  final Color shadowLight;
  final Color shadowMedium;

  // Decorative surfaces
  final Color challengeCardGradientStart;
  final Color challengeCardGradientEnd;
  final Color dialogBg;

  // Bottom nav
  final Color bottomNavBg;
  final Color bottomNavSelectedBg;
  final Color bottomNavSelectedIcon;
  final Color bottomNavSelectedLabel;
  final Color bottomNavUnselected;

  // Accents
  final Color accentPrimary;
  final Color accentSuccess;
  final Color accentWarning;
  final Color accentDanger;
  final Color accentInfo;
  final Color accentTeal;

  // Light palette
  /// Soft lavender background, white cards. Polished, friendly.
  static const light = DTColors(
    bg: Color(0xFFF5F3FA),
    cardSurface: Color(0xFFFFFFFF),
    cardSurfaceElevated: Color(0xFFFFFFFF),

    text: Color(0xFF0F1115),
    textPrimary: Color(0xFF14181F),
    textSecondary: Color(0xFF5A6068),
    textGrey: Color(0xFFB8BCC4),
    textOnAccent: Color(0xFFFFFFFF),

    borderLight: Color(0xFFEAEAF0),
    borderGrey: Color(0xFFD9D9E0),

    iconLight: Color(0xFF5A6068),
    iconLightGrey: Color(0xFFD9D9E0),

    shadowLight: Color(0x14000000), // 8% black
    shadowMedium: Color(0x26000000), // 15% black

    challengeCardGradientStart: Color(0xFFE8E2F3),
    challengeCardGradientEnd: Color(0xFFF0EBF7),
    dialogBg: Color(0xFFFFFFFF),

    bottomNavBg: Color(0xFF0F1115),
    bottomNavSelectedBg: Color(0xFFF5F3FA),
    bottomNavSelectedIcon: Color(0xFF0F1115),
    bottomNavSelectedLabel: Color(0xFFFFFFFF),
    bottomNavUnselected: Color(0x80FFFFFF), // 50% white

    accentPrimary: Color(0xFF3D7AE5),  // refined metricBlue
    accentSuccess: Color(0xFF22A06B),
    accentWarning: Color(0xFFE08530),
    accentDanger: Color(0xFFE04D4D),
    accentInfo: Color(0xFF4ECDC4),
    accentTeal: Color(0xFF4ECDC4),
  );

  // Dark palette
  /// Deep slate-blue near-black with three distinct surface tiers.
  ///
  /// Cool dark charcoals (not pure black, not purple
  /// gray), brighter accents to compensate for lower bg luminance, stronger
  /// shadows so elevation reads correctly.
  static const dark = DTColors(
    bg: Color(0xFF0A0E13),                    // Scaffold: deep slate
    cardSurface: Color(0xFF151B23),           // Cards: one tier up
    cardSurfaceElevated: Color(0xFF1C242E),   // Modals / chart cards

    text: Color(0xFFF1F3F5),
    textPrimary: Color(0xFFF1F3F5),           // near-white, not pure
    textSecondary: Color(0xFFA1A8B3),         // mid-grey
    textGrey: Color(0xFF5F6975),              // placeholders / disabled
    textOnAccent: Color(0xFFFFFFFF),

    borderLight: Color(0xFF1F2832),           // subtle dividers
    borderGrey: Color(0xFF2D3744),            // stronger separators

    iconLight: Color(0xFFA1A8B3),
    iconLightGrey: Color(0xFF2D3744),

    // Dark mode benefits from STRONGER shadows because surfaces are close in
    // luminance - subtle black shadows are invisible.
    shadowLight: Color(0x66000000),  // 40% black
    shadowMedium: Color(0x99000000), // 60% black

    challengeCardGradientStart: Color(0xFF1E2536),
    challengeCardGradientEnd: Color(0xFF202A3A),
    dialogBg: Color(0xFF1C242E),

    bottomNavBg: Color(0xFF151B23),
    bottomNavSelectedBg: Color(0xFF2D3744),
    bottomNavSelectedIcon: Color(0xFFF1F3F5),
    bottomNavSelectedLabel: Color(0xFFF1F3F5),
    bottomNavUnselected: Color(0x80A1A8B3),

    accentPrimary: Color(0xFF5FA0FF),    // brighter blue for dark bg
    accentSuccess: Color(0xFF3DCB7F),    // brighter green
    accentWarning: Color(0xFFFF9C5C),    // softer orange
    accentDanger: Color(0xFFFF6B6B),     // existing cardRed works on dark
    accentInfo: Color(0xFF5FD1C8),       // brighter teal
    accentTeal: Color(0xFF5FD1C8),
  );

  static DTColors of(BuildContext context) =>
      Theme.of(context).extension<DTColors>() ?? light;

  @override
  DTColors copyWith({
    Color? bg,
    Color? cardSurface,
    Color? cardSurfaceElevated,
    Color? text,
    Color? textPrimary,
    Color? textSecondary,
    Color? textGrey,
    Color? textOnAccent,
    Color? borderLight,
    Color? borderGrey,
    Color? iconLight,
    Color? iconLightGrey,
    Color? shadowLight,
    Color? shadowMedium,
    Color? challengeCardGradientStart,
    Color? challengeCardGradientEnd,
    Color? dialogBg,
    Color? bottomNavBg,
    Color? bottomNavSelectedBg,
    Color? bottomNavSelectedIcon,
    Color? bottomNavSelectedLabel,
    Color? bottomNavUnselected,
    Color? accentPrimary,
    Color? accentSuccess,
    Color? accentWarning,
    Color? accentDanger,
    Color? accentInfo,
    Color? accentTeal,
  }) =>
      DTColors(
        bg: bg ?? this.bg,
        cardSurface: cardSurface ?? this.cardSurface,
        cardSurfaceElevated: cardSurfaceElevated ?? this.cardSurfaceElevated,
        text: text ?? this.text,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textGrey: textGrey ?? this.textGrey,
        textOnAccent: textOnAccent ?? this.textOnAccent,
        borderLight: borderLight ?? this.borderLight,
        borderGrey: borderGrey ?? this.borderGrey,
        iconLight: iconLight ?? this.iconLight,
        iconLightGrey: iconLightGrey ?? this.iconLightGrey,
        shadowLight: shadowLight ?? this.shadowLight,
        shadowMedium: shadowMedium ?? this.shadowMedium,
        challengeCardGradientStart:
            challengeCardGradientStart ?? this.challengeCardGradientStart,
        challengeCardGradientEnd:
            challengeCardGradientEnd ?? this.challengeCardGradientEnd,
        dialogBg: dialogBg ?? this.dialogBg,
        bottomNavBg: bottomNavBg ?? this.bottomNavBg,
        bottomNavSelectedBg: bottomNavSelectedBg ?? this.bottomNavSelectedBg,
        bottomNavSelectedIcon:
            bottomNavSelectedIcon ?? this.bottomNavSelectedIcon,
        bottomNavSelectedLabel:
            bottomNavSelectedLabel ?? this.bottomNavSelectedLabel,
        bottomNavUnselected: bottomNavUnselected ?? this.bottomNavUnselected,
        accentPrimary: accentPrimary ?? this.accentPrimary,
        accentSuccess: accentSuccess ?? this.accentSuccess,
        accentWarning: accentWarning ?? this.accentWarning,
        accentDanger: accentDanger ?? this.accentDanger,
        accentInfo: accentInfo ?? this.accentInfo,
        accentTeal: accentTeal ?? this.accentTeal,
      );

  @override
  DTColors lerp(DTColors? other, double t) {
    if (other == null) return this;
    return DTColors(
      bg: Color.lerp(bg, other.bg, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      cardSurfaceElevated:
          Color.lerp(cardSurfaceElevated, other.cardSurfaceElevated, t)!,
      text: Color.lerp(text, other.text, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textGrey: Color.lerp(textGrey, other.textGrey, t)!,
      textOnAccent: Color.lerp(textOnAccent, other.textOnAccent, t)!,
      borderLight: Color.lerp(borderLight, other.borderLight, t)!,
      borderGrey: Color.lerp(borderGrey, other.borderGrey, t)!,
      iconLight: Color.lerp(iconLight, other.iconLight, t)!,
      iconLightGrey: Color.lerp(iconLightGrey, other.iconLightGrey, t)!,
      shadowLight: Color.lerp(shadowLight, other.shadowLight, t)!,
      shadowMedium: Color.lerp(shadowMedium, other.shadowMedium, t)!,
      challengeCardGradientStart:
          Color.lerp(challengeCardGradientStart, other.challengeCardGradientStart, t)!,
      challengeCardGradientEnd:
          Color.lerp(challengeCardGradientEnd, other.challengeCardGradientEnd, t)!,
      dialogBg: Color.lerp(dialogBg, other.dialogBg, t)!,
      bottomNavBg: Color.lerp(bottomNavBg, other.bottomNavBg, t)!,
      bottomNavSelectedBg:
          Color.lerp(bottomNavSelectedBg, other.bottomNavSelectedBg, t)!,
      bottomNavSelectedIcon:
          Color.lerp(bottomNavSelectedIcon, other.bottomNavSelectedIcon, t)!,
      bottomNavSelectedLabel:
          Color.lerp(bottomNavSelectedLabel, other.bottomNavSelectedLabel, t)!,
      bottomNavUnselected:
          Color.lerp(bottomNavUnselected, other.bottomNavUnselected, t)!,
      accentPrimary: Color.lerp(accentPrimary, other.accentPrimary, t)!,
      accentSuccess: Color.lerp(accentSuccess, other.accentSuccess, t)!,
      accentWarning: Color.lerp(accentWarning, other.accentWarning, t)!,
      accentDanger: Color.lerp(accentDanger, other.accentDanger, t)!,
      accentInfo: Color.lerp(accentInfo, other.accentInfo, t)!,
      accentTeal: Color.lerp(accentTeal, other.accentTeal, t)!,
    );
  }
}
