import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';

import 'providers.dart';
import 'screens/checkin_success_screen.dart';
import 'screens/checkin_tab.dart';
import 'screens/explore_tab.dart';
import 'screens/gym_detail_screen.dart';
import 'screens/home_tab.dart';
import 'screens/login_screen.dart';
import 'screens/plan_manage_screen.dart';
import 'screens/profile_tab.dart';
import 'screens/register_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/student_card_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Notifica o GoRouter quando o estado de auth muda (login/logout)
  final authListenable = ValueNotifier<AsyncValue<Student?>>(const AsyncValue.loading());
  ref.listen(authProvider, (_, next) => authListenable.value = next, fireImmediately: true);
  ref.onDispose(authListenable.dispose);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final auth = authListenable.value;
      if (auth.isLoading) return '/splash';

      final signedIn = auth.value != null;
      final onAuthScreen = {'/login', '/register', '/splash'}.contains(state.matchedLocation);
      if (!signedIn && !onAuthScreen) return '/login';
      if (signedIn && onAuthScreen) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(
        path: '/gyms/:id',
        builder: (context, state) =>
            GymDetailScreen(gymId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/checkin-success',
        builder: (context, state) => CheckinSuccessScreen(checkin: state.extra as CheckIn),
      ),
      GoRoute(path: '/plans', builder: (context, state) => const PlanManageScreen()),
      GoRoute(path: '/card', builder: (context, state) => const StudentCardScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ShellScreen(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (context, state) => const HomeTab()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/explore', builder: (context, state) => const ExploreTab()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/checkin', builder: (context, state) => const CheckinTab()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (context, state) => const ProfileTab()),
          ]),
        ],
      ),
    ],
  );
});
