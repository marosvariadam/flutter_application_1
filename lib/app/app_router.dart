import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/shared/widgets/widgets_nav/bottom_nav.dart';
import 'package:go_router/go_router.dart';

enum Approute{home, session, profile}

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder:(context, state, shell) => BottomNavScaffold(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: Approute.home.name,
                builder: (context, state) => const Scaffold(body: Center(child: Text('Home')),),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/session',
                name: Approute.session.name,
                builder: (context, state) => const Scaffold(body: Center(child: Text('Session')),),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: Approute.profile.name,
                builder: (context, state) => const Scaffold(body: Center(child: Text('Profile')),),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}