import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/app/design/theme.dart';
import 'package:flutter_application_1/app/bloc/theme_cubit.dart';
import 'package:flutter_application_1/app/user_session.dart';
import 'package:flutter_application_1/features/athlete_profile/bloc/athlete_profile_cubit.dart';
import 'package:flutter_application_1/features/athlete_profile/data/repositories/athlete_profile_repository.dart';
import 'package:flutter_application_1/features/auth/bloc/auth_bloc.dart';
import 'package:flutter_application_1/features/auth/data/repositories/auth_repository.dart';
import 'package:flutter_application_1/features/autoregulation/data/repositories/autoregulation_repository.dart';
import 'package:flutter_application_1/features/exercise/bloc/exercise_bloc.dart';
import 'package:flutter_application_1/features/exercise/data/repositories/exercise_repository.dart';
import 'package:flutter_application_1/features/exercise_stats/bloc/exercise_stats_cubit.dart';
import 'package:flutter_application_1/features/exercise_stats/data/repositories/exercise_stats_repository.dart';
import 'package:flutter_application_1/features/messaging/bloc/chat_bloc.dart';
import 'package:flutter_application_1/features/messaging/bloc/messaging_bloc.dart';
import 'package:flutter_application_1/features/messaging/data/repositories/message_repository.dart';
import 'package:flutter_application_1/features/notifications/bloc/notification_bloc.dart';
import 'package:flutter_application_1/features/notifications/data/repositories/notification_repository.dart';
import 'package:flutter_application_1/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:flutter_application_1/features/onboarding/data/repositories/onboarding_repository.dart';
import 'package:flutter_application_1/features/prediction/bloc/prediction_cubit.dart';
import 'package:flutter_application_1/features/prediction/data/repositories/prediction_repository.dart';
import 'package:flutter_application_1/features/trainer/bloc/athlete_status_cubit.dart';
import 'package:flutter_application_1/features/trainer/bloc/roster_bloc.dart';
import 'package:flutter_application_1/features/trainer/bloc/trainer_request_bloc.dart';
import 'package:flutter_application_1/features/trainer/data/repositories/roster_repository.dart';
import 'package:flutter_application_1/features/trainer/data/repositories/trainer_request_repository.dart';
import 'package:flutter_application_1/features/training_block/bloc/training_block_bloc.dart';
import 'package:flutter_application_1/features/training_block/data/repositories/training_block_repository.dart';
import 'package:flutter_application_1/features/training_plan/data/repositories/training_plan_repository.dart';
import 'package:flutter_application_1/features/user/data/models/user_model.dart';
import 'package:flutter_application_1/features/user/data/repositories/user_repository.dart';
import 'package:flutter_application_1/features/workout/bloc/workout_bloc.dart';
import 'package:flutter_application_1/features/workout/data/repositories/workout_repository.dart';

import '../helpers/fake_http.dart';
import 'page_fixtures.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class _MockStatusCubit extends MockCubit<AthleteStatusState>
    implements AthleteStatusCubit {}

enum Role { trainer, athlete, guest }

/// Registers the Flutter SDK's Roboto as the test font. The default test
/// font draws every glyph as a 1 em square — about 1.8× wider than Roboto —
/// so overflow checks would fail on text that fits on a real phone. Falls
/// back to that (stricter) font when the SDK files aren't found.
Future<void> loadRealFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return;
  final dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return;
  final loader = FontLoader('Roboto');
  for (final weight in ['light', 'regular', 'medium', 'bold', 'black']) {
    final file = File('${dir.path}/roboto-$weight.ttf');
    if (file.existsSync()) {
      final bytes = file.readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
  }
  await loader.load();
}

