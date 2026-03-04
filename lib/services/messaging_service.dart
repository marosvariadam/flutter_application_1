import 'dart:convert';
import 'package:flutter_application_1/app/user_session.dart';
import 'package:flutter_application_1/features/messaging/data/models/conversation_model.dart';
import 'package:flutter_application_1/features/messaging/data/models/message_model.dart';
import 'package:flutter_application_1/services/api_client.dart';

class MessagingService {
  final _api = ApiClient.instance;

  Future<List<ConversationModel>> getConversations() async {
    try {
      final response = await _api.get('/messages/conversations');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body) as List;
        final myId = UserSession.instance.userId;
        return data
            .map((j) => ConversationModel.fromJson(
                j as Map<String, dynamic>,
                myUserId: myId))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<ConversationModel?> getConversation(String id) async {
    try {
      final response = await _api.get('/messages/conversations/$id');
      if (response.statusCode == 200) {
        return ConversationModel.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>,
            myUserId: UserSession.instance.userId);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> sendMessage(String conversationId, String text) async {
    try {
      final response = await _api.post('/messages', {
        'conversationId': conversationId,
        'text': text,
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
