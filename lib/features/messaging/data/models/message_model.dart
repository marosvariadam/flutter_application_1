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

  factory MessageModel.fromJson(
      Map<String, dynamic> j, String myUserId) =>
      MessageModel(
        id: j['id'] as String,
        text: j['content'] as String? ?? j['text'] as String? ?? '',
        timestamp: DateTime.parse(
            j['createdAt'] as String? ?? j['timestamp'] as String),
        isSentByMe: (j['senderId'] as String?) == myUserId,
      );
}
