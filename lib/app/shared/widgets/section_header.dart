import 'package:flutter/material.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/design/dt_text.dart';

/// Section title (h2) with an optional "Összes" style text action on the
/// right.
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onAction;
  final String actionLabel;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.onAction,
    this.actionLabel = 'Összes',
    this.padding = const EdgeInsets.only(bottom: DT.s3),
  });

  @override
  Widget build(BuildContext context) {
    final t = DTText.of(context);
    final row = Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: t.h2),
          ),
        ),
        if (onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: DT.of(context).accentPrimary,
              minimumSize: const Size(DT.minTap, DT.minTap),
            ),
            child: Text(actionLabel,
                style: t.label.copyWith(
                    color: DT.of(context).accentPrimary,
                    fontWeight: FontWeight.w600)),
          ),
      ],
    );
    // The tap-size floor is for the action; a bare title keeps its own
    // height so section spacing stays as it was.
    return Padding(
      padding: padding,
      child: onAction == null
          ? row
          : ConstrainedBox(
              constraints: const BoxConstraints(minHeight: DT.minTap),
              child: row,
            ),
    );
  }
}
