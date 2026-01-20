import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/public/presentation/landing/landing_page.dart';
import '../../features/public/presentation/about/about_us_page.dart';
import '../../features/public/presentation/contact/contact_us_page_simple.dart';
import '../../features/dashboard/presentation/screens/farmer_dashboard.dart';
import '../../features/dashboard/presentation/screens/jarvis_farmer_dashboard.dart';
import '../../features/dashboard/presentation/screens/manager_dashboard.dart';
import '../../features/dashboard/presentation/screens/admin_dashboard.dart';
import '../../features/disease_detection/presentation/screens/enhanced_disease_detection_screen.dart';
import '../../features/auth/data/providers/auth_provider_simple.dart';
import '../enums/app_enums.dart';

// Auth state notifier for GoRouter to listen to
class AuthChangeNotifier extends ChangeNotifier {
  AuthChangeNotifier(this._ref) {
    _ref.listen(authStateSimpleProvider, (previous, next) {
      debugPrint('AuthChangeNotifier: Auth state changed! previous=$previous, next=$next');
      notifyListeners();
    });
  }
  final Ref _ref;
}

final authChangeNotifierProvider = Provider<AuthChangeNotifier>((ref) {
  return AuthChangeNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final authChangeNotifier = ref.watch(authChangeNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authChangeNotifier,
    redirect: (context, state) {
      final user = ref.read(authStateSimpleProvider);
      final isLoggedIn = user != null;
      final isLoggingIn = state.matchedLocation == '/login';
      final isPublicRoute = state.matchedLocation == '/' ||
          state.matchedLocation == '/about' ||
          state.matchedLocation == '/contact';

      debugPrint('ROUTER REDIRECT: location=${state.matchedLocation}, isLoggedIn=$isLoggedIn, user=${user?.username}');

      // If not logged in and trying to access protected route, redirect to login
      if (!isLoggedIn && !isPublicRoute && !isLoggingIn) {
        debugPrint('ROUTER: Redirecting to /login');
        return '/login';
      }

      // If logged in and trying to access login, redirect to dashboard
      if (isLoggedIn && isLoggingIn) {
        final dashboardRoute = _getDashboardRoute(user.role);
        debugPrint('ROUTER: User logged in on login page, redirecting to $dashboardRoute');
        return dashboardRoute;
      }

      debugPrint('ROUTER: No redirect needed');
      return null;
    },
    routes: [
      // Public routes
      GoRoute(
        path: '/',
        builder: (context, state) => const LandingPage(),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutUsPage(),
      ),
      GoRoute(
        path: '/contact',
        builder: (context, state) => const ContactUsPageSimple(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Dashboard routes (role-based) - Using enhanced Jarvis dashboard
      GoRoute(
        path: '/dashboard/farmer',
        builder: (context, state) => const JarvisFarmerDashboard(),
      ),
      GoRoute(
        path: '/dashboard/farmer/classic',
        builder: (context, state) => const FarmerDashboard(),
      ),
      GoRoute(
        path: '/dashboard/manager',
        builder: (context, state) => const ManagerDashboard(),
      ),
      GoRoute(
        path: '/dashboard/admin',
        builder: (context, state) => const AdminDashboard(),
      ),

      // Feature routes
      GoRoute(
        path: '/disease-detection',
        builder: (context, state) => const EnhancedDiseaseDetectionScreen(),
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
