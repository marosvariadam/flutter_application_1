import 'package:flutter/material.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/design/dt_colors.dart';
import 'package:flutter_application_1/app/design/dt_text.dart';

enum StatusTone { success, warning, danger, info, neutral }

/// Pill-shaped status label: soft tinted background with strong text in
/// the tone's accent. Replaces the private meta/info/type chips and the
/// difficulty chips.
class StatusChip extends StatelessWidget {
  final String label;
  final StatusTone tone;
  final IconData? icon;
  final Color? _color;

  const StatusChip(
    this.label, {
    super.key,
    this.tone = StatusTone.neutral,
    this.icon,
  }) : _color = null;

  /// For accents outside the five tones (e.g. `DT.of(context).difficulty(3)`):
  /// [color] text on a 15 % tint of it.
  const StatusChip.custom(
    this.label, {
    super.key,
    required Color color,
    this.icon,
  })  : _color = color,
        tone = StatusTone.neutral;

  /// Background and text color for [tone] in palette [c].
  static ({Color background, Color foreground}) toneColors(
      DTColors c, StatusTone tone) {
    return switch (tone) {
      StatusTone.success =>
        (background: c.successSoft, foreground: c.accentSuccess),
      StatusTone.warning =>
        (background: c.warningSoft, foreground: c.accentWarning),
      StatusTone.danger =>
        (background: c.dangerSoft, foreground: c.accentDanger),
      StatusTone.info =>
        (background: c.primarySoft, foreground: c.accentPrimary),
      StatusTone.neutral =>
        (background: c.borderLight, foreground: c.textSecondary),
    };
  }

  @override
  Widget build(BuildContext context) {
    final custom = _color;
    final colors = custom == null
        ? toneColors(DT.of(context), tone)
        : (background: custom.withValues(alpha: 0.15), foreground: custom);
    final style = DTText.of(context)
        .caption
        .copyWith(color: colors.foreground, fontWeight: FontWeight.w700);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DT.s2, vertical: 3),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(DT.rPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: colors.foreground),
            const SizedBox(width: DT.s1),
          ],
          Flexible(
            child: Text(label, style: style, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
