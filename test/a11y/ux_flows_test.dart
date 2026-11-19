// P4/P5 behaviour on real pages: pull-to-refresh reloads lists, the athlete
// home header, the bottom nav's tap targets and labels, and that every
// icon-only control has a screen-reader label.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:flutter_application_1/app/shared/widgets/user_avatar.dart';
import 'package:flutter_application_1/app/shared/widgets/widgets_nav/bottom_nav.dart';
import 'package:flutter_application_1/features/coach/presentation/athletes_page.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/home_header.dart';
import 'package:flutter_application_1/features/messaging/presentation/chat_page.dart';
import 'package:flutter_application_1/features/notifications/presentation/notifications_page.dart';
import 'package:flutter_application_1/features/trainer/presentation/roster_page.dart';
import 'package:flutter_application_1/features/trainer/presentation/trainer_requests_page.dart';
import 'package:flutter_application_1/features/workout/presentation/workout_detail_page.dart';

import '../helpers/fake_http.dart';
import 'page_fixtures.dart';
import 'page_harness.dart';

int _gets(FakeHttpAdapter a, String path) =>
    a.requests.where((r) => r.method == 'GET' && r.path == path).length;

Future<void> _pullToRefresh(WidgetTester tester) async {
  await tester.fling(
      find.byType(Scrollable).last, const Offset(0, 400), 1200);
  await tester.pump();
  await settleData(tester);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('hu');
    await loadRealFonts();
  });

  group('pull-to-refresh reloads the list', () {
    final cases = <(String, Widget Function(), String)>[
      ('Értesítések', () => const NotificationsPage(), '/api/notification'),
      ('Atlétáim', () => const AthletesPage(),
          '/api/user/trainer/t1/athletes'),
      ('Sportolók', () => const RosterPage(), '/api/user/trainer/t1/athletes'),
      ('Csatlakozási kérések', () => const TrainerRequestsPage(),
          '/api/trainer-request/pending'),
    ];
    for (final (name, build, path) in cases) {
      testWidgets(name, (tester) async {
        final api = FakeHttpAdapter(fixtureApi);
        await pumpAppPage(tester, build(),
            role: Role.trainer, textScale: 1, adapter: api);
        final before = _gets(api, path);
        expect(before, greaterThan(0));
        expect(find.byType(RefreshIndicator), findsWidgets);

        await _pullToRefresh(tester);
        expect(_gets(api, path), before + 1);
      });
    }
  });

  testWidgets('athlete home header: avatar initials, no dead search button',
      (tester) async {
    await pumpAppPage(
      tester,
      Scaffold(
        appBar: AppBar(
          toolbarHeight: 80,
          title: HomeHeader(now: () => DateTime(2026, 11, 19, 8)),
        ),
      ),
      role: Role.athlete,
      textScale: 1,
    );
    expect(find.text('Jó reggelt, Annamária!'), findsOneWidget);
    expect(find.byType(UserAvatar), findsOneWidget);
    expect(find.text('AS'), findsOneWidget); // Annamária Szabó-Kiss
    expect(find.byIcon(Icons.search), findsNothing);
    expect(find.byTooltip('Profil'), findsOneWidget);
  });

  testWidgets('bottom nav: 44 px targets, caption-size labels, selection',
      (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    final handle = tester.ensureSemantics();

    await pumpAppPage(
      tester,
      const SizedBox(),
      role: Role.athlete,
      textScale: 1,
      initialLocation: '/a',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, __, shell) => BottomNavScaffold(shell: shell),
          branches: [
            for (final path in ['/a', '/b', '/c', '/d'])
              StatefulShellBranch(routes: [
                GoRoute(
                    path: path,
                    builder: (_, __) => Scaffold(body: Text('page $path'))),
              ]),
          ],
        ),
      ],
    );

    for (final label in ['Kezdőlap', 'Edzés', 'Üzenetek', 'Profil']) {
      final item = find.ancestor(
          of: find.text(label), matching: find.byType(InkWell));
      expect(tester.getSize(item).height, greaterThanOrEqualTo(44), reason: label);
      expect(tester.widget<Text>(find.text(label)).style?.fontSize ?? 12,
          greaterThanOrEqualTo(12), reason: label);
    }
    expect(
        tester.getSemantics(find.bySemanticsLabel('Kezdőlap')),
        matchesSemantics(
            label: 'Kezdőlap',
            isButton: true,
            hasSelectedState: true,
            isSelected: true,
            hasTapAction: true));

    await tester.tap(find.text('Üzenetek'));
    await settleData(tester);
    expect(find.text('page /c'), findsOneWidget);
    expect(calls.map((c) => c.arguments),
        contains('HapticFeedbackType.selectionClick'));
    handle.dispose();
  });

  group('icon-only controls have a screen-reader label', () {
    final cases = <(String, Role, Widget Function())>[
      ('Chat', Role.trainer,
          () => const ChatPage(contactId: 'a1', contactName: 'Szabó-Kiss Annamária')),
      ('Edzés (edző)', Role.trainer,
          () => const WorkoutDetailPage(workoutId: 'w-next')),
      ('Edzés – folyamatban', Role.athlete,
          () => const WorkoutDetailPage(workoutId: 'w-today')),
    ];
    for (final (name, role, build) in cases) {
      testWidgets(name, (tester) async {
        final handle = tester.ensureSemantics();
        await pumpAppPage(tester, build(), role: role, textScale: 1);
        for (final button in tester.widgetList<IconButton>(
            find.byType(IconButton))) {
          expect(button.tooltip, isNotNull,
              reason: 'IconButton(${button.icon}) on $name');
        }
        handle.dispose();
      });
    }
  });
}
