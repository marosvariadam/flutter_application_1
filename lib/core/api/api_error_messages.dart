import 'package:dio/dio.dart';

/// Hungarian message for a failure that no typed repository exception
/// covered. Transport problems get a specific explanation; everything else
/// falls back to the caller's [fallback], so raw exception text never
/// reaches the UI.
String friendlyErrorMessage(Object error, {required String fallback}) {
  if (error is! DioException) return fallback;
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'A szerver nem válaszolt időben. Próbáld újra.';
    case DioExceptionType.connectionError:
      return 'Nincs internetkapcsolat, vagy a szerver nem érhető el.';
    case DioExceptionType.badResponse:
      final code = error.response?.statusCode ?? 0;
      if (code == 401) return 'Lejárt a bejelentkezés. Jelentkezz be újra.';
      if (code >= 500) {
        return 'A szerver most nem elérhető. Próbáld újra később.';
      }
      return fallback;
    default:
      return fallback;
  }
}
