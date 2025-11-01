import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: DT.cardTeal,
    brightness: Brightness.light
  );

  return base.copyWith(
    scaffoldBackgroundColor: DT.bg,
    textTheme: base.textTheme.apply(
      bodyColor: DT.text,
      displayColor: DT.text,
    ),
    cardTheme: CardThemeData(
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(DT.rCard)),
      )
    )
  );
}