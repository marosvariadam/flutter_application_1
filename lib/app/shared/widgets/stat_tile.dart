import 'package:flutter/material.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/design/dt_text.dart';

/// Small metric tile: icon, big value, caption label.
///
/// The default constructor is the card style from the athlete detail page
/// (card surface, card shadow, centered, icon in [color]); [StatTile.filled]
/// is the coach-home style (tinted background, start-aligned, no shadow).
class StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool _filled;

  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  }) : _filled = false;

  /// [color] is the tile background here; the icon uses the text color.
  const StatTile.filled({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  }) : _filled = true;

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    final t = DTText.of(context);
    final valueStyle = t.h2.copyWith(fontWeight: FontWeight.w800);
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Container(
        padding: _filled
            ? const EdgeInsets.all(DT.s3)
            : const EdgeInsets.symmetric(vertical: DT.s3, horizontal: DT.s2),
        decoration: BoxDecoration(
          color: _filled ? color : c.cardSurface,
          borderRadius: BorderRadius.circular(DT.rCardSmall),
          boxShadow: _filled ? null : DT.shadowCard(context),
        ),
        child: Column(
          crossAxisAlignment: _filled
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            Icon(icon, color: _filled ? c.textPrimary : color, size: 20),
            SizedBox(height: _filled ? DT.s2 : DT.s1),
            Text(value, style: valueStyle),
            Text(
              label,
              style: t.caption,
              textAlign: _filled ? TextAlign.start : TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
