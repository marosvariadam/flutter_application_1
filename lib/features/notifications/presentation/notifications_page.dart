import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/notifications/bloc/notification_bloc.dart';
import 'package:flutter_application_1/features/notifications/data/models/notification_model.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.of(context).bg,
      appBar: AppBar(
        backgroundColor: DT.of(context).bg,
        elevation: 0,
        leading: BackButton(color: DT.of(context).textPrimary),
        title: Text('Értesítések',
            style: TextStyle(
                color: DT.of(context).textPrimary, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state is NotificationsLoaded &&
                  state.unreadCount > 0) {
                return TextButton(
                  onPressed: () => context
                      .read<NotificationBloc>()
                      .add(MarkAllNotificationsRead()),
                  child: const Text('Mind olvasott',
                      style: TextStyle(
                          color: DT.metricBlue, fontSize: DT.s3)),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationInitial) {
            context
                .read<NotificationBloc>()
                .add(LoadNotifications());
            return const Center(child: CircularProgressIndicator());
          }
          if (state is NotificationError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: DT.cardRed),
                  const SizedBox(height: DT.s4),
                  Text(state.message,
                      style: TextStyle(
                          color: DT.of(context).textSecondary)),
                  const SizedBox(height: DT.s4),
                  ElevatedButton(
                    onPressed: () => context
                        .read<NotificationBloc>()
                        .add(LoadNotifications()),
                    child: const Text('Újra'),
                  ),
                ],
              ),
            );
          }
          if (state is NotificationsLoaded) {
            if (state.notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none_outlined,
                        size: 64, color: DT.of(context).iconLightGrey),
                    const SizedBox(height: DT.s4),
                    Text('Nincs értesítés.',
                        style: TextStyle(
                            color: DT.of(context).textSecondary, fontSize: DT.s4)),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(DT.s4),
              itemCount: state.notifications.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: DT.s2),
              itemBuilder: (context, i) {
                final notif = state.notifications[i];
                return _NotificationTile(notification: notif);
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: notification.isRead
          ? DT.gbWhite
          : DT.metricBlue.withOpacity(0.08),
      borderRadius: BorderRadius.circular(DT.rCardSmall),
      child: InkWell(
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        onTap: notification.isRead
            ? null
            : () => context
                .read<NotificationBloc>()
                .add(MarkNotificationRead(notification.id)),
        child: Padding(
          padding: const EdgeInsets.all(DT.s4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotificationIcon(type: notification.type),
              const SizedBox(width: DT.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notification.message,
                        style: TextStyle(
                            color: DT.of(context).textPrimary,
                            fontSize: DT.s3,
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.w600)),
                    const SizedBox(height: DT.s1),
                    Text(
                      _formatTime(notification.createdAt),
                      style: TextStyle(
                          color: DT.of(context).textSecondary,
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    color: DT.metricBlue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Most';
    if (diff.inHours < 1) return '${diff.inMinutes} perce';
    if (diff.inDays < 1) return '${diff.inHours} órája';
    if (diff.inDays < 7) return '${diff.inDays} napja';
    return DateFormat('yyyy.MM.dd').format(dt);
  }
}

class _NotificationIcon extends StatelessWidget {
  final String type;
  const _NotificationIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type.toLowerCase()) {
      'trainerrequestaccepted' => (Icons.check_circle, Colors.green),
      'trainerrequestrejected' => (Icons.cancel, DT.cardRed),
      'onboardingformavailable' =>
        (Icons.assignment_outlined, DT.metricBlue),
      'workoutassigned' =>
        (Icons.fitness_center, DT.cardOrange),
      _ => (Icons.notifications, DT.of(context).iconLight),
    };
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}
