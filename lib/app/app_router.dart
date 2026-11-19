import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/app/shared/widgets/widgets_nav/bottom_nav.dart';
import 'package:flutter_application_1/features/auth/bloc/auth_bloc.dart';
import 'package:flutter_application_1/features/register/register_page.dart';
import 'package:flutter_application_1/features/coach/presentation/athlete_detail_page.dart';
import 'package:flutter_application_1/features/coach/presentation/workout_builder_page.dart';
import 'package:flutter_application_1/features/home/presentation/home_page.dart';
import 'package:flutter_application_1/features/login/login_page.dart';
import 'package:flutter_application_1/features/messaging/presentation/chat_page.dart';
import 'package:flutter_application_1/features/messaging/presentation/messaging_page.dart';
import 'package:flutter_application_1/features/notifications/presentation/notifications_page.dart';
import 'package:flutter_application_1/features/onboarding/presentation/athlete_survey_page.dart';
import 'package:flutter_application_1/features/register/athlete_profile_survey_page.dart';
import 'package:flutter_application_1/features/training_plan/data/models/training_plan_model.dart';
import 'package:flutter_application_1/features/training_plan/presentation/my_plan_page.dart';
import 'package:flutter_application_1/features/training_plan/presentation/plan_editor_page.dart';
import 'package:flutter_application_1/features/training_plan/presentation/plan_generate_page.dart';
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
import 'package:flutter_application_1/features/exercise_stats/presentation/exercise_stats_page.dart';
import 'package:flutter_application_1/features/prediction/presentation/prediction_page.dart';
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
      // The profile survey runs after register, before login - treat it as
      // public so the push from the register page doesn't bounce to /login.
      final isPublic = loc == '/login' ||
          loc == '/register' ||
          loc == '/profile-survey';

      if (authState is! AuthAuthenticated && !isPublic) return '/login';

      if (authState is AuthAuthenticated && isPublic) {
        if (authState.user.isAthlete) {
          return _athleteRedirect(athleteStatusCubit, loc);
        }
        return '/home';
      }

      // Authenticated athlete on an app route - enforce the gate.
      if (authState is AuthAuthenticated &&
          authState.user.isAthlete &&
          !_athleteGateRoutes.contains(loc)) {
        return _athleteRedirect(athleteStatusCubit, loc);
      }

      return null;
    },
    routes: [
      // Auth
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

      // Athlete onboarding gate
      GoRoute(
        path: '/waiting',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: AthleteWaitingPage()),
      ),

      // Profile sub-routes
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

      // Structured athlete-profile survey (register and post-login refill).
      // Public because the user can land here mid-registration, before the
      // auth token is issued — the page then falls back to local storage.
      GoRoute(
        path: '/profile-survey',
        pageBuilder: (_, __) =>
            const MaterialPage(child: AthleteProfileSurveyPage()),
      ),

      // Onboarding
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

      // Trainer tools
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

      // Notifications
      GoRoute(
        path: '/notifications',
        pageBuilder: (_, __) =>
            const MaterialPage(child: NotificationsPage()),
      ),

      // Full-screen routes (outside shell)
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
      GoRoute(
        path: '/exercise-stats',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, String?>?;
          return MaterialPage(
            child: ExerciseStatsPage(
              athleteId: extra?['athleteId'],
              athleteName: extra?['athleteName'],
            ),
          );
        },
      ),
      GoRoute(
        path: '/prediction',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, String?>?;
          return MaterialPage(
            child: PredictionPage(
              athleteId: extra?['athleteId'],
              athleteName: extra?['athleteName'],
            ),
          );
        },
      ),
      // AI plan generator wizard. Reads athleteId from the query param so
      // the entry link from athlete_detail_page doesn't depend on go_router
      // extras (plain /plan/generate?athleteId=... also works from a push).
      GoRoute(
        path: '/plan/generate',
        pageBuilder: (context, state) {
          final athleteId = state.uri.queryParameters['athleteId'] ?? '';
          return MaterialPage(
            child: PlanGeneratePage(athleteId: athleteId),
          );
        },
      ),
      // Athlete's read-only view of their accepted plans.
      GoRoute(
        path: '/plan/mine',
        pageBuilder: (_, __) => const MaterialPage(child: MyPlanPage()),
      ),
      // Plan editor — pushed from the generate wizard's result view with the
      // just-saved TrainingPlanModel as `extra`. The backend has no
      // GET /api/plan/{id} endpoint yet, so deep-linking without a plan
      // argument falls back to an error page.
      GoRoute(
        path: '/plan/:id/edit',
        pageBuilder: (context, state) {
          final extra = state.extra;
          return MaterialPage(
            child: PlanEditorPage(
                plan: extra is TrainingPlanModel ? extra : null),
          );
        },
      ),

      // Main shell with bottom nav
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            BottomNavScaffold(shell: shell),
        branches: [
          // Tab 0 - Home (athlete) / Overview (coach)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: HomePage()),
              ),
            ],
          ),
          // Tab 1 - Sessions (athlete) / Athletes (coach)
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
          // Tab 2 - Messages
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
          // Tab 3 - Profile
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

  // Still loading - send to waiting (which shows a spinner).
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

  // AthleteStatusReady - let the original navigation proceed.
  return null;
}

// Helpers

/// Makes GoRouter re-evaluate redirect whenever any of the given streams emit.
class _CombinedListenable extends ChangeNotifier {
  _CombinedListenable(List<Stream<dynamic>> streams) {
    for (final s in streams) {
      s.listen((_) => notifyListeners());
    }
  }
}
