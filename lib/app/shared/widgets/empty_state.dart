import 'package:flutter/material.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';

/// Centered placeholder for screens and sections with nothing to show:
/// an icon in a soft circle, a title, an optional explanation and an
/// optional action button.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    return StateMessage(
      icon: icon,
      tone: c.accentPrimary,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

/// Shared layout behind [EmptyState] and `ErrorState`.
class StateMessage extends StatelessWidget {
  final IconData icon;
  final Color tone;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const StateMessage({
    super.key,
    required this.icon,
    required this.tone,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DT.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: tone, size: 30),
            ),
            const SizedBox(height: DT.s4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: DT.s2),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textSecondary, fontSize: 14),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: DT.s4),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.accentPrimary,
                  side: BorderSide(color: c.accentPrimary),
                  minimumSize: const Size(120, 44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DT.rCardSmall)),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
