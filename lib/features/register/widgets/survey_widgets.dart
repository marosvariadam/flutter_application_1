import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter/services.dart';

/// Single-choice row used by the profile survey's goal and level steps.
class SurveyOptionRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const SurveyOptionRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: DT.s3),
        padding: const EdgeInsets.symmetric(horizontal: DT.s4, vertical: DT.s4),
        decoration: BoxDecoration(
          color: selected
              ? DT.of(context).accentPrimary.withValues(alpha: 0.08)
              : DT.of(context).cardSurface,
          border: Border.all(
            color: selected ? DT.of(context).accentPrimary : DT.of(context).borderGrey,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(DT.rCardSmall),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? DT.of(context).accentPrimary : DT.of(context).iconLight,
            ),
            const SizedBox(width: DT.s3),
            Text(
              label,
              style: TextStyle(
                color: selected ? DT.of(context).accentPrimary : DT.of(context).textPrimary,
                fontSize: DT.s4,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SurveyChipOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const SurveyChipOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: DT.s4, vertical: DT.s3),
        decoration: BoxDecoration(
          color: selected
              ? DT.of(context).accentPrimary.withValues(alpha: 0.08)
              : DT.of(context).cardSurface,
          border: Border.all(
            color: selected ? DT.of(context).accentPrimary : DT.of(context).borderGrey,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(DT.rChip),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? DT.of(context).accentPrimary : DT.of(context).textPrimary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// Big number + slider used by the survey's numeric steps.
class SurveyNumberSlider extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final int divisions;
  final String unit;
  final String minLabel;
  final String maxLabel;
  final ValueChanged<int> onChanged;

  const SurveyNumberSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.unit,
    required this.minLabel,
    required this.maxLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    return Column(
      children: [
        const SizedBox(height: DT.s5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$value',
              style: TextStyle(
                color: c.accentPrimary,
                fontSize: 72,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: DT.s2),
            Text(
              unit,
              style: TextStyle(color: c.textSecondary, fontSize: DT.s5),
            ),
          ],
        ),
        const SizedBox(height: DT.s5),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: c.accentPrimary,
            inactiveTrackColor: c.borderGrey,
            thumbColor: c.accentPrimary,
            overlayColor: c.accentPrimary.withValues(alpha: 0.1),
            trackHeight: 6,
          ),
          child: Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: divisions,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DT.s2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(minLabel, style: TextStyle(color: c.textSecondary)),
              Text(maxLabel, style: TextStyle(color: c.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
