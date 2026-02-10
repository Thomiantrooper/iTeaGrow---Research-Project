import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/data/providers/auth_provider.dart';

class ManagerDashboard extends ConsumerStatefulWidget {
  const ManagerDashboard({super.key});

  @override
  ConsumerState<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends ConsumerState<ManagerDashboard> {
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
            opacity: 0.05,
            child: SizedBox.expand(),
          ),
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildSliverAppBar(user?.fullName ?? 'Manager'),
              SliverPadding(
                padding: TeaSpacing.screenPaddingHorizontal,
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: TeaSpacing.md),
                    _buildStatsOverview(),
                    const SizedBox(height: TeaSpacing.lg),
                    _buildStrategicPlanning(),
                    const SizedBox(height: TeaSpacing.lg),
                    _buildManagementTools(),
                    const SizedBox(height: TeaSpacing.xxl),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(ref),
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
                  'Estate Manager,',
                  style: TeaTypography.bodyMedium
                      .copyWith(color: TeaColors.darkGray),
                ),
                Text(
                  userName,
                  style: TeaTypography.headlineMedium
                      .copyWith(color: Colors.purple.shade900),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TeaIconButton(
          icon: Icons.search,
          onPressed: () {},
          tooltip: 'Search',
        ),
        TeaIconButton(
          icon: Icons.notifications_outlined,
          onPressed: () {},
          hasBadge: true,
          badgeText: '5',
          tooltip: 'Notifications',
        ),
        const SizedBox(width: TeaSpacing.sm),
      ],
    );
  }

  Widget _buildStatsOverview() {
    return Row(
      children: [
        Expanded(
          child: TeaMetricCard(
            label: 'Total Yield',
            value: '4.2',
            unit: ' Tons',
            icon: Icons.inventory_2_outlined,
            iconColor: Colors.purple,
            trend: '+12%',
            isPositiveTrend: true,
          ),
        ),
        const SizedBox(width: TeaSpacing.sm),
        Expanded(
          child: TeaMetricCard(
            label: 'Avg Quality',
            value: 'A+',
            icon: Icons.verified_outlined,
            iconColor: TeaColors.healthyGreen,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStrategicPlanning() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TeaSectionHeader(
          title: 'Strategic Planning',
          icon: Icons.auto_graph_outlined,
        ),
        const SizedBox(height: TeaSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildHeroAction(
                title: 'Predict Yield',
                subtitle: 'AI Projections',
                icon: Icons.query_stats,
                gradient: [Colors.purple.shade700, Colors.purple.shade400],
                onTap: () => context.push('/yield-prediction'),
              ),
            ),
            const SizedBox(width: TeaSpacing.sm),
            Expanded(
              child: _buildHeroAction(
                title: 'Quality Audit',
                subtitle: 'Powder Grading',
                icon: Icons.grade,
                gradient: [Colors.orange.shade700, Colors.orange.shade400],
                onTap: () => context.push('/powder-grading'),
              ),
            ),
          ],
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 100.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildHeroAction({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return TeaCard.elevated(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: TeaRadius.radiusMd,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                icon,
                size: 80,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(TeaSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TeaTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TeaTypography.labelSmall.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementTools() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TeaSectionHeader(
          title: 'Quick Actions',
          icon: Icons.flash_on_outlined,
        ),
        const SizedBox(height: TeaSpacing.sm),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: TeaSpacing.sm,
          crossAxisSpacing: TeaSpacing.sm,
          childAspectRatio: 1.3,
          children: [
            _buildPremiumActionCard(
              title: 'Leaf Maturity',
              subtitle: 'Check quality',
              tag: 'MATURITY',
              icon: Icons.center_focus_strong,
              gradient: [
                TeaColors.freshLeaf,
                TeaColors.matureLeaf.withOpacity(0.8)
              ],
              onTap: () => context.push('/leaf-maturity'),
            ),
            _buildPremiumActionCard(
              title: 'Disease Scan',
              subtitle: 'Plant health',
              tag: 'DIAGNOSIS',
              icon: Icons.bug_report_outlined,
              gradient: [Colors.red.shade700, Colors.red.shade400],
              onTap: () => context.push('/disease-detection'),
            ),
            _buildPremiumActionCard(
              title: 'Growth',
              subtitle: 'Block progress',
              tag: 'ANALYSIS',
              icon: Icons.grass_outlined,
              gradient: [TeaColors.leafLight, TeaColors.freshLeaf],
              onTap: () => context.push('/plants'),
            ),
            _buildPremiumActionCard(
              title: 'IoT Sensors',
              subtitle: 'Real-time data',
              tag: 'LIVE',
              icon: Icons.sensors,
              gradient: [TeaColors.infoSky, Colors.blue.shade400],
              onTap: () => context.push('/iot-devices'),
            ),
            _buildPremiumActionCard(
              title: 'Soil Test',
              subtitle: 'Nutrient check',
              tag: 'SOIL',
              icon: Icons.science_outlined,
              gradient: [TeaColors.richSoil, Colors.brown.shade400],
              onTap: () => context.push('/soil-fertilization'),
            ),
            _buildPremiumActionCard(
              title: 'Quality',
              subtitle: 'Powder grade',
              tag: 'GRADING',
              icon: Icons.grade_outlined,
              gradient: [TeaColors.warmAmber, TeaColors.goldenSunlight],
              onTap: () => context.push('/powder-grading'),
            ),
          ],
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildPremiumActionCard({
    required String title,
    required String subtitle,
    required String tag,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return TeaCard.elevated(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: TeaRadius.radiusMd,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                icon,
                size: 70,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(TeaSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: TeaTypography.titleSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TeaTypography.labelSmall.copyWith(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(WidgetRef ref) {
    return Drawer(
      backgroundColor: TeaColors.mistGreen,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text('Estate Manager'),
            accountEmail: const Text('manager@iteagrow.com'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.2),
              child: const Icon(Icons.admin_panel_settings,
                  color: Colors.white, size: 40),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade800, Colors.purple.shade400],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.analytics, color: TeaColors.freshLeaf),
            title: const Text('Analytics Dashboard'),
            onTap: () {
              Navigator.pop(context);
              context.push('/dashboard/admin/analytics');
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.blue),
            title: const Text('Scan History'),
            onTap: () {
              Navigator.pop(context);
              context.push('/scan-history');
            },
          ),
          ListTile(
            leading: Icon(Icons.description, color: Colors.orange.shade700),
            title: const Text('Reports'),
            onTap: () {
              Navigator.pop(context);
              context.push('/reports');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: TeaColors.alertRust),
            title: const Text('Logout',
                style: TextStyle(color: TeaColors.alertRust)),
            onTap: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
