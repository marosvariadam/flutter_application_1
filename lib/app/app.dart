import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/app_router.dart';
import 'package:flutter_application_1/app/design/theme.dart';
import 'package:go_router/go_router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter _router = buildRouter();
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: _router,
    );
  }
}