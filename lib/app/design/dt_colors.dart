import 'package:flutter/material.dart';

/// Theme-aware color tokens. Access via [DTColors.of(context)].
class DTColors extends ThemeExtension<DTColors> {
  const DTColors({
    required this.bg,
    required this.text,
    required this.textPrimary,
    required this.textSecondary,
    required this.textGrey,
    required this.borderLight,
    required this.borderGrey,
    required this.iconLight,
    required this.iconLightGrey,
    required this.shadowLight,
    required this.cardSurface,
    required this.challengeCardGradientStart,
    required this.challengeCardGradientEnd,
    required this.dialogBg,
  });

  final Color bg;
  final Color text;
  final Color textPrimary;
  final Color textSecondary;
  final Color textGrey;
  final Color borderLight;
  final Color borderGrey;
  final Color iconLight;
  final Color iconLightGrey;
  final Color shadowLight;
  final Color cardSurface;
  final Color challengeCardGradientStart;
  final Color challengeCardGradientEnd;
  final Color dialogBg;

  static const light = DTColors(
    bg: Color.fromARGB(255, 245, 243, 250),
    text: Color(0xFF0F1115),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF666666),
    textGrey: Color(0xFFCCCCCC),
    borderLight: Color(0xFFF0F0F0),
    borderGrey: Color(0xFFE0E0E0),
    iconLight: Color(0xFF666666),
    iconLightGrey: Color(0xFFE0E0E0),
    shadowLight: Color.fromARGB(40, 0, 0, 0),
    cardSurface: Colors.white,
    challengeCardGradientStart: Color(0xFFE8E2F3),
    challengeCardGradientEnd: Color(0xFFF0EBF7),
    dialogBg: Color.fromARGB(255, 245, 243, 250),
  );

  static const dark = DTColors(
    bg: Color(0xFF12121A),
    text: Color(0xFFE8E8F0),
    textPrimary: Color(0xFFE0E0E0),
    textSecondary: Color(0xFF9E9E9E),
    textGrey: Color(0xFF555565),
    borderLight: Color(0xFF2A2A38),
    borderGrey: Color(0xFF3A3A48),
    iconLight: Color(0xFFAAAAAA),
    iconLightGrey: Color(0xFF3A3A48),
    shadowLight: Color.fromARGB(80, 0, 0, 0),
    cardSurface: Color(0xFF1E1E2A),
    challengeCardGradientStart: Color(0xFF2A2440),
    challengeCardGradientEnd: Color(0xFF231E38),
    dialogBg: Color(0xFF1E1E2A),
  );

  static DTColors of(BuildContext context) =>
      Theme.of(context).extension<DTColors>() ?? light;

  @override
  DTColors copyWith({
    Color? bg,
    Color? text,
    Color? textPrimary,
    Color? textSecondary,
    Color? textGrey,
    Color? borderLight,
    Color? borderGrey,
    Color? iconLight,
    Color? iconLightGrey,
    Color? shadowLight,
    Color? cardSurface,
    Color? challengeCardGradientStart,
    Color? challengeCardGradientEnd,
    Color? dialogBg,
  }) =>
      DTColors(
        bg: bg ?? this.bg,
        text: text ?? this.text,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textGrey: textGrey ?? this.textGrey,
        borderLight: borderLight ?? this.borderLight,
        borderGrey: borderGrey ?? this.borderGrey,
        iconLight: iconLight ?? this.iconLight,
        iconLightGrey: iconLightGrey ?? this.iconLightGrey,
        shadowLight: shadowLight ?? this.shadowLight,
        cardSurface: cardSurface ?? this.cardSurface,
        challengeCardGradientStart:
            challengeCardGradientStart ?? this.challengeCardGradientStart,
        challengeCardGradientEnd:
            challengeCardGradientEnd ?? this.challengeCardGradientEnd,
        dialogBg: dialogBg ?? this.dialogBg,
      );

  @override
  DTColors lerp(DTColors? other, double t) {
    if (other == null) return this;
    return DTColors(
      bg: Color.lerp(bg, other.bg, t)!,
      text: Color.lerp(text, other.text, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textGrey: Color.lerp(textGrey, other.textGrey, t)!,
      borderLight: Color.lerp(borderLight, other.borderLight, t)!,
      borderGrey: Color.lerp(borderGrey, other.borderGrey, t)!,
      iconLight: Color.lerp(iconLight, other.iconLight, t)!,
      iconLightGrey: Color.lerp(iconLightGrey, other.iconLightGrey, t)!,
      shadowLight: Color.lerp(shadowLight, other.shadowLight, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      challengeCardGradientStart:
          Color.lerp(challengeCardGradientStart, other.challengeCardGradientStart, t)!,
      challengeCardGradientEnd:
          Color.lerp(challengeCardGradientEnd, other.challengeCardGradientEnd, t)!,
      dialogBg: Color.lerp(dialogBg, other.dialogBg, t)!,
    );
  }
}
