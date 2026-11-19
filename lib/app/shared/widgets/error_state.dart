import 'package:flutter/material.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/shared/widgets/empty_state.dart';
import 'package:flutter_application_1/core/api/api_error_messages.dart';

/// Centered error placeholder with an optional "Újra" retry button.
///
/// Pass either a ready Hungarian [message] or the raw [error]; an error is
/// mapped to Hungarian copy (network, timeout, 401, 403, 5xx) and its own
/// text is never shown.
class ErrorState extends StatelessWidget {
  final Object? error;
  final String? message;
  final String title;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    this.error,
    this.message,
    this.title = 'Hiba történt',
    this.onRetry,
  }) : assert(error != null || message != null,
            'ErrorState needs an error or a message');

  static const fallbackMessage = 'Váratlan hiba történt. Próbáld újra.';

  /// The Hungarian text shown for [error].
  static String messageFor(Object error) =>
      friendlyErrorMessage(error, fallback: fallbackMessage);

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    return StateMessage(
      icon: Icons.error_outline,
      tone: c.accentDanger,
      softTone: c.dangerSoft,
      title: title,
      message: message ?? messageFor(error!),
      actionLabel: onRetry == null ? null : 'Újra',
      onAction: onRetry,
    );
  }
}
