import 'package:flutter/material.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/design/dt_text.dart';
import 'package:flutter_application_1/app/shared/widgets/buttons.dart';

/// Centered placeholder for screens and sections with nothing to show:
/// an icon in a 64 px soft circle, an h2 title, an optional explanation
/// and an optional action.
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
      softTone: c.primarySoft,
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
  final Color softTone;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const StateMessage({
    super.key,
    required this.icon,
    required this.tone,
    required this.softTone,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    final t = DTText.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DT.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: softTone, shape: BoxShape.circle),
              child: Icon(icon, color: tone, size: 30),
            ),
            const SizedBox(height: DT.s4),
            Text(title, textAlign: TextAlign.center, style: t.h2),
            if (message != null) ...[
              const SizedBox(height: DT.s2),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: t.body.copyWith(color: c.textSecondary),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: DT.s4),
              SecondaryButton(
                label: actionLabel!,
                onPressed: onAction,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
