// ignore_for_file: unused_import

import 'package:field_survey/screens/auth/login_page.dart';
import 'package:field_survey/screens/auth/register_page.dart';
import 'package:field_survey/screens/dashboard/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash/splash_screen.dart';
import 'app_routes.dart';

class AppPages {
  static final router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardPage(),
      ),
    ],
  );
}
