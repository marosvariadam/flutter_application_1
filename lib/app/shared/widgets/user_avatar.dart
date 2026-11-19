import 'package:flutter/material.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';

/// Round avatar with the person's initials on a color picked from
/// `avatarPalette` by a stable hash of the name, so a person keeps the same
/// color everywhere and across launches.
class UserAvatar extends StatelessWidget {
  final String name;
  final double size;

  const UserAvatar({super.key, required this.name, this.size = 40});

  /// "Kiss Anna" → "KA", "anna" → "A", "" → "?".
  static String initialsFor(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first;
    final second = parts.length > 1 ? parts[1].characters.first : '';
    return '$first$second'.toUpperCase();
  }

  /// Index into a palette of [length] colors. Deterministic (unlike
  /// `String.hashCode`) and case-insensitive.
  static int paletteIndex(String name, int length) {
    var hash = 0;
    for (final unit in name.trim().toLowerCase().codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash % length;
  }

  @override
  Widget build(BuildContext context) {
    final palette = DT.of(context).avatarPalette;
    final color = palette[paletteIndex(name, palette.length)];
    return Semantics(
      label: name,
      image: true,
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.18),
        ),
        alignment: Alignment.center,
        child: Text(
          initialsFor(name),
          style: TextStyle(
            color: color,
            fontSize: size * 0.36,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
