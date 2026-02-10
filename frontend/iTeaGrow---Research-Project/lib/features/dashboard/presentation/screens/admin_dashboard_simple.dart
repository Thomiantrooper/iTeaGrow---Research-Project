import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/data/providers/auth_provider.dart';

class AdminDashboardSimple extends ConsumerStatefulWidget {
  const AdminDashboardSimple({super.key});

  @override
  ConsumerState<AdminDashboardSimple> createState() =>
      _AdminDashboardSimpleState();
}

class _AdminDashboardSimpleState extends ConsumerState<AdminDashboardSimple> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset > 50 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 50 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: TeaColors.mistGreen,
      body: Stack(
        children: [
          const FloatingLeavesBackground(
            leafCount: 4,
            opacity: 0.06,
            child: SizedBox.expand(),
          ),
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildSliverAppBar(user?.fullName ?? 'Administrator'),
              SliverPadding(
                padding: TeaSpacing.screenPaddingHorizontal,
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: TeaSpacing.md),
                    _buildWelcomeCard(user?.fullName ?? 'Administrator'),
                    const SizedBox(height: TeaSpacing.lg),
                    _buildSystemHealth(),
                    const SizedBox(height: TeaSpacing.lg),
                    _buildAdminTools(),
                    const SizedBox(height: TeaSpacing.lg),
                    _buildRecentActivity(),
                    const SizedBox(height: TeaSpacing.xxl),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: TeaBottomNavBar(
        currentIndex: 0,
        items: const [
          TeaNavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Home'),
          TeaNavItem(icon: Icons.analytics_outlined, activeIcon: Icons.analytics, label: 'Analytics'),
          TeaNavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Users'),
          TeaNavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings'),
        ],
        onTap: (index) {
          switch (index) {
            case 1:
              context.push('/dashboard/admin/analytics');
            case 2:
              context.push('/dashboard/admin/users');
            case 3:
              context.push('/dashboard/admin/config');
          }
        },
      ),
    );
  }

  Widget _buildSliverAppBar(String userName) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: _isScrolled ? 2 : 0,
      backgroundColor: _isScrolled ? TeaColors.white : Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.fromLTRB(
              TeaSpacing.md, 0, TeaSpacing.md, TeaSpacing.md),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Panel',
                  style: TeaTypography.bodyMedium
                      .copyWith(color: TeaColors.darkGray),
                ),
                Text(
                  userName,
                  style: TeaTypography.headlineMedium
                      .copyWith(color: TeaColors.matureLeaf),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TeaIconButton(
          icon: Icons.notifications_outlined,
          onPressed: () {},
          hasBadge: true,
          badgeText: '3',
          tooltip: 'Notifications',
        ),
        TeaIconButton(
          icon: Icons.logout,
          onPressed: () async {
            await ref.read(authStateProvider.notifier).logout();
            if (mounted) context.go('/login');
          },
          tooltip: 'Logout',
        ),
        const SizedBox(width: TeaSpacing.sm),
      ],
    );
  }

  Widget _buildWelcomeCard(String name) {
    return TeaCard.elevated(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: TeaRadius.radiusLg,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [TeaColors.matureLeaf, TeaColors.freshLeaf],
          ),
        ),
        padding: const EdgeInsets.all(TeaSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: TeaTypography.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: TeaTypography.headlineSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'System Administration',
                    style: TeaTypography.labelMedium.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSystemHealth() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TeaSectionHeader(
          title: 'System Health',
          icon: Icons.monitor_heart_outlined,
        ),
        const SizedBox(height: TeaSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TeaMetricCard(
                label: 'Database',
                value: 'Online',
                icon: Icons.storage_outlined,
                iconColor: TeaColors.healthyGreen,
              ),
            ),
            const SizedBox(width: TeaSpacing.smd),
            Expanded(
              child: TeaMetricCard(
                label: 'IoT Devices',
                value: '12',
                unit: ' Active',
                icon: Icons.sensors_outlined,
                iconColor: TeaColors.infoSky,
              ),
            ),
          ],
        ),
        const SizedBox(height: TeaSpacing.smd),
        Row(
          children: [
            Expanded(
              child: TeaMetricCard(
                label: 'Data Sync',
                value: 'Synced',
                icon: Icons.cloud_done_outlined,
                iconColor: TeaColors.freshLeaf,
              ),
            ),
            const SizedBox(width: TeaSpacing.smd),
            Expanded(
              child: TeaMetricCard(
                label: 'ML Models',
                value: 'Loaded',
                icon: Icons.psychology_outlined,
                iconColor: TeaColors.goldenSunlight,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildAdminTools() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TeaSectionHeader(
          title: 'Administration Tools',
          icon: Icons.build_outlined,
        ),
        const SizedBox(height: TeaSpacing.smd),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: TeaSpacing.smd,
          crossAxisSpacing: TeaSpacing.smd,
          childAspectRatio: 1.2,
          children: [
            TeaImageCard(
              title: 'User Management',
              subtitle: 'Roles & Permissions',
              tag: 'USERS',
              fallbackIcon: Icons.people,
              gradientColors: [TeaColors.infoSky, const Color(0xFF42A5F5)],
              borderRadius: TeaRadius.radiusLg,
              onTap: () => context.push('/dashboard/admin/users'),
            ),
            TeaImageCard(
              title: 'Device Management',
              subtitle: 'IoT Configuration',
              tag: 'DEVICES',
              fallbackIcon: Icons.devices,
              gradientColors: const [Color(0xFF7B1FA2), Color(0xFFAB47BC)],
              borderRadius: TeaRadius.radiusLg,
              onTap: () => context.push('/dashboard/admin/devices'),
            ),
            TeaImageCard(
              title: 'System Config',
              subtitle: 'Thresholds & Rules',
              tag: 'CONFIG',
              fallbackIcon: Icons.settings,
              gradientColors: [TeaColors.warningAmber, TeaColors.goldenSunlight],
              borderRadius: TeaRadius.radiusLg,
              onTap: () => context.push('/dashboard/admin/config'),
            ),
            TeaImageCard(
              title: 'Data Sync',
              subtitle: 'Cloud Backup',
              tag: 'SYNC',
              fallbackIcon: Icons.sync,
              gradientColors: const [Color(0xFF00897B), Color(0xFF4DB6AC)],
              borderRadius: TeaRadius.radiusLg,
              onTap: () => context.push('/dashboard/admin/sync'),
            ),
            TeaImageCard(
              title: 'System Logs',
              subtitle: 'Audit Trail',
              tag: 'LOGS',
              fallbackIcon: Icons.description,
              gradientColors: [TeaColors.darkGray, TeaColors.mediumGray],
              borderRadius: TeaRadius.radiusLg,
              onTap: () => context.push('/dashboard/admin/logs'),
            ),
            TeaImageCard(
              title: 'Analytics',
              subtitle: 'Dashboard & Charts',
              tag: 'DATA',
              fallbackIcon: Icons.analytics,
              gradientColors: [TeaColors.freshLeaf, TeaColors.matureLeaf],
              borderRadius: TeaRadius.radiusLg,
              onTap: () => context.push('/dashboard/admin/analytics'),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TeaSectionHeader(
          title: 'Recent Activity',
          icon: Icons.history_outlined,
        ),
        const SizedBox(height: TeaSpacing.sm),
        _buildActivityItem(
          icon: Icons.person_add,
          title: 'New user registered',
          subtitle: 'farmer_john - 2 hours ago',
          color: TeaColors.infoSky,
        ),
        const SizedBox(height: TeaSpacing.sm),
        _buildActivityItem(
          icon: Icons.sensors,
          title: 'IoT device connected',
          subtitle: 'Sensor-NPK-03 - 5 hours ago',
          color: TeaColors.freshLeaf,
        ),
        const SizedBox(height: TeaSpacing.sm),
        _buildActivityItem(
          icon: Icons.cloud_sync,
          title: 'Data synchronized',
          subtitle: '1,245 records - 1 day ago',
          color: TeaColors.goldenSunlight,
        ),
      ],
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return TeaCard.elevated(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: TeaRadius.radiusMd,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: TeaSpacing.smd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TeaTypography.titleSmall),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TeaTypography.labelSmall.copyWith(
                    color: TeaColors.darkGray,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: TeaColors.mediumGray, size: 20),
        ],
      ),
    );
  }
}
