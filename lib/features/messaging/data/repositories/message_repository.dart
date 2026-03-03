import 'package:flutter_application_1/core/api/api_client.dart';
import 'package:flutter_application_1/core/api/api_constants.dart';
import 'package:flutter_application_1/features/messaging/data/models/conversation_model.dart';
import 'package:flutter_application_1/features/messaging/data/models/message_model.dart';

class MessageRepository {
  final ApiClient _client;
  final String myUserId;

  MessageRepository(this._client, {required this.myUserId});

  Future<List<ConversationModel>> getConversations() async {
    final res = await _client.dio.get(ApiConstants.conversations);
    return (res.data as List)
        .map((e) =>
            ConversationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MessageModel>> getThread(String otherId, {int page = 1}) async {
    final res = await _client.dio.get(
      ApiConstants.messageThread(otherId),
      queryParameters: {'page': page},
    );
    return (res.data as List).map((e) {
      final m = e as Map<String, dynamic>;
      return MessageModel(
        id: m['id'] as String,
        text: m['content'] as String,
        timestamp: DateTime.parse(m['createdAt'] as String),
        isSentByMe: m['senderId'] as String == myUserId,
      );
    }).toList();
  }

  Future<void> sendMessage(String recipientId, String text) async {
    await _client.dio.post(
      ApiConstants.sendMessage(recipientId),
      data: {'content': text},
    );
  }

  Future<void> markRead(String otherId) async {
    await _client.dio.patch(ApiConstants.markRead(otherId));
  }
}
