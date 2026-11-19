import 'package:flutter/material.dart';

/// Puts a centered placeholder (`EmptyState`, `ErrorState`) inside a
/// `RefreshIndicator`: it fills the viewport, stays centered and is always
/// scrollable, so pull-to-refresh also works on an empty or failed list.
/// Taller content (large font sizes) simply scrolls.
class RefreshableFill extends StatelessWidget {
  final Widget child;

  const RefreshableFill({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }
}
