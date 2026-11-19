import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/dt_colors.dart';

/// Type scale with the theme's text colors baked in. Use
/// `DTText.of(context).title` etc. instead of ad-hoc `fontSize` values.
///
/// | token        | size / weight                 | use                       |
/// |--------------|-------------------------------|---------------------------|
/// | `display`    | 28 / w800                     | big numbers (1RM, streak) |
/// | `h1`         | 22 / w700                     | page title                |
/// | `h2`         | 18 / w700                     | section title             |
/// | `title`      | 16 / w600                     | card title                |
/// | `body`       | 14 / w400                     | body text                 |
/// | `bodyStrong` | 14 / w600                     | emphasized body           |
/// | `label`      | 13 / w500, secondary          | form labels, meta         |
/// | `caption`    | 12 / w500, secondary          | timestamps, chips — the minimum size in the app |
/// | `overline`   | 12 / w700, +0.6, secondary    | section labels (pass the text through [upper]) |
///
/// The theme's `bodyMedium` (what a bare `Text` uses) is [body], so default
/// text already matches the scale.
class DTText {
  final TextStyle display;
  final TextStyle h1;
  final TextStyle h2;
  final TextStyle title;
  final TextStyle body;
  final TextStyle bodyStrong;
  final TextStyle label;
  final TextStyle caption;
  final TextStyle overline;

  const DTText._({
    required this.display,
    required this.h1,
    required this.h2,
    required this.title,
    required this.body,
    required this.bodyStrong,
    required this.label,
    required this.caption,
    required this.overline,
  });

  factory DTText.fromColors(DTColors c) => DTText._(
        display: TextStyle(
            fontSize: 28, fontWeight: FontWeight.w800, color: c.textPrimary),
        h1: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w700, color: c.textPrimary),
        h2: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: c.textPrimary),
        title: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600, color: c.textPrimary),
        body: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w400, color: c.textPrimary),
        bodyStrong: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary),
        label: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500, color: c.textSecondary),
        caption: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500, color: c.textSecondary),
        overline: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: c.textSecondary,
        ),
      );

  static final DTText _light = DTText.fromColors(DTColors.light);
  static final DTText _dark = DTText.fromColors(DTColors.dark);

  static DTText of(BuildContext context) {
    final c = DTColors.of(context);
    if (identical(c, DTColors.light)) return _light;
    if (identical(c, DTColors.dark)) return _dark;
    // Mid theme-change animation the colors are interpolated.
    return DTText.fromColors(c);
  }

  /// Overline labels are uppercase; a TextStyle can't transform case.
  static String upper(String text) => text.toUpperCase();
}
