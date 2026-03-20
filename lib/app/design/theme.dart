import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/design/dt_colors.dart';

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: DT.cardTeal,
    brightness: Brightness.light,
  );

  return base.copyWith(
    scaffoldBackgroundColor: DTColors.light.bg,
    textTheme: base.textTheme.apply(
      bodyColor: DTColors.light.textPrimary,
      displayColor: DTColors.light.textPrimary,
    ),
    cardTheme: CardThemeData(
      color: DTColors.light.cardSurface,
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(DT.rCard)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: DTColors.light.dialogBg,
    ),
    extensions: const [DTColors.light],
  );
}

ThemeData buildDarkTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: DT.cardTeal,
    brightness: Brightness.dark,
  );

  return base.copyWith(
    scaffoldBackgroundColor: DTColors.dark.bg,
    textTheme: base.textTheme.apply(
      bodyColor: DTColors.dark.textPrimary,
      displayColor: DTColors.dark.textPrimary,
    ),
    cardTheme: CardThemeData(
      color: DTColors.dark.cardSurface,
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(DT.rCard)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: DTColors.dark.dialogBg,
    ),
    extensions: const [DTColors.dark],
  );
}
