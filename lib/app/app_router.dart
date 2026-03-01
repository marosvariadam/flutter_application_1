import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/shared/widgets/widgets_nav/bottom_nav.dart';
import 'package:flutter_application_1/features/coach/presentation/athlete_detail_page.dart';
import 'package:flutter_application_1/features/coach/presentation/workout_builder_page.dart';
import 'package:flutter_application_1/features/home/presantation/home_page.dart';
import 'package:flutter_application_1/features/login/login_page.dart';
import 'package:flutter_application_1/features/messaging/presentation/chat_page.dart';
import 'package:flutter_application_1/features/messaging/presentation/messaging_page.dart';
import 'package:flutter_application_1/features/profiles/presentation/profiles_page.dart';
import 'package:flutter_application_1/features/session/presentation/session_page.dart';
import 'package:flutter_application_1/features/workout/data/models/workout_model.dart';
import 'package:flutter_application_1/features/workout/presentation/workout_detail_page.dart';
import 'package:flutter_application_1/features/register/athlete_survey_page.dart';
import 'package:flutter_application_1/features/register/register_page.dart';
import 'package:go_router/go_router.dart';

enum Approute { home, session, messages, profile, login, register }

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      // ── Auth ────────────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        name: Approute.login.name,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LoginPage()),
      ),
      GoRoute(
        path: '/register',
        name: Approute.register.name,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: RegisterPage()),
      ),
      GoRoute(
        path: '/athlete-survey',
        pageBuilder: (context, state) =>
            const MaterialPage(child: AthleteSurveyPage()),
      ),

      // ── Full-screen routes (outside shell) ──────────────────────────────────
      GoRoute(
        path: '/workout-detail',
        pageBuilder: (context, state) {
          final workout = state.extra as WorkoutModel;
          return MaterialPage(child: WorkoutDetailPage(workout: workout));
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
        builder: (context, state, shell) => BottomNavScaffold(shell: shell),
        branches: [
          // Tab 0 — Home (athlete) / Overview (coach)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: Approute.home.name,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: HomePage()),
              ),
            ],
          ),
          // Tab 1 — Sessions (athlete) / Athletes (coach)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/session',
                name: Approute.session.name,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: SessionsPage()),
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
                name: Approute.profile.name,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ProfilesPage()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
