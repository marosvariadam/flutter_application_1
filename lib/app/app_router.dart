import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/app/shared/widgets/widgets_nav/bottom_nav.dart';
import 'package:flutter_application_1/features/auth/bloc/auth_bloc.dart';
import 'package:flutter_application_1/features/auth/presentation/register_page.dart';
import 'package:flutter_application_1/features/exercise/presentation/exercise_catalogue_page.dart';
import 'package:flutter_application_1/features/exercise/presentation/exercise_form_page.dart';
import 'package:flutter_application_1/features/home/presentation/home_page.dart';
import 'package:flutter_application_1/features/login/login_page.dart';
import 'package:flutter_application_1/features/messaging/presentation/chat_page.dart';
import 'package:flutter_application_1/features/messaging/presentation/messaging_page.dart';
import 'package:flutter_application_1/features/notifications/presentation/notifications_page.dart';
import 'package:flutter_application_1/features/onboarding/presentation/athlete_survey_page.dart';
import 'package:flutter_application_1/features/onboarding/presentation/trainer_form_builder_page.dart';
import 'package:flutter_application_1/features/onboarding/presentation/trainer_responses_page.dart';
import 'package:flutter_application_1/features/profiles/presentation/profiles_page.dart';
import 'package:flutter_application_1/features/session/presentation/session_page.dart';
import 'package:flutter_application_1/features/trainer/presentation/create_edit_athlete_page.dart';
import 'package:flutter_application_1/features/trainer/presentation/roster_page.dart';
import 'package:flutter_application_1/features/trainer/presentation/trainer_requests_page.dart';
import 'package:flutter_application_1/features/user/presentation/change_password_page.dart';
import 'package:flutter_application_1/features/user/presentation/edit_profile_page.dart';
import 'package:flutter_application_1/features/workout/presentation/workout_calendar_page.dart';
import 'package:flutter_application_1/features/workout/presentation/workout_detail_page.dart';
import 'package:flutter_application_1/features/workout/presentation/workout_form_page.dart';
import 'package:flutter_application_1/features/workout/presentation/workout_list_page.dart';
import 'package:flutter_application_1/features/workout/presentation/workout_review_page.dart';

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
      // ── Auth ───────────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: LoginPage()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (_, __) =>
            const MaterialPage(child: RegisterPage()),
      ),

      // ── Notifications (full-screen) ─────────────────────────────────────────
      GoRoute(
        path: '/notifications',
        pageBuilder: (_, __) =>
            const MaterialPage(child: NotificationsPage()),
      ),

      // ── Messaging (full-screen, no bottom nav) ──────────────────────────────
      GoRoute(
        path: '/messages',
        pageBuilder: (_, __) =>
            const MaterialPage(child: MessagingPage()),
        routes: [
          GoRoute(
            path: ':contactId',
            pageBuilder: (_, state) => MaterialPage(
              child: ChatPage(
                contactId: state.pathParameters['contactId']!,
              ),
            ),
          ),
        ],
      ),

      // ── Profile management ──────────────────────────────────────────────────
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

      // ── Trainer roster ──────────────────────────────────────────────────────
      GoRoute(
        path: '/roster',
        pageBuilder: (_, __) =>
            const MaterialPage(child: RosterPage()),
        routes: [
          GoRoute(
            path: 'new',
            pageBuilder: (_, __) =>
                const MaterialPage(child: CreateEditAthletePage()),
          ),
          GoRoute(
            path: ':athleteId/edit',
            pageBuilder: (_, state) => MaterialPage(
              child: CreateEditAthletePage(
                athleteId: state.pathParameters['athleteId'],
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/trainer-requests',
        pageBuilder: (_, state) {
          final isTrainer =
              state.uri.queryParameters['trainer'] == 'true';
          return MaterialPage(
            child: TrainerRequestsPage(isTrainer: isTrainer),
          );
        },
      ),

      // ── Workouts ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/workout/new',
        pageBuilder: (_, __) =>
            const MaterialPage(child: WorkoutFormPage()),
      ),
      GoRoute(
        path: '/workout/:id',
        pageBuilder: (_, state) => MaterialPage(
          child: WorkoutDetailPage(
            workoutId: state.pathParameters['id']!,
          ),
        ),
        routes: [
          GoRoute(
            path: 'edit',
            pageBuilder: (_, state) => MaterialPage(
              child: WorkoutFormPage(
                workoutId: state.pathParameters['id'],
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/workout-calendar',
        pageBuilder: (_, __) =>
            const MaterialPage(child: WorkoutCalendarPage()),
      ),
      GoRoute(
        path: '/workout-review/:athleteId',
        pageBuilder: (_, state) => MaterialPage(
          child: WorkoutReviewPage(
            athleteId: state.pathParameters['athleteId']!,
          ),
        ),
      ),

      // ── Exercises ───────────────────────────────────────────────────────────
      GoRoute(
        path: '/exercise-catalogue',
        pageBuilder: (_, state) {
          final selectionMode =
              state.uri.queryParameters['select'] == 'true';
          return MaterialPage(
            child:
                ExerciseCataloguePage(selectionMode: selectionMode),
          );
        },
      ),
      GoRoute(
        path: '/exercise/new',
        pageBuilder: (_, __) =>
            const MaterialPage(child: ExerciseFormPage()),
      ),
      GoRoute(
        path: '/exercise/:id/edit',
        pageBuilder: (_, state) => MaterialPage(
          child: ExerciseFormPage(
            exerciseId: state.pathParameters['id'],
          ),
        ),
      ),

      // ── Onboarding ──────────────────────────────────────────────────────────
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

      // ── Bottom-nav shell ────────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            BottomNavScaffold(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: HomePage()),
              ),
            ],
          ),
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
