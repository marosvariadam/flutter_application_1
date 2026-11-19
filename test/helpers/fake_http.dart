import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/api/api_client.dart';

/// Canned HTTP answer for [FakeHttpAdapter].
class FakeResponse {
  final int status;
  final Object? body;
  const FakeResponse(this.status, [this.body]);
}

/// Dio adapter that records every request and answers from [handler], so
/// repository tests run the real ApiClient/Dio stack without a network.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeResponse Function(RequestOptions request) handler;
  final List<RequestOptions> requests = [];

  FakeHttpAdapter([FakeResponse Function(RequestOptions)? handler])
      : handler = handler ?? ((_) => const FakeResponse(200));

  RequestOptions get last => requests.last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final r = handler(options);
    return ResponseBody.fromString(
      r.body == null ? '' : jsonEncode(r.body),
      r.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Real [ApiClient] wired to [adapter]. The auth interceptor is dropped
/// because it reads the token from platform secure storage.
ApiClient fakeApiClient(FakeHttpAdapter adapter) {
  final client = ApiClient();
  client.dio.interceptors.clear();
  client.dio.httpClientAdapter = adapter;
  return client;
}