/// Pumps [page] the way the app hosts it: every repository (real code over a
/// fake HTTP backend serving [fixtureApi]), the app-level blocs, a GoRouter
/// and the app theme. Small phone (360 × 740) unless [size] says otherwise.
Future<void> pumpAppPage(
  WidgetTester tester,
  Widget page, {
  required Role role,
  bool dark = false,
  double textScale = 1.3,
  Size size = const Size(360, 740),
  AthleteStatusState? status,
  List<RouteBase>? routes,
  String initialLocation = '/',
  FakeHttpAdapter? adapter,
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = size * 2;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final userId = role == Role.trainer ? 't1' : 'a1';
  FlutterSecureStorage.setMockInitialValues({'user_id': userId});
  if (role == Role.guest) {
    UserSession.instance.clear();
  } else {
    UserSession.instance.set(
      role: role == Role.trainer ? 'Trainer' : 'Athlete',
      userId: userId,
      firstName: role == Role.trainer ? 'Bence' : 'Annamária',
      lastName: role == Role.trainer ? 'Kovács' : 'Szabó-Kiss',
      email: '$userId@example.com',
    );
  }

  final api = fakeApiClient(adapter ?? FakeHttpAdapter(fixtureApi));
  final auth = _MockAuthBloc();
  whenListen(
    auth,
    const Stream<AuthState>.empty(),
    initialState: role == Role.guest
        ? AuthUnauthenticated()
        : AuthAuthenticated(UserModel(
            id: userId,
            firstName: role == Role.trainer ? 'Bence' : 'Annamária',
            lastName: role == Role.trainer ? 'Kovács' : 'Szabó-Kiss',
            email: '$userId@example.com',
            role: role == Role.trainer ? 'Trainer' : 'Athlete',
          )),
  );
  final statusCubit = _MockStatusCubit();
  whenListen(statusCubit, const Stream<AthleteStatusState>.empty(),
      initialState: status ?? AthleteStatusPending());

  final rosterRepo = RosterRepository(api);
  final requestRepo = TrainerRequestRepository(api);
  final workoutRepo = WorkoutRepository(api);
  final exerciseRepo = ExerciseRepository(api);
  final notifRepo = NotificationRepository(api);
  final onboardingRepo = OnboardingRepository(api);
  final messageRepo = MessageRepository(api);
  final statsRepo = ExerciseStatsRepository(api);
  final predictionRepo = PredictionRepository(api);
  final blockRepo = TrainingBlockRepository(api);
  final planRepo = TrainingPlanRepository(api);
  final autoregRepo = AutoregulationRepository(api);
  final profileRepo = AthleteProfileRepository(api);

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: routes ?? [GoRoute(path: '/', builder: (_, __) => page)],
  );

  await tester.pumpWidget(MultiRepositoryProvider(
    providers: [
      RepositoryProvider.value(value: AuthRepository(api)),
      RepositoryProvider.value(value: UserRepository(api)),
      RepositoryProvider.value(value: rosterRepo),
      RepositoryProvider.value(value: requestRepo),
      RepositoryProvider.value(value: workoutRepo),
      RepositoryProvider.value(value: exerciseRepo),
      RepositoryProvider.value(value: notifRepo),
      RepositoryProvider.value(value: onboardingRepo),
      RepositoryProvider.value(value: statsRepo),
      RepositoryProvider.value(value: predictionRepo),
      RepositoryProvider.value(value: blockRepo),
      RepositoryProvider.value(value: planRepo),
      RepositoryProvider.value(value: autoregRepo),
      RepositoryProvider.value(value: profileRepo),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider<AuthBloc>.value(value: auth),
        BlocProvider<AthleteStatusCubit>.value(value: statusCubit),
        BlocProvider(create: (_) => NotificationBloc(notifRepo)),
        BlocProvider(create: (_) => MessagingBloc(repo: messageRepo)),
        BlocProvider(create: (_) => ChatBloc(repo: messageRepo)),
        BlocProvider(create: (_) => RosterBloc(rosterRepo)),
        BlocProvider(create: (_) => TrainerRequestBloc(requestRepo)),
        BlocProvider(create: (_) => WorkoutBloc(workoutRepo)),
        BlocProvider(create: (_) => ExerciseBloc(exerciseRepo)),
        BlocProvider(create: (_) => OnboardingBloc(onboardingRepo)),
        BlocProvider(create: (_) => ExerciseStatsCubit(statsRepo)),
        BlocProvider(create: (_) => PredictionCubit(predictionRepo)),
        BlocProvider(create: (_) => TrainingBlockBloc(blockRepo)),
        BlocProvider(create: (_) => AthleteProfileCubit(profileRepo)),
      ],
      child: MaterialApp.router(
        theme: buildTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        routerConfig: router,
      ),
    ),
  ));
  await settleData(tester);
}

/// Lets the fake requests resolve and the cross-fades finish without
/// waiting on endless animations (skeleton pulse, waiting-page pulse).
Future<void> settleData(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

/// Unmounts the page so pending timers are cancelled before the test ends.
Future<void> unmountPage(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}
