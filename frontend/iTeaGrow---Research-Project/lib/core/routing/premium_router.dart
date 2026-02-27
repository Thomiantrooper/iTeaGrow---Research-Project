import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/premium_login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/premium_farmer_dashboard.dart';
import '../../features/dashboard/presentation/screens/manager_dashboard.dart';
import '../../features/dashboard/presentation/screens/manager_users_screen.dart';
import '../../features/dashboard/presentation/screens/admin_dashboard_simple.dart';
import '../../features/disease_detection/presentation/screens/premium_disease_detection_screen.dart';
import '../../features/soil_fertilization/presentation/screens/soil_fertilization_screen.dart';
import '../../features/powder_grading/presentation/screens/powder_grading_screen.dart';
import '../../features/market_analysis/presentation/market_analysis_screen.dart';
import '../../features/market_analysis/presentation/market_value_admin_screen.dart';
import '../../features/market_analysis/presentation/market_price_report_screen.dart';
import '../../features/market_analysis/data/models/market_models.dart';
import '../../features/plants/presentation/screens/premium_plants_screen.dart';
import '../../features/map/presentation/screens/premium_map_screen.dart';
import '../../features/settings/presentation/screens/premium_settings_screen.dart';
import '../../features/profile/presentation/screens/premium_profile_screen.dart';
import '../../features/iot_connectivity/presentation/screens/premium_iot_screen.dart';
import '../../features/leaf_maturity/presentation/screens/leaf_maturity_screen.dart';
import '../../features/yield_prediction/presentation/screens/yield_prediction_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/help/presentation/screens/help_center_screen.dart';
import '../../features/activity/presentation/screens/activity_history_screen.dart';
import '../../features/chatbot/presentation/screens/chatbot_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/data/providers/auth_provider.dart';
import '../../features/admin/presentation/screens/admin_placeholder_screens.dart';
import '../../features/dashboard/presentation/screens/analytics_dashboard_screen.dart';
import '../../features/reports/presentation/screens/reports_list_screen.dart';
import '../../features/reports/presentation/screens/report_preview_screen.dart';
import '../../features/disease_detection/presentation/screens/scan_history_screen.dart';
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
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: TeaAnimations.enter,
              ),
            ),
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

/// ChangeNotifier bridge that triggers GoRouter redirect re-evaluation
/// when auth state changes, without recreating the entire GoRouter.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      // Only notify when auth status actually changes
      if (previous?.status != next.status) {
        notifyListeners();
      }
    });
  }
}

