class MessageModel {
  final String id;
  final String text;
  final DateTime timestamp;
  final bool isSentByMe;

  const MessageModel({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.isSentByMe,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, {String? myUserId}) {
    final senderId = json['senderId'] as String?;
    final isSentByMe = senderId != null && myUserId != null
        ? senderId == myUserId
        : (json['isSentByMe'] as bool? ?? false);
    return MessageModel(
      id: json['id'] as String,
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isSentByMe: isSentByMe,
    );
  }
}
