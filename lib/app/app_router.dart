import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/app/shared/widgets/widgets_nav/bottom_nav.dart';
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
import 'package:flutter_application_1/features/trainer/bloc/athlete_status_cubit.dart';
import 'package:flutter_application_1/features/trainer/presentation/athlete_requests_page.dart';
import 'package:flutter_application_1/features/trainer/presentation/athlete_waiting_page.dart';
import 'package:flutter_application_1/features/trainer/presentation/roster_page.dart';
import 'package:flutter_application_1/features/trainer/presentation/trainer_requests_page.dart';
import 'package:flutter_application_1/features/user/presentation/change_password_page.dart';
import 'package:flutter_application_1/features/user/presentation/edit_profile_page.dart';
import 'package:flutter_application_1/features/workout/presentation/workout_detail_page.dart';
import 'package:flutter_application_1/features/workout/presentation/workout_list_page.dart';

enum Approute { home, session, messages, profile, login, register }

/// Routes an athlete can visit while still in the onboarding gate.
const _athleteGateRoutes = {'/waiting', '/athlete-requests'};

GoRouter buildRouter(AuthBloc authBloc, AthleteStatusCubit athleteStatusCubit) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable:
        _CombinedListenable([authBloc.stream, athleteStatusCubit.stream]),
    redirect: (context, state) {
      final authState = authBloc.state;
      if (authState is AuthInitial) return null;

      final loc = state.matchedLocation;
      final isPublic = loc == '/login' || loc == '/register';

      if (authState is! AuthAuthenticated && !isPublic) return '/login';

      if (authState is AuthAuthenticated && isPublic) {
        if (authState.user.isAthlete) {
          return _athleteRedirect(athleteStatusCubit, loc);
        }
        return '/home';
      }

      // Authenticated athlete on an app route — enforce the gate.
      if (authState is AuthAuthenticated &&
          authState.user.isAthlete &&
          !_athleteGateRoutes.contains(loc)) {
        return _athleteRedirect(athleteStatusCubit, loc);
      }

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

      // ── Athlete onboarding gate ──────────────────────────────────────────────
      GoRoute(
        path: '/waiting',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: AthleteWaitingPage()),
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
        pageBuilder: (_, __) =>
            const MaterialPage(child: TrainerRequestsPage(isTrainer: true)),
      ),
      GoRoute(
        path: '/athlete-requests',
        pageBuilder: (_, __) =>
            const MaterialPage(child: AthleteRequestsPage()),
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
                      final name = state.extra as String?;
                      return MaterialPage(child: ChatPage(contactId: id, contactName: name));
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

/// Returns the redirect target for an authenticated athlete, or null if they
/// are already on the right screen.
String? _athleteRedirect(AthleteStatusCubit cubit, String currentLoc) {
  final status = cubit.state;

  // Still loading — send to waiting (which shows a spinner).
  if (status is AthleteStatusInitial || status is AthleteStatusLoading) {
    if (currentLoc != '/waiting') return '/waiting';
    return null;
  }

  if (status is AthleteStatusPending) {
    if (currentLoc != '/waiting') return '/waiting';
    return null;
  }

  if (status is AthleteStatusNeedsForm) {
    if (currentLoc != '/onboarding/survey') return '/onboarding/survey';
    return null;
  }

  // AthleteStatusReady — let the original navigation proceed.
  return null;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Makes GoRouter re-evaluate redirect whenever any of the given streams emit.
class _CombinedListenable extends ChangeNotifier {
  _CombinedListenable(List<Stream<dynamic>> streams) {
    for (final s in streams) {
      s.listen((_) => notifyListeners());
    }
  }
}
