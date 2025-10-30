import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum Approute{home, sessions, profile}

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
                builder: (context, state) => const Scaffold(body: Text('Home'),),
                ),
        ]

      )
    ],
  );
}