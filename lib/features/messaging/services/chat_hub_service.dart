import 'package:signalr_netcore/signalr_client.dart';
import 'package:flutter_application_1/core/api/api_constants.dart';

class ChatHubService {
  HubConnection? _connection;

  /// Called when a new message arrives on the open thread.
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
        onMessageReceived?.call(
            Map<String, dynamic>.from(args[0] as Map));
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
