import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/app/app_router.dart';
import 'package:flutter_application_1/app/bloc/theme_cubit.dart';
import 'package:flutter_application_1/app/design/theme.dart';
import 'package:flutter_application_1/app/user_session.dart';
import 'package:flutter_application_1/core/api/api_client.dart';
import 'package:flutter_application_1/core/notifications/local_notification_service.dart';
import 'package:flutter_application_1/core/storage/token_storage.dart';
import 'package:flutter_application_1/features/auth/bloc/auth_bloc.dart';
import 'package:flutter_application_1/features/auth/data/repositories/auth_repository.dart';
import 'package:flutter_application_1/features/exercise/bloc/exercise_bloc.dart';
import 'package:flutter_application_1/features/exercise/data/repositories/exercise_repository.dart';
import 'package:flutter_application_1/features/messaging/bloc/chat_bloc.dart';
import 'package:flutter_application_1/features/messaging/bloc/messaging_bloc.dart';
import 'package:flutter_application_1/features/messaging/data/repositories/message_repository.dart';
import 'package:flutter_application_1/features/messaging/services/chat_hub_service.dart';
import 'package:flutter_application_1/features/notifications/bloc/notification_bloc.dart';
import 'package:flutter_application_1/features/notifications/data/repositories/notification_repository.dart';
import 'package:flutter_application_1/features/notifications/services/notification_hub_service.dart';
import 'package:flutter_application_1/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:flutter_application_1/features/onboarding/data/repositories/onboarding_repository.dart';
import 'package:flutter_application_1/features/trainer/bloc/athlete_status_cubit.dart';
import 'package:flutter_application_1/features/trainer/bloc/roster_bloc.dart';
import 'package:flutter_application_1/features/trainer/bloc/trainer_request_bloc.dart';
import 'package:flutter_application_1/features/trainer/data/repositories/roster_repository.dart';
import 'package:flutter_application_1/features/trainer/data/repositories/trainer_request_repository.dart';
import 'package:flutter_application_1/features/user/data/repositories/user_repository.dart';
import 'package:flutter_application_1/features/exercise_stats/bloc/exercise_stats_cubit.dart';
import 'package:flutter_application_1/features/exercise_stats/data/repositories/exercise_stats_repository.dart';
import 'package:flutter_application_1/features/prediction/bloc/prediction_cubit.dart';
import 'package:flutter_application_1/features/prediction/data/repositories/prediction_repository.dart';
import 'package:flutter_application_1/features/training_block/bloc/training_block_bloc.dart';
import 'package:flutter_application_1/features/training_block/data/repositories/training_block_repository.dart';
import 'package:flutter_application_1/features/workout/bloc/workout_bloc.dart';
import 'package:flutter_application_1/features/workout/data/repositories/workout_repository.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final ThemeCubit _themeCubit;
  late final AuthBloc _authBloc;
  late final ApiClient _apiClient;
  late final NotificationHubService _notifHub;
  late final ChatHubService _chatHub;

  late final AuthRepository _authRepo;
  late final UserRepository _userRepo;
  late final RosterRepository _rosterRepo;
  late final TrainerRequestRepository _trainerRequestRepo;
  late final WorkoutRepository _workoutRepo;
  late final ExerciseRepository _exerciseRepo;
  late final NotificationRepository _notifRepo;
  late final OnboardingRepository _onboardingRepo;
  late final MessageRepository _messageRepo;
  late final ExerciseStatsRepository _exerciseStatsRepo;
  late final PredictionRepository _predictionRepo;
  late final TrainingBlockRepository _trainingBlockRepo;
  late final AthleteStatusCubit _athleteStatusCubit;

  StreamSubscription<Map<String, dynamic>>? _chatHubNotifSub;

  @override
  void initState() {
    super.initState();

    _themeCubit = ThemeCubit()..load();

    _notifHub = NotificationHubService();
    _chatHub = ChatHubService();

    // Boot local notifications and subscribe the chat hub to fire a
    // notification for any incoming message. We dedupe vs. the open thread
    // inside the listener (see `_shouldShowChatNotification`).
    LocalNotificationService.instance.init();
    _chatHubNotifSub = _chatHub.messages.listen(_onIncomingChatMessage);

    _apiClient = ApiClient(onUnauthorized: () {
      _authBloc.add(LogoutRequested());
    });

    _authRepo = AuthRepository(_apiClient);
    _userRepo = UserRepository(_apiClient);
    _rosterRepo = RosterRepository(_apiClient);
    _trainerRequestRepo = TrainerRequestRepository(_apiClient);
    _workoutRepo = WorkoutRepository(_apiClient);
    _exerciseRepo = ExerciseRepository(_apiClient);
    _notifRepo = NotificationRepository(_apiClient);
    _onboardingRepo = OnboardingRepository(_apiClient);
    _messageRepo = MessageRepository(_apiClient);
    _exerciseStatsRepo = ExerciseStatsRepository(_apiClient);
    _predictionRepo = PredictionRepository(_apiClient);
    _trainingBlockRepo = TrainingBlockRepository(_apiClient);

    _authBloc = AuthBloc(authRepo: _authRepo, userRepo: _userRepo);
    _athleteStatusCubit =
        AthleteStatusCubit(_trainerRequestRepo, _onboardingRepo);
    _authBloc.add(AppStarted());
  }

  @override
  void dispose() {
    _chatHubNotifSub?.cancel();
    _themeCubit.close();
    _authBloc.close();
    _athleteStatusCubit.close();
    _notifHub.disconnect();
    _chatHub.disconnect();
    super.dispose();
  }

  /// The current chat-thread route (`/messages/:id`) if the user is on it.
  /// We don't fire a notification for the conversation the user is actively
  /// reading.
  String? _openChatId;

  /// Human-friendly title for a backend notification payload. Falls back to a
  /// generic word if the type is unknown.
  String _notifTitleFor(Map<String, dynamic> data) {
    final type = (data['type'] as String?)?.toLowerCase();
    switch (type) {
      case 'workout_assigned':
      case 'workoutassigned':
        return 'Új edzés';
      case 'trainer_request_accepted':
      case 'trainerrequestaccepted':
        return 'Edzői kérés elfogadva';
      case 'trainer_request_rejected':
      case 'trainerrequestrejected':
        return 'Edzői kérés elutasítva';
      default:
        return 'Új értesítés';
    }
  }

  void _onIncomingChatMessage(Map<String, dynamic> data) {
    final senderId = (data['senderId'] ?? data['fromUserId']) as String?;
    final senderName =
        (data['senderName'] ?? data['fromUserName']) as String? ?? 'Üzenet';
    final body = (data['content'] ?? data['text']) as String? ?? '';
    if (senderId == null || senderId.isEmpty) return;
    if (_openChatId == senderId) return; // user is reading this thread
    LocalNotificationService.instance.showChat(
      contactId: senderId,
      contactName: senderName,
      body: body,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _authRepo),
        RepositoryProvider.value(value: _userRepo),
        RepositoryProvider.value(value: _rosterRepo),
        RepositoryProvider.value(value: _trainerRequestRepo),
        RepositoryProvider.value(value: _workoutRepo),
        RepositoryProvider.value(value: _exerciseRepo),
        RepositoryProvider.value(value: _notifRepo),
        RepositoryProvider.value(value: _onboardingRepo),
        RepositoryProvider.value(value: _exerciseStatsRepo),
        RepositoryProvider.value(value: _predictionRepo),
        RepositoryProvider.value(value: _trainingBlockRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _themeCubit),
          BlocProvider.value(value: _authBloc),
          BlocProvider.value(value: _athleteStatusCubit),
          BlocProvider(
            create: (_) => NotificationBloc(_notifRepo),
          ),
          BlocProvider(create: (_) => MessagingBloc(repo: _messageRepo)),
          BlocProvider(
            create: (_) => ChatBloc(repo: _messageRepo, hub: _chatHub),
          ),
          BlocProvider(create: (_) => RosterBloc(_rosterRepo)),
          BlocProvider(
              create: (_) => TrainerRequestBloc(_trainerRequestRepo)),
          BlocProvider(create: (_) => WorkoutBloc(_workoutRepo)),
          BlocProvider(create: (_) => ExerciseBloc(_exerciseRepo)),
          BlocProvider(create: (_) => OnboardingBloc(_onboardingRepo)),
          BlocProvider(create: (_) => ExerciseStatsCubit(_exerciseStatsRepo)),
          BlocProvider(create: (_) => PredictionCubit(_predictionRepo)),
          BlocProvider(create: (_) => TrainingBlockBloc(_trainingBlockRepo)),
        ],
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) async {
            if (state is AuthAuthenticated) {
              UserSession.instance.set(
                role: state.user.role,
                userId: state.user.id,
                firstName: state.user.firstName,
                lastName: state.user.lastName,
                email: state.user.email,
              );
              // Kick off the athlete onboarding gate check.
              if (state.user.isAthlete) {
                _athleteStatusCubit.check();
              }
              final token = await TokenStorage.getAccessToken();
              if (token != null) {
                await _notifHub.connect(
                  token,
                  onNotification: (data) {
                    // Update the in-app notification bell / list.
                    context
                        .read<NotificationBloc>()
                        .add(NotificationReceived(data));
                    // Fire an OS notification banner.
                    LocalNotificationService.instance.showGeneric(
                      title: _notifTitleFor(data),
                      body: (data['message'] as String?) ?? '',
                      notificationId: data['id'] as String?,
                    );
                  },
                );
                await _chatHub.connect(token);
              }
            } else if (state is AuthUnauthenticated) {
              UserSession.instance.clear();
              _athleteStatusCubit.reset();
              await _notifHub.disconnect();
              await _chatHub.disconnect();
              // Clear scheduled reminders so they don't fire after logout.
              await LocalNotificationService.instance.cancelAll();
            }
          },
          child: _RouterWrapper(
            authBloc: _authBloc,
            athleteStatusCubit: _athleteStatusCubit,
            onOpenChatIdChanged: (id) => _openChatId = id,
          ),
        ),
      ),
    );
  }
}

