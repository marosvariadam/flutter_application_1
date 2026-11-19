import 'package:flutter/material.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';

/// Big week count plus a 2–12 week slider.
class PlanGenerateWeeksSelector extends StatelessWidget {
  final int weeks;
  final ValueChanged<int> onChanged;
  const PlanGenerateWeeksSelector({
    super.key,
    required this.weeks,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$weeks',
              style: TextStyle(
                color: DT.of(context).accentPrimary,
                fontSize: 48,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: DT.s2),
            Text(
              'hét',
              style: TextStyle(
                color: DT.of(context).textSecondary,
                fontSize: DT.s4,
              ),
            ),
          ],
        ),
        Slider(
          value: weeks.toDouble(),
          min: 2,
          max: 12,
          divisions: 10,
          activeColor: DT.of(context).accentPrimary,
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}
