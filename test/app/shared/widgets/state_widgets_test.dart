import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/design/dt_colors.dart';
import 'package:flutter_application_1/app/design/theme.dart';
import 'package:flutter_application_1/app/shared/widgets/empty_state.dart';
import 'package:flutter_application_1/app/shared/widgets/error_state.dart';

Widget _host(Widget child, {required bool dark}) => MaterialApp(
      theme: buildTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(body: child),
    );

/// Fill color of the 64 px circle behind the state icon.
Color _circleColor(WidgetTester tester, IconData icon) {
  final box = tester.widget<Container>(find
      .ancestor(of: find.byIcon(icon), matching: find.byType(Container))
      .first);
  return (box.decoration! as BoxDecoration).color!;
}

DioException _dio(DioExceptionType type, {int? status}) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: type,
      response: status == null
          ? null
          : Response(
              requestOptions: RequestOptions(path: '/x'), statusCode: status),
    );

void main() {
  for (final dark in [false, true]) {
    final theme = dark ? 'dark' : 'light';
    final palette = dark ? DTColors.dark : DTColors.light;

    group('EmptyState ($theme)', () {
      testWidgets('icon on primarySoft, title, message and action',
          (tester) async {
        var taps = 0;
        await tester.pumpWidget(_host(
          EmptyState(
            icon: Icons.event_note,
            title: 'Nincs adat',
            message: 'Később visszanézhetsz.',
            actionLabel: 'Frissítés',
            onAction: () => taps++,
          ),
          dark: dark,
        ));

        expect(find.text('Nincs adat'), findsOneWidget);
        expect(find.text('Később visszanézhetsz.'), findsOneWidget);
        expect(_circleColor(tester, Icons.event_note), palette.primarySoft);
        expect(tester.widget<Icon>(find.byIcon(Icons.event_note)).color,
            palette.accentPrimary);
        expect(tester.widget<Text>(find.text('Nincs adat')).style?.color,
            palette.textPrimary);

        await tester.tap(find.text('Frissítés'));
        expect(taps, 1);
      });

      testWidgets('without an action there is no button', (tester) async {
        await tester.pumpWidget(_host(
          const EmptyState(icon: Icons.inbox, title: 'Üres'),
          dark: dark,
        ));
        expect(find.byType(OutlinedButton), findsNothing);
      });
    });

    group('ErrorState ($theme)', () {
      testWidgets('message, danger colors and a retry', (tester) async {
        var retries = 0;
        await tester.pumpWidget(_host(
          ErrorState(message: 'Nem sikerült.', onRetry: () => retries++),
          dark: dark,
        ));

        expect(find.text('Hiba történt'), findsOneWidget);
        expect(find.text('Nem sikerült.'), findsOneWidget);
        expect(_circleColor(tester, Icons.error_outline), palette.dangerSoft);
        expect(tester.widget<Icon>(find.byIcon(Icons.error_outline)).color,
            palette.accentDanger);

        await tester.tap(find.text('Újra'));
        expect(retries, 1);
      });

      testWidgets('no retry button without a callback', (tester) async {
        await tester.pumpWidget(_host(
          const ErrorState(message: 'Nincs jogosultság.'),
          dark: dark,
        ));
        expect(find.text('Újra'), findsNothing);
      });
    });
  }

  group('ErrorState maps errors to Hungarian', () {
    final cases = <String, Object>{
      'Nincs internetkapcsolat, vagy a szerver nem érhető el.':
          _dio(DioExceptionType.connectionError),
      'A szerver nem válaszolt időben. Próbáld újra.':
          _dio(DioExceptionType.receiveTimeout),
      'Nincs jogosultságod ehhez a művelethez.':
          _dio(DioExceptionType.badResponse, status: 403),
      'A szerver most nem elérhető. Próbáld újra később.':
          _dio(DioExceptionType.badResponse, status: 503),
      'Lejárt a bejelentkezés. Jelentkezz be újra.':
          _dio(DioExceptionType.badResponse, status: 401),
    };
    cases.forEach((expected, error) {
      testWidgets(expected, (tester) async {
        await tester.pumpWidget(_host(ErrorState(error: error), dark: false));
        expect(find.text(expected), findsOneWidget);
      });
    });

    testWidgets('never shows the raw exception text', (tester) async {
      await tester.pumpWidget(_host(
        ErrorState(error: Exception('SocketException: secret host 10.0.2.2')),
        dark: false,
      ));
      expect(find.text(ErrorState.fallbackMessage), findsOneWidget);
      expect(find.textContaining('SocketException'), findsNothing);
      expect(find.textContaining('10.0.2.2'), findsNothing);
    });

    testWidgets('an explicit message wins over the error', (tester) async {
      await tester.pumpWidget(_host(
        ErrorState(
            error: _dio(DioExceptionType.connectionError),
            message: 'Saját üzenet.'),
        dark: false,
      ));
      expect(find.text('Saját üzenet.'), findsOneWidget);
    });
  });
}