class _RouterWrapper extends StatefulWidget {
  final AuthBloc authBloc;
  final AthleteStatusCubit athleteStatusCubit;
  /// Called whenever the router lands on (or leaves) `/messages/:id` so we
  /// can suppress chat notifications for the currently-open conversation.
  final ValueChanged<String?> onOpenChatIdChanged;

  const _RouterWrapper({
    required this.authBloc,
    required this.athleteStatusCubit,
    required this.onOpenChatIdChanged,
  });

  @override
  State<_RouterWrapper> createState() => _RouterWrapperState();
}

class _RouterWrapperState extends State<_RouterWrapper> {
  late final _router =
      buildRouter(widget.authBloc, widget.athleteStatusCubit);

  StreamSubscription<NotificationTap>? _tapSub;

  @override
  void initState() {
    super.initState();
    _tapSub = LocalNotificationService.instance.taps.listen(_handleTap);
    _router.routerDelegate.addListener(_onRouteChanged);
  }

  @override
  void dispose() {
    _tapSub?.cancel();
    _router.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    // Re-evaluate which chat thread (if any) is currently open.
    final loc = _router.routerDelegate.currentConfiguration.uri.toString();
    final m = RegExp(r'^/messages/([^/?#]+)').firstMatch(loc);
    widget.onOpenChatIdChanged(m?.group(1));
  }

  void _handleTap(NotificationTap tap) {
    switch (tap.type) {
      case 'chat':
        final id = tap.contactId;
        if (id != null) {
          _router.go('/messages/$id', extra: tap.contactName);
        }
        break;
      case 'workout':
        final id = tap.workoutId;
        if (id != null) {
          _router.push('/workout-detail', extra: id);
        }
        break;
      case 'generic':
      default:
        _router.go(tap.deepLink ?? '/notifications');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (_, __) => _router.refresh(),
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) => MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: themeMode,
          routerConfig: _router,
        ),
      ),
    );
  }
}
