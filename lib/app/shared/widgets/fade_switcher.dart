import 'package:flutter/material.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';

/// Cross-fades between a screen's loading, content, empty and error views
/// ([DT.normal]) so the page doesn't jump when data arrives. Children of
/// different types switch automatically; give same-typed children distinct
/// keys. Respects the system "reduce motion" setting.
class FadeSwitcher extends StatelessWidget {
  final Widget child;

  const FadeSwitcher({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return AnimatedSwitcher(
      duration: still ? Duration.zero : DT.normal,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      child: child,
    );
  }
}
