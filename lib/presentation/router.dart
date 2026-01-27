import 'package:expense/presentation/pages/auth/login_page.dart';
import 'package:expense/presentation/pages/auth/register_page.dart';
import 'package:expense/presentation/pages/auth/forgot_password_page.dart';
import 'package:expense/presentation/pages/dashboard/dashboard_page.dart';
import 'package:expense/presentation/pages/expenses/expenses_page.dart';
import 'package:expense/presentation/pages/account/account_page.dart';
import 'package:expense/presentation/pages/account/projects_page.dart';
import 'package:expense/presentation/pages/settings/settings_page.dart';
import 'package:expense/presentation/pages/stats/stats_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:async';

class AppRouter {
  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  static final config = GoRouter(
    observers: [routeObserver],
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    ),
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuthPath =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';

      if (session == null && !isAuthPath) {
        return '/login';
      }
      if (session != null && isAuthPath) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(path: '/', builder: (context, state) => const DashboardPage()),
      GoRoute(
        path: '/expenses',
        builder: (context, state) => const ExpensesPage(),
      ),
      GoRoute(
        path: '/account',
        builder: (context, state) => const AccountPage(),
      ),
      GoRoute(
        path: '/projects',
        builder: (context, state) => const ProjectsPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(path: '/stats', builder: (context, state) => const StatsPage()),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
