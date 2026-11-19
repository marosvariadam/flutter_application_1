import 'package:flutter/material.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/shared/widgets/empty_state.dart';

/// Centered error placeholder with an optional "Újra" retry button. Takes
/// an already user-facing Hungarian [message]; map exceptions with
/// `friendlyErrorMessage` before passing them in.
class ErrorState extends StatelessWidget {
  final String message;
  final String title;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    required this.message,
    this.title = 'Hiba történt',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return StateMessage(
      icon: Icons.error_outline,
      tone: DT.of(context).accentDanger,
      title: title,
      message: message,
      actionLabel: onRetry == null ? null : 'Újra',
      onAction: onRetry,
    );
  }
}
