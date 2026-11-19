import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/api/api_error_messages.dart';

DioException _dio(DioExceptionType type, {int? status}) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: type,
      response: status == null
          ? null
          : Response(
              requestOptions: RequestOptions(path: '/x'), statusCode: status),
    );

void main() {
  const fallback = 'Valami hiba.';

  test('timeouts explain that the server was slow', () {
    for (final t in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    ]) {
      expect(friendlyErrorMessage(_dio(t), fallback: fallback),
          'A szerver nem válaszolt időben. Próbáld újra.');
    }
  });

  test('connection errors mention the network', () {
    expect(
      friendlyErrorMessage(_dio(DioExceptionType.connectionError),
          fallback: fallback),
      'Nincs internetkapcsolat, vagy a szerver nem érhető el.',
    );
  });

  test('403 says the user is not allowed', () {
    expect(
      friendlyErrorMessage(_dio(DioExceptionType.badResponse, status: 403),
          fallback: fallback),
      'Nincs jogosultságod ehhez a művelethez.',
    );
  });

  test('5xx and 401 responses get their own copy', () {
    expect(
      friendlyErrorMessage(_dio(DioExceptionType.badResponse, status: 503),
          fallback: fallback),
      'A szerver most nem elérhető. Próbáld újra később.',
    );
    expect(
      friendlyErrorMessage(_dio(DioExceptionType.badResponse, status: 401),
          fallback: fallback),
      'Lejárt a bejelentkezés. Jelentkezz be újra.',
    );
  });

  test('other responses and non-Dio errors use the fallback', () {
    expect(
      friendlyErrorMessage(_dio(DioExceptionType.badResponse, status: 418),
          fallback: fallback),
      fallback,
    );
    expect(friendlyErrorMessage(_dio(DioExceptionType.cancel),
        fallback: fallback), fallback);
    expect(friendlyErrorMessage(Exception('boom'), fallback: fallback),
        fallback);
    expect(friendlyErrorMessage(StateError('x'), fallback: fallback),
        fallback);
  });
}
