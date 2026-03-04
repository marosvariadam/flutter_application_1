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

  factory ConversationModel.fromJson(Map<String, dynamic> json,
      {String? myUserId}) {
    final msgs = (json['messages'] as List?)
            ?.map((m) => MessageModel.fromJson(
                m as Map<String, dynamic>,
                myUserId: myUserId))
            .toList() ??
        [];
    return ConversationModel(
      id: json['id'] as String,
      contactName: json['contactName'] as String,
      contactAvatarUrl: json['contactAvatarUrl'] as String? ?? '',
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageTime: DateTime.parse(json['lastMessageTime'] as String),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      isOnline: json['isOnline'] as bool? ?? false,
      messages: msgs,
    );
  }

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
