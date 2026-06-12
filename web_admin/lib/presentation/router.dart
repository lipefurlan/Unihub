import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/panel_auth_repository.dart';
import 'providers.dart';
import 'screens/admin_gyms_screen.dart';
import 'screens/admin_overview_screen.dart';
import 'screens/admin_payouts_screen.dart';
import 'screens/admin_students_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/login_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/students_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authListenable = ValueNotifier<AsyncValue<PanelSession?>>(const AsyncValue.loading());
  ref.listen(sessionProvider, (_, next) => authListenable.value = next, fireImmediately: true);
  ref.onDispose(authListenable.dispose);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final auth = authListenable.value;
      if (auth.isLoading) return '/splash';

      final session = auth.value;
      final location = state.matchedLocation;
      final onAuthScreen = {'/login', '/splash'}.contains(location);

      if (session == null) return onAuthScreen ? null : '/login';

      final home = session.isAdmin ? '/admin/overview' : '/dashboard';
      if (onAuthScreen) return home;
      // Cada role só navega na própria área
      final inAdminArea = location.startsWith('/admin');
      if (session.isAdmin != inAdminArea) return home;
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) =>
            ShellScreen(location: state.matchedLocation, child: child),
        routes: [
          // Área da academia
          GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
          GoRoute(path: '/students', builder: (context, state) => const StudentsScreen()),
          GoRoute(path: '/finance', builder: (context, state) => const FinanceScreen()),
          GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
          // Área da operação UniHub
          GoRoute(path: '/admin/overview', builder: (context, state) => const AdminOverviewScreen()),
          GoRoute(path: '/admin/gyms', builder: (context, state) => const AdminGymsScreen()),
          GoRoute(path: '/admin/payouts', builder: (context, state) => const AdminPayoutsScreen()),
          GoRoute(path: '/admin/students', builder: (context, state) => const AdminStudentsScreen()),
        ],
      ),
    ],
  );
});
