import 'dart:async';

import 'package:signalr_netcore/signalr_client.dart';
import 'package:flutter_application_1/core/api/api_constants.dart';

class ChatHubService {
  HubConnection? _connection;

  final _messages = StreamController<Map<String, dynamic>>.broadcast();

  /// Broadcast stream of incoming hub messages. Multiple subscribers OK:
  /// the open thread's [ChatBloc] consumes one, and the app-level local
  /// notification handler consumes another.
  Stream<Map<String, dynamic>> get messages => _messages.stream;

  /// Legacy single-callback hook, kept for back-compat. Prefer [messages].
  void Function(Map<String, dynamic> message)? onMessageReceived;

  Future<void> connect(String accessToken) async {
    if (_connection?.state == HubConnectionState.Connected) return;

    _connection = HubConnectionBuilder()
        .withUrl(
          '${ApiConstants.baseUrl}${ApiConstants.chatHub}',
          options: HttpConnectionOptions(
            accessTokenFactory: () async => accessToken,
            logMessageContent: false,
          ),
        )
        .withAutomaticReconnect()
        .build();

    _connection!.on('ReceiveMessage', (args) {
      if (args != null && args.isNotEmpty && args[0] != null) {
        final data = Map<String, dynamic>.from(args[0] as Map);
        _messages.add(data);
        onMessageReceived?.call(data);
      }
    });

    try {
      await _connection!.start();
    } catch (_) {
      // Hub connection failure is non-fatal; REST fallback still works.
    }
  }

  Future<void> disconnect() async {
    try {
      await _connection?.stop();
    } catch (_) {}
    _connection = null;
  }

  bool get isConnected =>
      _connection?.state == HubConnectionState.Connected;
}
