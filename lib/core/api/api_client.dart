import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/api/api_constants.dart';
import 'package:flutter_application_1/core/storage/token_storage.dart';

class ApiClient {
  late final Dio dio;
  final VoidCallback? onUnauthorized;

  ApiClient({this.onUnauthorized}) {
    dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    dio.interceptors.add(_AuthInterceptor(dio, onUnauthorized));
  }
}

typedef VoidCallback = void Function();

// ── Auth interceptor ───────────────────────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  final VoidCallback? _onUnauthorized;

  // A separate Dio instance without interceptors for the refresh call.
  final Dio _rawDio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    headers: {'Content-Type': 'application/json'},
  ));

  _AuthInterceptor(this._dio, this._onUnauthorized);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await TokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // Try token refresh
    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken == null) throw Exception('No refresh token');

      final res = await _rawDio.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      final newAccess = res.data['accessToken'] as String;
      final newRefresh = res.data['refreshToken'] as String? ?? refreshToken;
      await TokenStorage.saveTokens(newAccess, newRefresh);

      // Retry original request
      final opts = err.requestOptions;
      opts.headers['Authorization'] = 'Bearer $newAccess';
      final retryRes = await _dio.fetch(opts);
      handler.resolve(retryRes);
    } catch (_) {
      await TokenStorage.clearAll();
      _onUnauthorized?.call();
      handler.next(err);
    }
  }
}
