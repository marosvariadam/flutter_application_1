import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/app/shared/widgets/widgets_nav/bottom_nav.dart';
import 'package:flutter_application_1/app/user_session.dart';
import 'package:flutter_application_1/features/auth/bloc/auth_bloc.dart';
import 'package:flutter_application_1/features/auth/presentation/register_page.dart';
import 'package:flutter_application_1/features/coach/presentation/athlete_detail_page.dart';
import 'package:flutter_application_1/features/coach/presentation/workout_builder_page.dart';
import 'package:flutter_application_1/features/home/presantation/home_page.dart';
import 'package:flutter_application_1/features/login/login_page.dart';
import 'package:flutter_application_1/features/messaging/presentation/chat_page.dart';
import 'package:flutter_application_1/features/messaging/presentation/messaging_page.dart';
import 'package:flutter_application_1/features/notifications/presentation/notifications_page.dart';
import 'package:flutter_application_1/features/onboarding/presentation/athlete_survey_page.dart';
import 'package:flutter_application_1/features/onboarding/presentation/trainer_form_builder_page.dart';
import 'package:flutter_application_1/features/onboarding/presentation/trainer_responses_page.dart';
import 'package:flutter_application_1/features/profiles/presentation/profiles_page.dart';
import 'package:flutter_application_1/features/session/presentation/session_page.dart';
import 'package:flutter_application_1/features/trainer/presentation/roster_page.dart';
import 'package:flutter_application_1/features/trainer/presentation/trainer_requests_page.dart';
import 'package:flutter_application_1/features/user/presentation/change_password_page.dart';
import 'package:flutter_application_1/features/user/presentation/edit_profile_page.dart';
import 'package:flutter_application_1/features/workout/presentation/workout_detail_page.dart';
import 'package:flutter_application_1/features/workout/presentation/workout_list_page.dart';

enum Approute { home, session, messages, profile, login, register }

GoRouter buildRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _AuthBlocListenable(authBloc),
    redirect: (context, state) {
      final authState = authBloc.state;
      if (authState is AuthInitial) return null;

      final isAuthenticated = authState is AuthAuthenticated;
      final isPublic = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isAuthenticated && !isPublic) return '/login';
      if (isAuthenticated && isPublic) return '/home';
      return null;
    },
    routes: [
      // ── Auth ────────────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: LoginPage()),
      ),
      GoRoute(
        path: '/register',
        name: Approute.register.name,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: RegisterPage()),
      ),
      // ── Profile sub-routes ───────────────────────────────────────────────────
      GoRoute(
        path: '/profile/edit',
        pageBuilder: (_, __) =>
            const MaterialPage(child: EditProfilePage()),
      ),
      GoRoute(
        path: '/profile/change-password',
        pageBuilder: (_, __) =>
            const MaterialPage(child: ChangePasswordPage()),
      ),

      // ── Onboarding ───────────────────────────────────────────────────────────
      GoRoute(
        path: '/onboarding/form-builder',
        pageBuilder: (_, __) =>
            const MaterialPage(child: TrainerFormBuilderPage()),
      ),
      GoRoute(
        path: '/onboarding/responses',
        pageBuilder: (_, __) =>
            const MaterialPage(child: TrainerResponsesPage()),
      ),
      GoRoute(
        path: '/onboarding/survey',
        pageBuilder: (_, __) =>
            const MaterialPage(child: AthleteSurveyPage()),
      ),

      // ── Trainer tools ────────────────────────────────────────────────────────
      GoRoute(
        path: '/roster',
        pageBuilder: (_, __) => const MaterialPage(child: RosterPage()),
      ),
      GoRoute(
        path: '/trainer-requests',
        pageBuilder: (context, _) {
          final authState = authBloc.state;
          final isTrainer = authState is AuthAuthenticated &&
              authState.user.isTrainer;
          return MaterialPage(
              child: TrainerRequestsPage(isTrainer: isTrainer));
        },
      ),

      // ── Notifications ────────────────────────────────────────────────────────
      GoRoute(
        path: '/notifications',
        pageBuilder: (_, __) =>
            const MaterialPage(child: NotificationsPage()),
      ),

      // ── Full-screen routes (outside shell) ──────────────────────────────────
      GoRoute(
        path: '/workout-detail',
        pageBuilder: (context, state) {
          final workoutId = state.extra as String;
          return MaterialPage(child: WorkoutDetailPage(workoutId: workoutId));
        },
      ),
      GoRoute(
        path: '/athlete-detail/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return MaterialPage(child: AthleteDetailPage(athleteId: id));
        },
      ),
      GoRoute(
        path: '/workout-builder',
        pageBuilder: (context, state) {
          final athleteId = state.extra as String?;
          return MaterialPage(
            child: WorkoutBuilderPage(preselectedAthleteId: athleteId),
          );
        },
      ),

      // ── Main shell with bottom nav ───────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            BottomNavScaffold(shell: shell),
        branches: [
          // Tab 0 — Home (athlete) / Overview (coach)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: HomePage()),
              ),
            ],
          ),
          // Tab 1 — Sessions (athlete) / Athletes (coach)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/session',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: SessionsPage()),
                routes: [
                  GoRoute(
                    path: 'workouts',
                    pageBuilder: (_, __) =>
                        const NoTransitionPage(child: WorkoutsHubPage()),
                  ),
                ],
              ),
            ],
          ),
          // Tab 2 — Messages
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/messages',
                name: Approute.messages.name,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: MessagingPage()),
                routes: [
                  GoRoute(
                    path: ':id',
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return MaterialPage(child: ChatPage(contactId: id));
                    },
                  ),
                ],
              ),
            ],
          ),
          // Tab 3 — Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: ProfilesPage()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Makes GoRouter re-evaluate redirect on every AuthBloc state change.
class _AuthBlocListenable extends ChangeNotifier {
  _AuthBlocListenable(AuthBloc bloc) {
    bloc.stream.listen((_) => notifyListeners());
  }
}
