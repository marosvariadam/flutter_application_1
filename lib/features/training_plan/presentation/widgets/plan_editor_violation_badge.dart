import 'package:flutter/material.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/training_plan/data/models/violation_model.dart';

/// Compact red/orange chip displaying validator output. Tapping shows the
/// full message in a bottom sheet so the row stays legible even with many
/// violations.
class PlanEditorViolationBadge extends StatelessWidget {
  final ViolationModel violation;
  final VoidCallback? onTap;
  const PlanEditorViolationBadge({
    super.key,
    required this.violation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isError = violation.isError;
    final color = isError ? DT.cardRed : DT.cardOrange;
    return InkWell(
      onTap: onTap ??
          () => showModalBottomSheet<void>(
                context: context,
                backgroundColor: DT.of(context).cardSurfaceElevated,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(DT.rCard)),
                ),
                builder: (_) => _ViolationDetailSheet(violation: violation),
              ),
      borderRadius: BorderRadius.circular(DT.rChip),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: DT.s2, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(DT.rChip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.warning_amber_outlined,
              color: color,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              isError ? 'Hiba' : 'Figyelem',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViolationDetailSheet extends StatelessWidget {
  final ViolationModel violation;
  const _ViolationDetailSheet({required this.violation});

  @override
  Widget build(BuildContext context) {
    final isError = violation.isError;
    final color = isError ? DT.cardRed : DT.cardOrange;
    return Padding(
      padding: const EdgeInsets.all(DT.s5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                  isError ? Icons.error_outline : Icons.warning_amber_outlined,
                  color: color,
                  size: 24),
              const SizedBox(width: DT.s2),
              Text(
                isError ? 'Hiba' : 'Figyelmeztetés',
                style: TextStyle(
                  color: color,
                  fontSize: DT.s5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: DT.s3),
          Text(
            violation.message,
            style: TextStyle(
                color: DT.of(context).textPrimary, fontSize: DT.s4),
          ),
          const SizedBox(height: DT.s2),
          Text(
            'Kód: ${violation.code}',
            style: TextStyle(
                color: DT.of(context).textSecondary, fontSize: DT.s3),
          ),
          const SizedBox(height: DT.s4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Bezárás'),
            ),
          ),
        ],
      ),
    );
  }
}
