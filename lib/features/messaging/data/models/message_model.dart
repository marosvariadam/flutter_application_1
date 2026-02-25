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
}
