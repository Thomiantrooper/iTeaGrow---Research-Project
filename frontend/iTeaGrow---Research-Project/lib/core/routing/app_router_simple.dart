import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/public/presentation/landing/landing_page_simple.dart';
import '../../features/public/presentation/about/about_us_page_simple.dart';
import '../../features/public/presentation/contact/contact_us_page_simple.dart';
import '../../features/auth/presentation/screens/login_screen_simple.dart';
import '../../features/dashboard/presentation/screens/farmer_dashboard_simple.dart';
import '../../features/dashboard/presentation/screens/manager_dashboard_simple.dart';
import '../../features/dashboard/presentation/screens/admin_dashboard_simple.dart';
import '../../features/auth/data/providers/auth_provider_simple.dart';
import '../enums/app_enums.dart';

/// Fast page transition with minimal duration
CustomTransitionPage<void> _buildFastTransition({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 150),
    reverseTransitionDuration: const Duration(milliseconds: 100),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeOut).animate(animation),
        child: child,
      );
    },
  );
}

final appRouterSimpleProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateSimpleProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState != null;
      final isLoggingIn = state.matchedLocation == '/login';
      final isPublicRoute = state.matchedLocation == '/' ||
          state.matchedLocation == '/about' ||
          state.matchedLocation == '/contact';

      if (!isLoggedIn && !isPublicRoute && !isLoggingIn) {
        return '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        return _getDashboardRoute(authState.role);
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _buildFastTransition(
          child: const SimpleLandingPage(),
          state: state,
        ),
      ),
      GoRoute(
        path: '/about',
        pageBuilder: (context, state) => _buildFastTransition(
          child: const AboutUsPageSimple(),
          state: state,
        ),
      ),
      GoRoute(
        path: '/contact',
        pageBuilder: (context, state) => _buildFastTransition(
          child: const ContactUsPageSimple(),
          state: state,
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _buildFastTransition(
          child: const LoginScreenSimple(),
          state: state,
        ),
      ),
      GoRoute(
        path: '/dashboard/farmer',
        pageBuilder: (context, state) => _buildFastTransition(
          child: const FarmerDashboardSimple(),
          state: state,
        ),
      ),
      GoRoute(
        path: '/dashboard/manager',
        pageBuilder: (context, state) => _buildFastTransition(
          child: const ManagerDashboardSimple(),
          state: state,
        ),
      ),
      GoRoute(
        path: '/dashboard/admin',
        pageBuilder: (context, state) => _buildFastTransition(
          child: const AdminDashboardSimple(),
          state: state,
        ),
      ),
    ],
  );
});

String _getDashboardRoute(UserRole role) {
  switch (role) {
    case UserRole.farmer:
      return '/dashboard/farmer';
    case UserRole.manager:
      return '/dashboard/manager';
    case UserRole.admin:
      return '/dashboard/admin';
  }
}