/// Premium Router Provider - creates GoRouter ONCE and uses
/// refreshListenable to re-evaluate redirects on auth state changes.
final premiumRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthChangeNotifier(ref);

  final router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      // Read current auth state (not watch - we use refreshListenable instead)
      final authState = ref.read(authStateProvider);
      final isAuthenticated = authState.isAuthenticated;
      final user = authState.user;
      final currentPath = state.matchedLocation;

      // Public routes that don't require authentication
      final publicRoutes = [
        '/splash',
        '/login',
        '/register',
        '/forgot-password'
      ];
      final isPublicRoute = publicRoutes.contains(currentPath);

      // If auth is still loading, let them stay on splash
      if (authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading) {
        if (currentPath != '/splash') {
          return '/splash';
        }
        return null;
      }

      // If not logged in and trying to access protected route → go to login
      if (!isAuthenticated && !isPublicRoute) {
        return '/login';
      }

      // If logged in and on login page → go to dashboard
      if (isAuthenticated && currentPath == '/login') {
        return _getDashboardRoute(user?.role ?? UserRole.farmer);
      }

      // If logged in and on splash → go to dashboard
      if (isAuthenticated && currentPath == '/splash') {
        return _getDashboardRoute(user?.role ?? UserRole.farmer);
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

      // Registration Screen
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _buildPremiumTransition(
          child: const RegisterScreen(),
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

      // Farmer Dashboard alias
      GoRoute(
        path: '/farmer-dashboard',
        redirect: (context, state) => '/dashboard/farmer',
      ),

      // Manager Dashboard (using existing)
      GoRoute(
        path: '/dashboard/manager',
        pageBuilder: (context, state) => _buildPremiumTransition(
          child: const ManagerDashboard(),
          state: state,
        ),
      ),

      // Manager: User Overview (read-only)
      GoRoute(
        path: '/dashboard/manager/users',
        pageBuilder: (context, state) => _buildPremiumTransition(
          child: const ManagerUsersScreen(),
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
          child: const PremiumDiseaseDetectionScreen(),
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
          child: const PowderGradingScreen(showMarketData: false),
          state: state,
        ),
      ),

      // Market Analysis
      GoRoute(
        path: '/market-analysis',
        pageBuilder: (context, state) => _buildPremiumTransition(
          child: const MarketAnalysisScreen(),
          state: state,
        ),
      ),

      // Market Value Admin
      GoRoute(
          path: '/market-admin',
          pageBuilder: (context, state) => _buildPremiumTransition(
                child: const MarketValueAdminScreen(),
                state: state,
              ),
          routes: [
            GoRoute(
                path: 'report',
                pageBuilder: (context, state) {
                  final reportData = state.extra as MarketPriceResponse?;
                  // Fallback if accessed absolutely
                  if (reportData == null) {
                    return _buildPremiumTransition(
                      child: const MarketValueAdminScreen(),
                      state: state,
                    );
                  }
                  return _buildPremiumTransition(
                    child: MarketPriceReportScreen(reportData: reportData),
                    state: state,
                  );
                })
          ]),

      // Plants/Growth Monitoring
      GoRoute(
        path: '/plants',
        pageBuilder: (context, state) => _buildPremiumTransition(
          child: const PremiumPlantsScreen(),
          state: state,
        ),
      ),

      // Plantation Map
      GoRoute(
        path: '/map',
        pageBuilder: (context, state) => _buildPremiumTransition(
          child: const PremiumMapScreen(),
          state: state,
        ),
      ),

      // Settings
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) {
          final authState = ref.read(authStateProvider);
          final isFarmer = authState.user?.role == UserRole.farmer;
          return _buildPremiumTransition(
            child: PremiumSettingsScreen(allowBiometricAndPin: isFarmer),
            state: state,
          );
        },
      ),

      // Profile
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => _buildPremiumTransition(
          child: const PremiumProfileScreen(),
          state: state,
        ),
      ),

      // IoT Devices
      GoRoute(
        path: '/iot-devices',
        pageBuilder: (context, state) => _buildPremiumTransition(
          child: const PremiumIoTScreen(),
          state: state,
        ),
      ),

      // Leaf Maturity
      GoRoute(
        path: '/leaf-maturity',
        pageBuilder: (context, state) => _buildPremiumTransition(
          child: const LeafMaturityScreen(),
          state: state,
        ),
      ),

      // Yield Prediction
      GoRoute(
        path: '/yield-prediction',
        pageBuilder: (context, state) => _buildPremiumTransition(
          child: const YieldPredictionScreen(),
          state: state,
        ),
      ),

      // Notifications
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => _buildPremiumTransition(
          child: const NotificationsScreen(),
          state: state,
        ),
      ),

      // Help Center
      GoRoute(
        path: '/help-center',
        pageBuilder: (context, state) => _buildPremiumTransition(
          child: const HelpCenterScreen(),
          state: state,
        ),
      ),

      // Activity History
      GoRoute(
        path: '/activity-history',
        pageBuilder: (context, state) => _buildPremiumTransition(
          child: const ActivityHistoryScreen(),
          state: state,
        ),
      ),

      // Chatbot
      GoRoute(
        path: '/chatbot',
        pageBuilder: (context, state) => _buildPremiumTransition(
          child: const ChatbotScreen(),
          state: state,
        ),
      ),

      // Forgot Password
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => _buildPremiumTransition(
          child: const ForgotPasswordScreen(),
          state: state,
        ),
      ),

      // ── Admin Sub-Routes ──────────────────────────────────────

      // Admin: User Management
      GoRoute(
        path: '/dashboard/admin/users',
        pageBuilder: (context, state) => _buildPremiumTransition(
          child: const UserManagementScreen(),
          state: state,
        ),
      ),

      // Admin: Device Management
      GoRoute(
        path: '/dashboard/admin/devices',
        pageBuilder: (context, state) => _buildPremiumTransition(
          child: const DeviceManagementScreen(),
          state: state,
        ),
      ),

      // Admin: System Configuration
      GoRoute(
        path: '/dashboard/admin/config',
        pageBuilder: (context, state) => _buildPremiumTransition(
          child: const SystemConfigScreen(),
          state: state,
        ),
      ),

      // Admin: Data Sync
      GoRoute(
        path: '/dashboard/admin/sync',
        pageBuilder: (context, state) => _buildPremiumTransition(
          child: const DataSyncScreen(),
          state: state,
        ),
      ),

      // Admin: System Logs
      GoRoute(
        path: '/dashboard/admin/logs',
        pageBuilder: (context, state) => _buildPremiumTransition(
          child: const SystemLogsScreen(),
          state: state,
        ),
      ),

      // Admin/Manager: Analytics Dashboard
      GoRoute(
        path: '/dashboard/admin/analytics',
        pageBuilder: (context, state) => _buildPremiumTransition(
          child: const AnalyticsDashboardScreen(),
          state: state,
        ),
      ),

      // ── Reports & History Routes ──────────────────────────────

      // Scan History
      GoRoute(
        path: '/scan-history',
        pageBuilder: (context, state) => _buildPremiumTransition(
          child: const ScanHistoryScreen(),
          state: state,
        ),
      ),

      // Reports List
      GoRoute(
        path: '/reports',
        pageBuilder: (context, state) => _buildPremiumTransition(
          child: const ReportsListScreen(),
          state: state,
        ),
      ),

      // Report Preview (with detection ID parameter)
      GoRoute(
        path: '/reports/preview/:id',
        pageBuilder: (context, state) {
          final detectionId = state.pathParameters['id'] ?? '';
          return _buildPremiumTransition(
            child: ReportPreviewScreen(detectionId: detectionId),
            state: state,
          );
        },
      ),
    ],

    // Error page
    errorPageBuilder: (context, state) => _buildPremiumTransition(
      child: _ErrorPage(error: state.error?.toString() ?? 'Page not found'),
      state: state,
    ),
  );

  ref.onDispose(router.dispose);
  return router;
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
