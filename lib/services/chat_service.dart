import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  
  final String _hubUrl = "http://10.0.2.2:5233/chatHub"; 
  
  HubConnection? _hubConnection;
  final _storage = const FlutterSecureStorage();

  
  Function(dynamic)? onMessageReceived;

  Future<void> connect() async {
    final token = await _storage.read(key: 'jwt_token');
    
    if (token == null) {
      print("No token found. Cannot connect to chat.");
      return;
    }

    // connection with the Token
    _hubConnection = HubConnectionBuilder()
        .withUrl(
          _hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token, // Pass JWT here
          ),
        )
        .build();

    // 2. Listeners
    _hubConnection?.on("ReceiveMessage", _handleIncomingMessage);

    // 3. Start Connection
    try {
      await _hubConnection?.start();
      print("SignalR Connected!");
    } catch (e) {
      print("SignalR Connection Error: $e");
    }
  }

  void _handleIncomingMessage(List<dynamic>? args) {
    if (args != null && args.isNotEmpty) {
      final messageData = args[0];
      print("New Message: $messageData");
      
      // Notify the UI if a callback is registered
      if (onMessageReceived != null) {
        onMessageReceived!(messageData);
      }
    }
  }

  // Send a message to the Hub
  Future<void> sendMessage(String receiverId, String content) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      try {
        await _hubConnection?.invoke("SendMessage", args: [receiverId, content]);
      } catch (e) {
        print("Error sending message: $e");
      }
    } else {
      print("Cannot send. Chat is disconnected.");
    }
  }

  Future<List<dynamic>> getInbox() async {
    print("Inbox: Starting request..."); // Debug 1
    
    final token = await _storage.read(key: 'jwt_token');
    print("Inbox: Token found? ${token != null}"); // Debug 2

    final url = Uri.parse('http://10.0.2.2:5233/api/chat/inbox'); 
    print("Inbox: Calling URL $url"); // Debug 3

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      print("Inbox: Response ${response.statusCode}"); // Debug 4
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load inbox: ${response.statusCode}');
      }
    } catch (e) {
      print("Inbox Error: $e"); // Debug 5
      rethrow;
    }
  }

  Future<List<dynamic>> getInboxOld() async {
    final token = await _storage.read(key: 'jwt_token');
    // Note: Ensure this matches your backend HTTP port (e.g. 5233)
    final url = Uri.parse('http://10.0.2.2:5233/api/chat/inbox'); 

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load inbox');
    }
  }

  

  void disconnect() {
    _hubConnection?.stop();
  }
}