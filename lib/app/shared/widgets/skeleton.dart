import 'package:flutter/material.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';

/// A plain placeholder shape. Wrap one or more in [SkeletonPulse] to animate
/// them together.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = DT.rXs,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: DT.of(context).borderLight,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

/// Fades its child in and out while content loads (no package needed).
/// Holds still when the platform asks to reduce motion.
class SkeletonPulse extends StatefulWidget {
  final Widget child;
  const SkeletonPulse({super.key, required this.child});

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _opacity =
      Tween<double>(begin: 0.45, end: 1).animate(_controller);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Betöltés…',
        child: ExcludeSemantics(
          child: FadeTransition(opacity: _opacity, child: widget.child),
        ),
      );
}

/// Loading placeholder for a list of cards: each row is a card-shaped block
/// with an avatar circle and two text lines, pulsing together.
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  /// Page bodies pass the list's own padding (usually `EdgeInsets.all(DT.s5)`).
  final EdgeInsetsGeometry padding;

  const SkeletonList({
    super.key,
    this.itemCount = 4,
    this.itemHeight = 72,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    return SkeletonPulse(
      // Clips instead of overflowing when the screen is shorter than the
      // placeholder rows.
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < itemCount; i++)
            Container(
              height: itemHeight,
              margin: const EdgeInsets.only(bottom: DT.s3),
              padding: const EdgeInsets.all(DT.s4),
              decoration: BoxDecoration(
                color: c.cardSurface,
                borderRadius: BorderRadius.circular(DT.rCard),
              ),
              child: const Row(
                children: [
                  SkeletonBox(width: 40, height: 40, radius: DT.rPill),
                  SizedBox(width: DT.s3),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FractionallySizedBox(
                          widthFactor: 0.7,
                          child: SkeletonBox(height: 14),
                        ),
                        SizedBox(height: DT.s2),
                        FractionallySizedBox(
                          widthFactor: 0.4,
                          child: SkeletonBox(height: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
        ),
      ),
    );
  }
}
