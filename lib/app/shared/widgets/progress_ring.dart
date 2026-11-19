import 'package:flutter/material.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/design/dt_text.dart';

/// Circular progress (e.g. completed exercises / total) with a short label
/// in the middle. At 100 % it switches to [DTColors.accentSuccess] and a
/// check mark.
class ProgressRing extends StatelessWidget {
  final int done;
  final int total;
  final double size;

  /// Read by screen readers, e.g. "gyakorlat" → "2 / 5 gyakorlat kész".
  final String unit;

  const ProgressRing({
    super.key,
    required this.done,
    required this.total,
    this.size = 52,
    this.unit = '',
  });

  double get value => total <= 0 ? 0 : (done / total).clamp(0.0, 1.0);
  bool get isComplete => total > 0 && done >= total;

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    final color = isComplete ? c.accentSuccess : c.accentPrimary;
    final label = unit.isEmpty ? '$done / $total kész' : '$done / $total $unit kész';
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: value,
              strokeWidth: 5,
              strokeCap: StrokeCap.round,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
            Center(
              child: isComplete
                  ? Icon(Icons.check, color: color, size: size * 0.45)
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.all(DT.s2),
                        child: Text(
                          '$done/$total',
                          style: DTText.of(context)
                              .caption
                              .copyWith(fontWeight: FontWeight.w700, color: color),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
