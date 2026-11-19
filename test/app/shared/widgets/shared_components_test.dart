import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/design/dt_colors.dart';
import 'package:flutter_application_1/app/design/theme.dart';
import 'package:flutter_application_1/app/shared/widgets/app_bottom_sheet.dart';
import 'package:flutter_application_1/app/shared/widgets/buttons.dart';
import 'package:flutter_application_1/app/shared/widgets/dt_card.dart';
import 'package:flutter_application_1/app/shared/widgets/section_header.dart';
import 'package:flutter_application_1/app/shared/widgets/skeleton.dart';
import 'package:flutter_application_1/app/shared/widgets/stat_tile.dart';
import 'package:flutter_application_1/app/shared/widgets/user_avatar.dart';

Widget _host(Widget child, {bool dark = false}) => MaterialApp(
      theme: buildTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('DTCard', () {
    testWidgets('uses the card surface and responds to taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(
        DTCard(onTap: () => taps++, child: const Text('Kártya')),
        dark: true,
      ));
      final material = tester.widget<Material>(find
          .ancestor(of: find.text('Kártya'), matching: find.byType(Material))
          .first);
      expect(material.color, DTColors.dark.cardSurface);
      expect(material.clipBehavior, Clip.antiAlias);

      await tester.tap(find.text('Kártya'));
      expect(taps, 1);
    });

    testWidgets('without onTap there is no ink well', (tester) async {
      await tester.pumpWidget(_host(const DTCard(child: Text('Statikus'))));
      expect(find.byType(InkWell), findsNothing);
    });
  });

  group('SectionHeader', () {
    testWidgets('shows the title and an optional action', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(
          SectionHeader(title: 'Edzések', onAction: () => taps++)));
      expect(tester.widget<Text>(find.text('Edzések')).style?.fontSize, 18);
      await tester.tap(find.text('Összes'));
      expect(taps, 1);

      await tester.pumpWidget(_host(const SectionHeader(title: 'Edzések')));
      expect(find.text('Összes'), findsNothing);
    });
  });

  group('StatTile', () {
    testWidgets('card style colors the icon and reads as one label',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const StatTile(
        icon: Icons.local_fire_department,
        value: '5',
        label: 'Sorozat',
        color: Colors.deepOrange,
      )));
      expect(
          tester.widget<Icon>(find.byIcon(Icons.local_fire_department)).color,
          Colors.deepOrange);
      expect(find.bySemanticsLabel('Sorozat: 5'), findsOneWidget);
      expect(tester.widget<Text>(find.text('Sorozat')).style?.fontSize, 12);
      handle.dispose();
    });

    testWidgets('filled style uses the color as background', (tester) async {
      await tester.pumpWidget(_host(const StatTile.filled(
        icon: Icons.people,
        value: '12',
        label: 'Sportolók',
        color: Color(0xFFBBD2FF),
      )));
      final box = tester.widget<Container>(find
          .ancestor(of: find.text('12'), matching: find.byType(Container))
          .first);
      expect((box.decoration! as BoxDecoration).color, const Color(0xFFBBD2FF));
      expect(tester.widget<Icon>(find.byIcon(Icons.people)).color,
          DTColors.light.textPrimary);
    });
  });

  group('UserAvatar', () {
    test('initials', () {
      expect(UserAvatar.initialsFor('Kiss Anna'), 'KA');
      expect(UserAvatar.initialsFor('  ádám   marosvári  '), 'ÁM');
      expect(UserAvatar.initialsFor('anna'), 'A');
      expect(UserAvatar.initialsFor('Nagy Péter Pál'), 'NP');
      expect(UserAvatar.initialsFor(''), '?');
    });

    test('palette index is stable and case-insensitive', () {
      final a = UserAvatar.paletteIndex('Kiss Anna', 6);
      expect(UserAvatar.paletteIndex('Kiss Anna', 6), a);
      expect(UserAvatar.paletteIndex('kiss anna ', 6), a);
      expect(a, inInclusiveRange(0, 5));
      // Names sharing a first letter don't all get the same color.
      final colors = ['Anna', 'András', 'Attila', 'Ágnes', 'Albert', 'Ádám']
          .map((n) => UserAvatar.paletteIndex(n, 6))
          .toSet();
      expect(colors.length, greaterThan(1));
    });

    testWidgets('draws initials in the palette color', (tester) async {
      await tester.pumpWidget(_host(const UserAvatar(name: 'Kiss Anna')));
      final expected = DTColors.light
          .avatarPalette[UserAvatar.paletteIndex('Kiss Anna', 6)];
      expect(tester.widget<Text>(find.text('KA')).style?.color, expected);
    });
  });

  group('buttons', () {
    late List<MethodCall> platformCalls;

    setUp(() {
      platformCalls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        platformCalls.add(call);
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('PrimaryButton is 52 px, full width, and taps with haptics',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(
          PrimaryButton(label: 'Mentés', onPressed: () => taps++)));

      expect(tester.getSize(find.byType(PrimaryButton)).height, 52);
      expect(tester.getSize(find.byType(PrimaryButton)).width, 800);
      await tester.tap(find.text('Mentés'));
      expect(taps, 1);
      expect(platformCalls.map((c) => c.method),
          contains('HapticFeedback.vibrate'));
    });

    testWidgets('loading shows a spinner and ignores taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(PrimaryButton(
          label: 'Mentés', onPressed: () => taps++, isLoading: true)));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Mentés'), findsNothing);
      await tester.tap(find.byType(PrimaryButton));
      expect(taps, 0);
    });

    testWidgets('SecondaryButton can size to its label', (tester) async {
      await tester.pumpWidget(_host(SecondaryButton(
          label: 'Újra', onPressed: () {}, expand: false)));
      expect(tester.getSize(find.byType(SecondaryButton)).width,
          lessThan(800));
      expect(tester.getSize(find.byType(SecondaryButton)).height, 52);
    });
  });

  group('skeletons', () {
    testWidgets('SkeletonList pulses its card placeholders', (tester) async {
      await tester.pumpWidget(_host(const SkeletonList(itemCount: 3)));
      expect(find.byType(SkeletonBox), findsNWidgets(9));

      final fade = find.byType(FadeTransition).first;
      final start = tester.widget<FadeTransition>(fade).opacity.value;
      await tester.pump(const Duration(milliseconds: 450));
      expect(tester.widget<FadeTransition>(fade).opacity.value,
          isNot(start));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('holds still when animations are disabled', (tester) async {
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: _host(const SkeletonList(itemCount: 1)),
      ));
      final fade = find.byType(FadeTransition).first;
      expect(tester.widget<FadeTransition>(fade).opacity.value, 1);
      await tester.pump(const Duration(milliseconds: 450));
      expect(tester.widget<FadeTransition>(fade).opacity.value, 1);
    });
  });

  testWidgets('AppBottomSheet.show adds the handle and title',
      (tester) async {
    await tester.pumpWidget(_host(Builder(
      builder: (context) => TextButton(
        onPressed: () => AppBottomSheet.show<void>(
          context,
          title: 'Szűrők',
          builder: (_) => const Text('Tartalom'),
        ),
        child: const Text('Nyitás'),
      ),
    )));

    await tester.tap(find.text('Nyitás'));
    await tester.pumpAndSettle();
    expect(find.byType(SheetHandle), findsOneWidget);
    expect(find.text('Szűrők'), findsOneWidget);
    expect(find.text('Tartalom'), findsOneWidget);
  });
}
