import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/notifications/bloc/notification_bloc.dart';
import 'package:flutter_application_1/features/notifications/data/models/notification_model.dart';
import 'package:flutter_application_1/app/design/dt_text.dart';
import 'package:flutter_application_1/app/shared/reload_and_wait.dart';
import 'package:flutter_application_1/app/shared/widgets/empty_state.dart';
import 'package:flutter_application_1/app/shared/widgets/error_state.dart';
import 'package:flutter_application_1/app/shared/widgets/fade_switcher.dart';
import 'package:flutter_application_1/app/shared/widgets/refreshable_fill.dart';
import 'package:flutter_application_1/app/shared/widgets/skeleton.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(LoadNotifications());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.of(context).bg,
      appBar: AppBar(
        backgroundColor: DT.of(context).bg,
        elevation: 0,
        leading: BackButton(color: DT.of(context).textPrimary),
        title: Text('Értesítések', style: DTText.of(context).title),
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
                  child: Text('Mind olvasott',
                      style: DTText.of(context)
                          .label
                          .copyWith(color: DT.of(context).accentPrimary)),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) =>
            FadeSwitcher(child: _body(context, state)),
      ),
    );
  }

  Widget _body(BuildContext context, NotificationState state) {
    final bloc = context.read<NotificationBloc>();
    Future<void> refresh() => reloadAndWait(
        bloc, () => bloc.add(LoadNotifications()),
        (s) => s is NotificationsLoaded || s is NotificationError);

    if (state is NotificationError) {
      return ErrorState(
        key: const ValueKey('error'),
        message: state.message,
        onRetry: () => bloc.add(LoadNotifications()),
      );
    }
    if (state is! NotificationsLoaded) {
      return const SkeletonList(
          key: ValueKey('loading'), padding: EdgeInsets.all(DT.s4));
    }
    if (state.notifications.isEmpty) {
      return RefreshIndicator(
        key: const ValueKey('empty'),
        onRefresh: refresh,
        child: const RefreshableFill(
          child: EmptyState(
            icon: Icons.notifications_none_outlined,
            title: 'Nincs értesítés',
            message: 'Itt jelennek meg a kérések és az új edzések.',
          ),
        ),
      );
    }
    return RefreshIndicator(
      key: const ValueKey('content'),
      onRefresh: refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(DT.s4),
        itemCount: state.notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: DT.s2),
        itemBuilder: (context, i) =>
            _NotificationTile(notification: state.notifications[i]),
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
          ? DT.of(context).cardSurface
          : DT.of(context).accentPrimary.withValues(alpha: 0.10),
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
                  decoration: BoxDecoration(
                    color: DT.of(context).accentPrimary,
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
      'trainerrequestreceived' => (Icons.person_add_outlined, DT.of(context).accentPrimary),
      'trainerrequestaccepted' => (Icons.check_circle, DT.of(context).accentSuccess),
      'trainerrequestrejected' => (Icons.cancel, DT.of(context).accentDanger),
      'onboardingformavailable' =>
        (Icons.assignment_outlined, DT.of(context).accentPrimary),
      'workoutassigned' =>
        (Icons.fitness_center, DT.of(context).accentOrange),
      _ => (Icons.notifications, DT.of(context).iconLight),
    };
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}
