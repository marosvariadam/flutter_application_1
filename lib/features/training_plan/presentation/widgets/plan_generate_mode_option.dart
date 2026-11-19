import 'package:flutter/material.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';

/// One selectable generation mode row (radio icon, label, description).
class PlanGenerateModeOption extends StatelessWidget {
  final String value;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onSelect;

  const PlanGenerateModeOption({
    super.key,
    required this.value,
    required this.label,
    required this.description,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: DT.s2),
        padding: const EdgeInsets.all(DT.s3),
        decoration: BoxDecoration(
          color: selected
              ? DT.metricBlue.withValues(alpha: 0.08)
              : DT.of(context).cardSurface,
          borderRadius: BorderRadius.circular(DT.rCardSmall),
          border: Border.all(
            color:
                selected ? DT.metricBlue : DT.of(context).borderGrey,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color:
                  selected ? DT.metricBlue : DT.of(context).iconLight,
            ),
            const SizedBox(width: DT.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? DT.metricBlue
                          : DT.of(context).textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                          color: DT.of(context).textSecondary,
                          fontSize: DT.s3),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
