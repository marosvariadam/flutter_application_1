class NotificationModel {
  final String id;
  final String type;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.metadata,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> j) =>
      NotificationModel(
        id: j['id'] as String,
        type: j['type'] as String,
        message: j['message'] as String,
        isRead: j['isRead'] as bool? ?? false,
        createdAt: DateTime.parse(j['createdAt'] as String),
        metadata: j['metadata'] as Map<String, dynamic>?,
      );

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        type: type,
        message: message,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        metadata: metadata,
      );
}
