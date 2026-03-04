import 'package:signalr_netcore/signalr_client.dart';
import 'package:flutter_application_1/core/api/api_constants.dart';

class NotificationHubService {
  HubConnection? _connection;

  Future<void> connect(
    String accessToken, {
    required void Function(Map<String, dynamic>) onNotification,
  }) async {
    if (_connection?.state == HubConnectionState.Connected) return;

    _connection = HubConnectionBuilder()
        .withUrl(
          '${ApiConstants.baseUrl}${ApiConstants.notificationHub}',
          options: HttpConnectionOptions(
            accessTokenFactory: () async => accessToken,
            logMessageContent: false,
          ),
        )
        .withAutomaticReconnect()
        .build();

    _connection!.on('Notification', (args) {
      if (args != null && args.isNotEmpty && args[0] != null) {
        onNotification(Map<String, dynamic>.from(args[0] as Map));
      }
    });

    try {
      await _connection!.start();
    } catch (_) {
      // Non-fatal; polling fallback still works.
    }
  }

  Future<void> disconnect() async {
    try {
      await _connection?.stop();
    } catch (_) {}
    _connection = null;
  }
}
