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
    dio.interceptors.add(_AuthInterceptor(onUnauthorized));
  }
}

typedef VoidCallback = void Function();

class _AuthInterceptor extends Interceptor {
  final VoidCallback? _onUnauthorized;
  _AuthInterceptor(this._onUnauthorized);

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
    if (err.response?.statusCode == 401) {
      // No refresh token — clear session and trigger logout.
      await TokenStorage.clearAll();
      _onUnauthorized?.call();
    }
    handler.next(err);
  }
}
