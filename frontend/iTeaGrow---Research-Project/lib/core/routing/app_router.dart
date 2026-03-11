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
import '../../features/market_analysis/presentation/market_analysis_screen.dart';
import '../../features/market_analysis/presentation/market_value_admin_screen.dart';
import '../../features/market_analysis/presentation/market_price_report_screen.dart';
import '../../features/market_analysis/presentation/screens/market_history_screen.dart';
import '../../features/market_analysis/data/models/market_models.dart';
import '../../features/auth/data/providers/auth_provider.dart';
import '../enums/app_enums.dart';

import '../../features/yield_prediction/presentation/screens/yield_prediction_screen.dart';

// Auth state notifier for GoRouter to listen to
class AuthChangeNotifier extends ChangeNotifier {
  AuthChangeNotifier(this._ref) {
    _ref.listen(authStateProvider, (previous, next) {
      debugPrint(
          'AuthChangeNotifier: Auth state changed! status=${next.status}, user=${next.user?.username}');
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
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.isAuthenticated;
      final user = authState.user;
      final isLoggingIn = state.matchedLocation == '/login';
      final isPublicRoute = state.matchedLocation == '/' ||
          state.matchedLocation == '/about' ||
          state.matchedLocation == '/contact';

      debugPrint(
          'ROUTER REDIRECT: location=${state.matchedLocation}, isLoggedIn=$isLoggedIn, user=${user?.username}');

      // If not logged in and trying to access protected route, redirect to login
      if (!isLoggedIn && !isPublicRoute && !isLoggingIn) {
        debugPrint('ROUTER: Redirecting to /login');
        return '/login';
      }

      // If logged in and trying to access login, redirect to dashboard
      if (isLoggedIn && isLoggingIn && user != null) {
        final dashboardRoute = _getDashboardRoute(user.role);
        debugPrint(
            'ROUTER: User logged in on login page, redirecting to $dashboardRoute');
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
      GoRoute(
        path: '/market-analysis',
        builder: (context, state) => const MarketAnalysisScreen(),
      ),
      GoRoute(
        path: '/market-history',
        builder: (context, state) => const MarketHistoryScreen(),
      ),
      GoRoute(
          path: '/market-admin',
          builder: (context, state) => const MarketValueAdminScreen(),
          routes: [
            GoRoute(
                path: 'report',
                builder: (context, state) {
                  final reportData = state.extra as MarketPriceResponse?;
                  // Fallback if accessed absolutely
                  if (reportData == null) {
                    return const MarketValueAdminScreen();
                  }
                  return MarketPriceReportScreen(reportData: reportData);
                })
          ]),

      // Yield Prediction Routes (Manager Only)
      GoRoute(
        path: '/yield-prediction',
        builder: (context, state) {
          final user = ref.read(authStateProvider).user;
          if (user?.role != UserRole.manager) {
            return const LoginScreen();
          }
          return const YieldPredictionScreen();
        },
        routes: [
          GoRoute(
            path: 'results', // sub-route: /yield-prediction/results
            builder: (context, state) {
              // We need to pass the result object.
              // Since GoRouter complicates passing complex objects directly via path,
              // we will rely on the Provider state which already holds the result.
              // Alternatively, we could pass it as extra.
              // For now, let's grab it from the provider in the build method
              // or check if it's passed via extra.

              // Ideally, we redirect back if no result in provider.
              return const YieldPredictionScreen(); // Placeholder, logic handled in valid screen
            },
            // Note: In our screen implementation we push MaterialPageRoute,
            // so we might not strictly need this sub-route unless we want deep linking.
            // But good to have for structure.
          ),
        ],
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
