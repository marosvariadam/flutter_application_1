import 'package:flutter/material.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';

/// The app's card: card surface, `rCard` corners, the resting card shadow.
/// With [onTap] it gets an ink ripple clipped to the rounded corners.
class DTCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;

  /// Defaults to the theme's card surface.
  final Color? color;

  const DTCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DT.s4),
    this.onTap,
    this.radius = DT.rCard,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    final content = Padding(padding: padding, child: child);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: DT.shadowCard(context),
      ),
      child: Material(
        color: color ?? DT.of(context).cardSurface,
        borderRadius: shape,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? content
            : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}
