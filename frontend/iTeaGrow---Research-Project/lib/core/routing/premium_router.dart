import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/premium_login_screen.dart';
import '../../features/dashboard/presentation/screens/premium_farmer_dashboard.dart';
import '../../features/dashboard/presentation/screens/manager_dashboard_simple.dart';
import '../../features/dashboard/presentation/screens/admin_dashboard_simple.dart';
import '../../features/disease_detection/presentation/screens/enhanced_disease_detection_screen.dart';
import '../../features/soil_fertilization/presentation/screens/soil_fertilization_screen.dart';
import '../../features/powder_grading/presentation/screens/powder_grading_screen.dart';
import '../../features/auth/data/providers/auth_provider_simple.dart';
import '../enums/app_enums.dart';
import '../animations/tea_animations.dart';
import '../design_system/design_system.dart';

/// Premium page transition with Tea-themed animation
CustomTransitionPage<void> _buildPremiumTransition({
  required Widget child,
  required GoRouterState state,
  bool fadeSlideUp = true,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: TeaAnimations.normal,
    reverseTransitionDuration: TeaAnimations.fast,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (fadeSlideUp) {
        return FadeTransition(
          opacity: CurveTween(curve: TeaAnimations.enter).animate(animation),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: TeaAnimations.enter,
            )),
            child: child,
          ),
        );
      }
      return FadeTransition(
        opacity: CurveTween(curve: TeaAnimations.enter).animate(animation),
        child: child,
      );
    },
  );
}

/// Premium Router Provider
final premiumRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateSimpleProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState != null;
      final currentPath = state.matchedLocation;

      // Public routes that don't require authentication
      final publicRoutes = ['/splash', '/login'];
      final isPublicRoute = publicRoutes.contains(currentPath);

      // If not logged in and trying to access protected route
      if (!isLoggedIn && !isPublicRoute) {
        return '/login';
      }

      // If logged in and on login page, redirect to dashboard
      if (isLoggedIn && currentPath == '/login') {
        return _getDashboardRoute(authState.role);
      }

      // If logged in and on splash, redirect to dashboard
      if (isLoggedIn && currentPath == '/splash') {
        return _getDashboardRoute(authState.role);
      }

      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => _buildPremiumTransition(
          child: const SplashScreen(),
          state: state,
          fadeSlideUp: false,
        ),
      ),

      // Login Screen
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _buildPremiumTransition(
          child: const PremiumLoginScreen(),
          state: state,
        ),
      ),

      // Farmer Dashboard
      GoRoute(
        path: '/dashboard/farmer',
        pageBuilder: (context, state) => _buildPremiumTransition(
          child: const PremiumFarmerDashboard(),
          state: state,
        ),
      ),

      // Manager Dashboard (using existing)
      GoRoute(
        path: '/dashboard/manager',
        pageBuilder: (context, state) => _buildPremiumTransition(
          child: const ManagerDashboardSimple(),
          state: state,
        ),
      ),

      // Admin Dashboard (using existing)
      GoRoute(
        path: '/dashboard/admin',
        pageBuilder: (context, state) => _buildPremiumTransition(
          child: const AdminDashboardSimple(),
          state: state,
        ),
      ),

      // Disease Detection
      GoRoute(
        path: '/disease-detection',
        pageBuilder: (context, state) => _buildPremiumTransition(
          child: const EnhancedDiseaseDetectionScreen(),
          state: state,
        ),
      ),

      // Soil Fertilization
      GoRoute(
        path: '/soil-fertilization',
        pageBuilder: (context, state) => _buildPremiumTransition(
          child: const SoilFertilizationScreen(),
          state: state,
        ),
      ),

      // Powder Grading
      GoRoute(
        path: '/powder-grading',
        pageBuilder: (context, state) => _buildPremiumTransition(
          child: const PowderGradingScreen(),
          state: state,
        ),
      ),
    ],

    // Error page
    errorPageBuilder: (context, state) => _buildPremiumTransition(
      child: _ErrorPage(error: state.error?.toString() ?? 'Page not found'),
      state: state,
    ),
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

/// Error Page Widget
class _ErrorPage extends StatelessWidget {
  final String error;

  const _ErrorPage({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeaColors.mistGreen,
      body: Center(
        child: Padding(
          padding: TeaSpacing.screenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(TeaSpacing.xl),
                decoration: BoxDecoration(
                  color: TeaColors.alertRust.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: TeaColors.alertRust,
                ),
              ),
              const SizedBox(height: TeaSpacing.xl),
              Text(
                'Oops! Page Not Found',
                style: TeaTypography.headlineMedium.copyWith(
                  color: TeaColors.nearBlack,
                ),
              ),
              const SizedBox(height: TeaSpacing.sm),
              Text(
                error,
                style: TeaTypography.bodyMedium.copyWith(
                  color: TeaColors.darkGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TeaSpacing.xl),
              ElevatedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home),
                label: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
