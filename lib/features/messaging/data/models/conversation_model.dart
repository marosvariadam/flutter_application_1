import 'package:flutter_application_1/features/messaging/data/models/message_model.dart';

class ConversationModel {
  final String id;
  final String contactName;
  final String contactAvatarUrl;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final List<MessageModel> messages;

  const ConversationModel({
    required this.id,
    required this.contactName,
    required this.contactAvatarUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.isOnline,
    required this.messages,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> j) =>
      ConversationModel(
        id: j['partnerId'] as String? ?? j['id'] as String,
        contactName:
            j['partnerName'] as String? ?? j['contactName'] as String? ?? '',
        contactAvatarUrl: j['partnerAvatarUrl'] as String? ?? '',
        lastMessage: j['lastMessage'] as String? ?? '',
        lastMessageTime: j['lastMessageAt'] != null
            ? DateTime.parse(j['lastMessageAt'] as String)
            : DateTime.now(),
        unreadCount: j['unreadCount'] as int? ?? 0,
        isOnline: false,
        messages: const [],
      );

  ConversationModel copyWith({List<MessageModel>? messages, int? unreadCount}) {
    return ConversationModel(
      id: id,
      contactName: contactName,
      contactAvatarUrl: contactAvatarUrl,
      lastMessage: messages != null && messages.isNotEmpty
          ? messages.last.text
          : lastMessage,
      lastMessageTime: messages != null && messages.isNotEmpty
          ? messages.last.timestamp
          : lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline,
      messages: messages ?? this.messages,
    );
  }
}
