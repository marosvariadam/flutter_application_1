import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/features/notifications/data/models/notification_model.dart';
import 'package:flutter_application_1/features/notifications/data/repositories/notification_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class NotificationEvent {}

class LoadNotifications extends NotificationEvent {}

class MarkNotificationRead extends NotificationEvent {
  final String id;
  MarkNotificationRead(this.id);
}

class MarkAllNotificationsRead extends NotificationEvent {}

/// Fired by NotificationHubService when a real-time notification arrives.
class NotificationReceived extends NotificationEvent {
  final Map<String, dynamic> data;
  NotificationReceived(this.data);
}

// ── States ────────────────────────────────────────────────────────────────────
abstract class NotificationState {}

class NotificationInitial extends NotificationState {}

class NotificationsLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  NotificationsLoaded(this.notifications)
      : unreadCount = notifications.where((n) => !n.isRead).length;
}

class NotificationError extends NotificationState {
  final String message;
  NotificationError(this.message);
}

// ── BLoC ──────────────────────────────────────────────────────────────────────
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _repo;
  List<NotificationModel> _notifications = [];

  NotificationBloc(this._repo) : super(NotificationInitial()) {
    on<LoadNotifications>(_onLoad);
    on<MarkNotificationRead>(_onMarkRead);
    on<MarkAllNotificationsRead>(_onMarkAllRead);
    on<NotificationReceived>(_onReceived);
  }

  Future<void> _onLoad(
      LoadNotifications event, Emitter<NotificationState> emit) async {
    try {
      _notifications = await _repo.getNotifications();
      emit(NotificationsLoaded(List.from(_notifications)));
    } catch (_) {
      emit(NotificationError('Nem sikerült betölteni az értesítéseket.'));
    }
  }

  Future<void> _onMarkRead(
      MarkNotificationRead event, Emitter<NotificationState> emit) async {
    try {
      await _repo.markRead(event.id);
      _notifications = _notifications
          .map((n) => n.id == event.id ? n.copyWith(isRead: true) : n)
          .toList();
      emit(NotificationsLoaded(List.from(_notifications)));
    } catch (_) {}
  }

  Future<void> _onMarkAllRead(
      MarkAllNotificationsRead event,
      Emitter<NotificationState> emit) async {
    try {
      await _repo.markAllRead();
      _notifications =
          _notifications.map((n) => n.copyWith(isRead: true)).toList();
      emit(NotificationsLoaded(List.from(_notifications)));
    } catch (_) {}
  }

  void _onReceived(
      NotificationReceived event, Emitter<NotificationState> emit) {
    try {
      final newNotif = NotificationModel.fromJson(event.data);
      _notifications = [newNotif, ..._notifications];
      emit(NotificationsLoaded(List.from(_notifications)));
    } catch (_) {}
  }
}
