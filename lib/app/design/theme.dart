import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/design/dt_colors.dart';

/// Light theme. Soft lavender background, white cards, blue accent.
ThemeData buildTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: DTColors.light.accentPrimary,
    brightness: Brightness.light,
  ).copyWith(
    surface: DTColors.light.cardSurface,
    onSurface: DTColors.light.textPrimary,
    primary: DTColors.light.accentPrimary,
    secondary: DTColors.light.accentTeal,
    error: DTColors.light.accentDanger,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    brightness: Brightness.light,
  );

  return base.copyWith(
    scaffoldBackgroundColor: DTColors.light.bg,
    canvasColor: DTColors.light.bg,
    dividerColor: DTColors.light.borderLight,
    textTheme: base.textTheme.apply(
      bodyColor: DTColors.light.textPrimary,
      displayColor: DTColors.light.textPrimary,
    ),
    iconTheme: IconThemeData(color: DTColors.light.iconLight),
    cardTheme: CardThemeData(
      color: DTColors.light.cardSurface,
      elevation: 4,
      shadowColor: DTColors.light.shadowMedium,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(DT.rCard)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: DTColors.light.dialogBg,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: DTColors.light.cardSurfaceElevated,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: DTColors.light.cardSurfaceElevated,
      contentTextStyle: TextStyle(color: DTColors.light.textPrimary),
      behavior: SnackBarBehavior.floating,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DTColors.light.cardSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        borderSide: BorderSide(color: DTColors.light.borderGrey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        borderSide: BorderSide(color: DTColors.light.borderGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        borderSide: BorderSide(color: DTColors.light.accentPrimary, width: 1.5),
      ),
      labelStyle: TextStyle(color: DTColors.light.textSecondary),
      hintStyle: TextStyle(color: DTColors.light.textGrey),
    ),
    extensions: const [DTColors.light],
  );
}

/// Dark theme. Deep slate near-black, two-tier surfaces, brighter accents.
ThemeData buildDarkTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: DTColors.dark.accentPrimary,
    brightness: Brightness.dark,
  ).copyWith(
    surface: DTColors.dark.cardSurface,
    onSurface: DTColors.dark.textPrimary,
    primary: DTColors.dark.accentPrimary,
    secondary: DTColors.dark.accentTeal,
    error: DTColors.dark.accentDanger,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    brightness: Brightness.dark,
  );

  return base.copyWith(
    scaffoldBackgroundColor: DTColors.dark.bg,
    canvasColor: DTColors.dark.bg,
    dividerColor: DTColors.dark.borderLight,
    textTheme: base.textTheme.apply(
      bodyColor: DTColors.dark.textPrimary,
      displayColor: DTColors.dark.textPrimary,
    ),
    iconTheme: IconThemeData(color: DTColors.dark.iconLight),
    cardTheme: CardThemeData(
      color: DTColors.dark.cardSurface,
      elevation: 4,
      shadowColor: DTColors.dark.shadowMedium,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(DT.rCard)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: DTColors.dark.dialogBg,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: DTColors.dark.cardSurfaceElevated,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: DTColors.dark.cardSurfaceElevated,
      contentTextStyle: TextStyle(color: DTColors.dark.textPrimary),
      behavior: SnackBarBehavior.floating,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DTColors.dark.cardSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        borderSide: BorderSide(color: DTColors.dark.borderGrey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        borderSide: BorderSide(color: DTColors.dark.borderGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        borderSide: BorderSide(color: DTColors.dark.accentPrimary, width: 1.5),
      ),
      labelStyle: TextStyle(color: DTColors.dark.textSecondary),
      hintStyle: TextStyle(color: DTColors.dark.textGrey),
    ),
    extensions: const [DTColors.dark],
  );
}
