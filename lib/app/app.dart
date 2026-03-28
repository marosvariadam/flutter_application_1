import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/app/app_router.dart';
import 'package:flutter_application_1/app/bloc/theme_cubit.dart';
import 'package:flutter_application_1/app/design/theme.dart';
import 'package:flutter_application_1/app/user_session.dart';
import 'package:flutter_application_1/core/api/api_client.dart';
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
  late final AthleteStatusCubit _athleteStatusCubit;

  @override
  void initState() {
    super.initState();

    _themeCubit = ThemeCubit()..load();

    _notifHub = NotificationHubService();
    _chatHub = ChatHubService();

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

    _authBloc = AuthBloc(authRepo: _authRepo, userRepo: _userRepo);
    _athleteStatusCubit =
        AthleteStatusCubit(_trainerRequestRepo, _onboardingRepo);
    _authBloc.add(AppStarted());
  }

  @override
  void dispose() {
    _themeCubit.close();
    _authBloc.close();
    _athleteStatusCubit.close();
    _notifHub.disconnect();
    _chatHub.disconnect();
    super.dispose();
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
                    context
                        .read<NotificationBloc>()
                        .add(NotificationReceived(data));
                  },
                );
                await _chatHub.connect(token);
              }
            } else if (state is AuthUnauthenticated) {
              UserSession.instance.clear();
              _athleteStatusCubit.reset();
              await _notifHub.disconnect();
              await _chatHub.disconnect();
            }
          },
          child: _RouterWrapper(
            authBloc: _authBloc,
            athleteStatusCubit: _athleteStatusCubit,
          ),
        ),
      ),
    );
  }
}

class _RouterWrapper extends StatefulWidget {
  final AuthBloc authBloc;
  final AthleteStatusCubit athleteStatusCubit;
  const _RouterWrapper({
    required this.authBloc,
    required this.athleteStatusCubit,
  });

  @override
  State<_RouterWrapper> createState() => _RouterWrapperState();
}

class _RouterWrapperState extends State<_RouterWrapper> {
  late final _router =
      buildRouter(widget.authBloc, widget.athleteStatusCubit);

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
