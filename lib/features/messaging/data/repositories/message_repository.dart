import 'package:flutter_application_1/app/user_session.dart';
import 'package:flutter_application_1/core/api/api_client.dart';
import 'package:flutter_application_1/core/api/api_constants.dart';
import 'package:flutter_application_1/features/messaging/data/models/conversation_model.dart';
import 'package:flutter_application_1/features/messaging/data/models/message_model.dart';

class MessageRepository {
  final ApiClient _client;
  MessageRepository(this._client);

  String get _myUserId => UserSession.instance.userId ?? '';

  Future<List<ConversationModel>> getConversations() async {
    final res = await _client.dio.get(ApiConstants.conversations);
    final rawList = _toList(res.data);
    final list = rawList
        .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
        .toList();
    list.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    return list;
  }

  Future<List<MessageModel>> getThread(String otherId, {int page = 1}) async {
    final res = await _client.dio.get(
      ApiConstants.messageThread(otherId),
      queryParameters: {'page': page},
    );
    final rawList = _toList(res.data);
    return rawList.map((e) {
      final m = e as Map<String, dynamic>;
      return MessageModel(
        id: m['id']?.toString() ?? '',
        text: m['content']?.toString() ?? m['text']?.toString() ?? '',
        timestamp: DateTime.tryParse(m['createdAt']?.toString() ?? '') ??
            DateTime.tryParse(m['timestamp']?.toString() ?? '') ??
            DateTime.now(),
        isSentByMe: m['senderId']?.toString() == _myUserId,
      );
    }).toList();
  }

  /// Safely extracts a list from a raw Dio response body.
  /// Handles bare arrays, wrapper objects ({ "items": [...] }, etc.) and nulls.
  static List<dynamic> _toList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      for (final key in const ['items', 'messages', 'conversations', 'data']) {
        if (data[key] is List) return data[key] as List<dynamic>;
      }
    }
    return const [];
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
