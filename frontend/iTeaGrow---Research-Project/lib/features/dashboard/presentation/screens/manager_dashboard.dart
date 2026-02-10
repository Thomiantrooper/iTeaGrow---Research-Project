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
      bottomNavigationBar: TeaBottomNavBar(
        currentIndex: 0,
        items: const [
          TeaNavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Home'),
          TeaNavItem(icon: Icons.analytics_outlined, activeIcon: Icons.analytics, label: 'Analytics'),
          TeaNavItem(icon: Icons.description_outlined, activeIcon: Icons.description, label: 'Reports'),
          TeaNavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
        ],
        onTap: (index) {
          switch (index) {
            case 1:
              context.push('/dashboard/admin/analytics');
            case 2:
              context.push('/reports');
            case 3:
              context.push('/profile');
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
                  'Estate Manager,',
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
            iconColor: TeaColors.matureLeaf,
            trend: '+12%',
            isPositiveTrend: true,
          ),
        ),
        const SizedBox(width: TeaSpacing.smd),
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
        const SizedBox(height: TeaSpacing.smd),
        Row(
          children: [
            Expanded(
              child: TeaImageCard(
                title: 'Predict Yield',
                subtitle: 'AI Projections',
                tag: 'FORECAST',
                fallbackIcon: Icons.query_stats,
                gradientColors: [TeaColors.matureLeaf, TeaColors.freshLeaf],
                height: 160,
                borderRadius: TeaRadius.radiusLg,
                onTap: () => context.push('/yield-prediction'),
              ),
            ),
            const SizedBox(width: TeaSpacing.smd),
            Expanded(
              child: TeaImageCard(
                title: 'Quality Audit',
                subtitle: 'Powder Grading',
                tag: 'GRADING',
                fallbackIcon: Icons.grade,
                gradientColors: [TeaColors.warningAmber, TeaColors.goldenSunlight],
                height: 160,
                borderRadius: TeaRadius.radiusLg,
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

  Widget _buildManagementTools() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TeaSectionHeader(
          title: 'Quick Actions',
          icon: Icons.flash_on_outlined,
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
              title: 'Leaf Maturity',
              subtitle: 'Check quality',
              tag: 'MATURITY',
              fallbackIcon: Icons.center_focus_strong,
              gradientColors: [
                TeaColors.freshLeaf,
                TeaColors.matureLeaf.withOpacity(0.8),
              ],
              borderRadius: TeaRadius.radiusLg,
              onTap: () => context.push('/leaf-maturity'),
            ),
            TeaImageCard(
              title: 'Disease Scan',
              subtitle: 'Plant health',
              tag: 'DIAGNOSIS',
              fallbackIcon: Icons.bug_report_outlined,
              gradientColors: [TeaColors.alertRust, const Color(0xFFEF5350)],
              borderRadius: TeaRadius.radiusLg,
              onTap: () => context.push('/disease-detection'),
            ),
            TeaImageCard(
              title: 'Growth',
              subtitle: 'Block progress',
              tag: 'ANALYSIS',
              fallbackIcon: Icons.grass_outlined,
              gradientColors: [TeaColors.leafLight, TeaColors.freshLeaf],
              borderRadius: TeaRadius.radiusLg,
              onTap: () => context.push('/plants'),
            ),
            TeaImageCard(
              title: 'IoT Sensors',
              subtitle: 'Real-time data',
              tag: 'LIVE',
              fallbackIcon: Icons.sensors,
              gradientColors: [TeaColors.infoSky, const Color(0xFF42A5F5)],
              borderRadius: TeaRadius.radiusLg,
              onTap: () => context.push('/iot-devices'),
            ),
            TeaImageCard(
              title: 'Soil Test',
              subtitle: 'Nutrient check',
              tag: 'SOIL',
              fallbackIcon: Icons.science_outlined,
              gradientColors: [TeaColors.richSoil, const Color(0xFF8D6E63)],
              borderRadius: TeaRadius.radiusLg,
              onTap: () => context.push('/soil-fertilization'),
            ),
            TeaImageCard(
              title: 'Quality',
              subtitle: 'Powder grade',
              tag: 'GRADING',
              fallbackIcon: Icons.grade_outlined,
              gradientColors: [TeaColors.warmAmber, TeaColors.goldenSunlight],
              borderRadius: TeaRadius.radiusLg,
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
}
