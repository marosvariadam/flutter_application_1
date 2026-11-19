import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/design/dt_text.dart';

/// Shared `fl_chart` styling so every line chart reads the same: primary
/// line with a 15 % gradient fill, caption-size axis labels, horizontal
/// grid only, tooltips on the elevated surface.
class DTChart {
  const DTChart._();

  /// Axis label style (caption, the app's smallest size).
  static TextStyle axisLabel(BuildContext context) =>
      DTText.of(context).caption;

  /// Reserved axis space that grows with the system font size, so larger
  /// labels don't get clipped.
  static double reserved(BuildContext context, double base) =>
      MediaQuery.textScalerOf(context).scale(base);

  /// fl_chart always labels the axis min/max, even when they fall between
  /// two interval steps (e.g. 157 right above 155), and those labels
  /// collide. True for such an off-step edge value: skip its label.
  static bool isOffStepEdge(double value, TitleMeta meta) {
    if (value != meta.min && value != meta.max) return false;
    final rest = value % meta.appliedInterval;
    return rest > 1e-6 && meta.appliedInterval - rest > 1e-6;
  }

  static FlGridData grid(BuildContext context) {
    final line = DT.of(context).borderLight;
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (_) => FlLine(color: line, strokeWidth: 1),
    );
  }

  /// Area under a line: [color] at 15 % fading to transparent.
  static BarAreaData gradientFill(Color color) => BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0),
          ],
        ),
      );

  /// Filled dots ringed in the card color.
  static FlDotData dots(BuildContext context, Color color,
      {double radius = 3}) {
    final ring = DT.of(context).cardSurface;
    return FlDotData(
      show: true,
      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
        radius: radius,
        color: color,
        strokeColor: ring,
        strokeWidth: 1.5,
      ),
    );
  }

  /// Tooltip box: elevated surface, hairline border, rounded like small
  /// cards, kept inside the chart.
  static LineTouchTooltipData tooltip(
    BuildContext context, {
    required GetLineTooltipItems getTooltipItems,
    double maxContentWidth = 160,
  }) {
    final c = DT.of(context);
    return LineTouchTooltipData(
      getTooltipColor: (_) => c.cardSurfaceElevated,
      tooltipBorder: BorderSide(color: c.borderGrey),
      tooltipRoundedRadius: DT.rCardSmall,
      tooltipPadding:
          const EdgeInsets.symmetric(horizontal: DT.s3, vertical: DT.s2),
      maxContentWidth: maxContentWidth,
      fitInsideHorizontally: true,
      fitInsideVertically: true,
      getTooltipItems: getTooltipItems,
    );
  }

  /// Text inside a tooltip, in the series' color.
  static TextStyle tooltipText(BuildContext context, Color color) =>
      DTText.of(context)
          .caption
          .copyWith(color: color, fontWeight: FontWeight.w600);
}
