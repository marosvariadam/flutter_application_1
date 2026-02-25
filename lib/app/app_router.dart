import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/shared/widgets/widgets_nav/bottom_nav.dart';
import 'package:flutter_application_1/features/home/presentation/home_page.dart';
import 'package:flutter_application_1/features/login/login_page.dart';
import 'package:flutter_application_1/features/messaging/presentation/chat_page.dart';
import 'package:flutter_application_1/features/messaging/presentation/messaging_page.dart';
import 'package:flutter_application_1/features/profiles/presentation/profiles_page.dart';
import 'package:flutter_application_1/features/session/presentation/session_page.dart';
import 'package:go_router/go_router.dart';

enum Approute { home, session, profile, login, messages, chat }

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        name: Approute.login.name,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LoginPage()),
      ),

      // Messaging — full-screen, outside the shell (no bottom nav)
      GoRoute(
        path: '/messages',
        name: Approute.messages.name,
        pageBuilder: (context, state) =>
            const MaterialPage(child: MessagingPage()),
        routes: [
          GoRoute(
            path: ':contactId',
            name: Approute.chat.name,
            pageBuilder: (context, state) => MaterialPage(
              child: ChatPage(
                contactId: state.pathParameters['contactId']!,
              ),
            ),
          ),
        ],
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => BottomNavScaffold(shell: shell),
        branches: [
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
