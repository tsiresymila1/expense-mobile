import 'package:expense/presentation/widgets/app_shell.dart';
import 'package:expense/presentation/pages/auth/login_page.dart';
import 'package:expense/presentation/pages/dashboard/dashboard_page.dart';
import 'package:expense/presentation/pages/expenses/expenses_page.dart';
import 'package:expense/presentation/pages/account/account_page.dart';
import 'package:expense/presentation/pages/account/projects_page.dart';
import 'package:expense/presentation/pages/settings/settings_page.dart';
import 'package:expense/presentation/pages/stats/stats_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_instantdb/flutter_instantdb.dart';
import 'package:go_router/go_router.dart';

import 'dart:async';

class AppRouter {
  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  static GoRouter config(InstantDB db) => GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(db.auth.onAuthStateChange),
    redirect: (context, state) {
      final loggedIn = db.auth.currentUser.value != null;
      final isAuthPath = state.matchedLocation == '/login';
      if (!loggedIn && !isAuthPath) return '/login';
      if (loggedIn && isAuthPath) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      ShellRoute(
        observers: [routeObserver],
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardPage(),
          ),
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
          GoRoute(
            path: '/stats',
            builder: (context, state) => const StatsPage(),
          ),
        ],
      ),
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
