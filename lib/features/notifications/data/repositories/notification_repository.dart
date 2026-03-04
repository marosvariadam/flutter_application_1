import 'package:flutter_application_1/core/api/api_client.dart';
import 'package:flutter_application_1/core/api/api_constants.dart';
import 'package:flutter_application_1/features/notifications/data/models/notification_model.dart';

class NotificationRepository {
  final ApiClient _client;
  NotificationRepository(this._client);

  Future<List<NotificationModel>> getNotifications() async {
    final res = await _client.dio.get(ApiConstants.notifications);
    return (res.data as List)
        .map((e) =>
            NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final res = await _client.dio.get(ApiConstants.unreadCount);
    return res.data['count'] as int? ?? 0;
  }

  Future<void> markRead(String id) async {
    await _client.dio.patch(ApiConstants.markNotifRead(id));
  }

  Future<void> markAllRead() async {
    await _client.dio.patch(ApiConstants.markAllRead);
  }
}
