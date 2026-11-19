import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/design/dt_colors.dart';
import 'package:flutter_application_1/app/design/dt_text.dart';
import 'package:flutter_application_1/app/design/theme.dart';
import 'package:flutter_application_1/app/shared/chart_style.dart';
import 'package:flutter_application_1/app/shared/greeting.dart';
import 'package:flutter_application_1/app/shared/reload_and_wait.dart';
import 'package:flutter_application_1/app/shared/widgets/empty_state.dart';
import 'package:flutter_application_1/app/shared/widgets/fade_switcher.dart';
import 'package:flutter_application_1/app/shared/widgets/progress_ring.dart';
import 'package:flutter_application_1/app/shared/widgets/refreshable_fill.dart';
import 'package:flutter_application_1/app/shared/widgets/skeleton.dart';

Widget _host(Widget child, {bool dark = false}) => MaterialApp(
      theme: buildTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(body: child),
    );

class _Counter extends Cubit<int> {
  _Counter() : super(0);
  void bump() => emit(state + 1);
}

void main() {
  group('timeOfDayGreeting', () {
    test('morning, day and evening', () {
      String at(int h) => timeOfDayGreeting(DateTime(2026, 11, 19, h));
      expect(at(5), 'Jó reggelt');
      expect(at(9), 'Jó reggelt');
      expect(at(10), 'Szép napot');
      expect(at(17), 'Szép napot');
      expect(at(18), 'Jó estét');
      expect(at(23), 'Jó estét');
      expect(at(3), 'Jó estét');
    });
  });

  group('FadeSwitcher', () {
    testWidgets('cross-fades to the new child over DT.normal',
        (tester) async {
      Widget body(String key) =>
          FadeSwitcher(child: Text(key, key: ValueKey(key)));
      await tester.pumpWidget(_host(body('loading')));
      await tester.pumpWidget(_host(body('content')));
      await tester.pump();
      // Both visible mid-fade.
      expect(find.text('loading'), findsOneWidget);
      expect(find.text('content'), findsOneWidget);
      await tester.pump(DT.normal);
      await tester.pump(DT.normal);
      expect(find.text('loading'), findsNothing);
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('switches at once when animations are disabled',
        (tester) async {
      Widget body(String key) => MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: _host(FadeSwitcher(child: Text(key, key: ValueKey(key)))),
          );
      await tester.pumpWidget(body('loading'));
      await tester.pumpWidget(body('content'));
      await tester.pump();
      expect(find.text('loading'), findsNothing);
    });
  });

  group('ProgressRing', () {
    for (final dark in [false, true]) {
      final c = dark ? DTColors.dark : DTColors.light;
      testWidgets('partial progress in the primary color (dark: $dark)',
          (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(_host(
            const Center(
                child: ProgressRing(done: 2, total: 5, unit: 'gyakorlat')),
            dark: dark));
        final ring = tester.widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator));
        expect(ring.value, 0.4);
        expect(ring.color, c.accentPrimary);
        expect(find.text('2/5'), findsOneWidget);
        expect(find.bySemanticsLabel('2 / 5 gyakorlat kész'), findsOneWidget);
        handle.dispose();
      });

      testWidgets('complete shows a green check (dark: $dark)',
          (tester) async {
        await tester.pumpWidget(_host(
            const Center(child: ProgressRing(done: 3, total: 3)),
            dark: dark));
        expect(
            tester
                .widget<CircularProgressIndicator>(
                    find.byType(CircularProgressIndicator))
                .color,
            c.accentSuccess);
        expect(tester.widget<Icon>(find.byIcon(Icons.check)).color,
            c.accentSuccess);
        expect(find.text('3/3'), findsNothing);
      });
    }

    test('value is clamped and safe for empty workouts', () {
      expect(const ProgressRing(done: 0, total: 0).value, 0);
      expect(const ProgressRing(done: 0, total: 0).isComplete, isFalse);
      expect(const ProgressRing(done: 7, total: 5).value, 1);
    });
  });

  testWidgets('RefreshableFill centers its child and stays pullable',
      (tester) async {
    var refreshes = 0;
    await tester.pumpWidget(_host(RefreshIndicator(
      onRefresh: () async => refreshes++,
      child: const RefreshableFill(
        child: EmptyState(icon: Icons.inbox_outlined, title: 'Üres'),
      ),
    )));
    final center = tester.getCenter(find.text('Üres'));
    expect(center.dy, closeTo(300, 80)); // middle of the 600 px test screen

    await tester.fling(find.text('Üres'), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();
    expect(refreshes, 1);
  });

  testWidgets('SkeletonList applies its padding and clips on short screens',
      (tester) async {
    await tester.pumpWidget(_host(const SizedBox(
      height: 200,
      child: SkeletonList(itemCount: 6, padding: EdgeInsets.all(DT.s5)),
    )));
    // 6 × 84 px rows in 200 px: no overflow error, first row inset.
    expect(tester.takeException(), isNull);
    final first = tester.getTopLeft(find.byType(SkeletonBox).first);
    expect(first.dx, greaterThanOrEqualTo(DT.s5));
    await tester.pumpWidget(const SizedBox());
  });

  group('reloadAndWait', () {
    test('completes once the bloc settles', () async {
      final bloc = _Counter();
      await reloadAndWait(bloc, bloc.bump, (s) => s == 1);
      expect(bloc.state, 1);
      await bloc.close();
    });

    test('gives up after the timeout when nothing is emitted', () async {
      final bloc = _Counter();
      await reloadAndWait(bloc, () {}, (s) => s == 1,
          timeout: const Duration(milliseconds: 20));
      expect(bloc.state, 0);
      await bloc.close();
    });
  });

  group('DTChart', () {
    testWidgets('caption labels, elevated tooltip, 15 % gradient',
        (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(_host(Builder(builder: (context) {
        ctx = context;
        return const SizedBox();
      }), dark: true));
      const c = DTColors.dark;

      expect(DTChart.axisLabel(ctx), DTText.of(ctx).caption);
      final tooltip = DTChart.tooltip(ctx, getTooltipItems: (_) => []);
      expect(tooltip.getTooltipColor(LineBarSpot(
          LineChartBarData(), 0, const FlSpot(0, 0))), c.cardSurfaceElevated);
      expect(tooltip.tooltipBorder.color, c.borderGrey);

      final fill = DTChart.gradientFill(c.accentPrimary);
      expect(fill.show, isTrue);
      expect(fill.gradient!.colors.first,
          c.accentPrimary.withValues(alpha: 0.15));
      expect(fill.gradient!.colors.last.a, 0);
    });

    test('skips axis edge labels that fall between two steps', () {
      TitleMeta meta(double min, double max, double interval) => TitleMeta(
            min: min,
            max: max,
            parentAxisSize: 300,
            axisPosition: 0,
            appliedInterval: interval,
            sideTitles: const SideTitles(),
            formattedValue: '',
            axisSide: AxisSide.left,
            rotationQuarterTurns: 0,
          );
      // y: 115 … 155 every 5, max 157 would sit on top of 155.
      expect(DTChart.isOffStepEdge(157, meta(115, 157, 5)), isTrue);
      expect(DTChart.isOffStepEdge(115, meta(115, 157, 5)), isFalse);
      expect(DTChart.isOffStepEdge(155, meta(115, 157, 5)), isFalse);
      // x: indices every 2, last index 13 next to 12.
      expect(DTChart.isOffStepEdge(13, meta(0, 13, 2)), isTrue);
      expect(DTChart.isOffStepEdge(12, meta(0, 12, 2)), isFalse);
    });

    testWidgets('reserved axis space grows with the font size',
        (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: Builder(builder: (context) {
          ctx = context;
          return const SizedBox();
        }),
      ));
      expect(DTChart.reserved(ctx, 40), closeTo(52, 0.01));
    });
  });
}
