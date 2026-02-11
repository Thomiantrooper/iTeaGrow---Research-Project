import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../providers/analytics_provider.dart';

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
    Future.microtask(() {
      ref.read(analyticsProvider.notifier).loadOverview();
      ref.read(analyticsProvider.notifier).loadUserStats();
    });
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
                    _buildTeamActivity(),
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
          TeaNavItem(icon: Icons.people_outlined, activeIcon: Icons.people, label: 'Users'),
          TeaNavItem(icon: Icons.analytics_outlined, activeIcon: Icons.analytics, label: 'Analytics'),
          TeaNavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
        ],
        onTap: (index) {
          switch (index) {
            case 1:
              context.push('/dashboard/manager/users');
            case 2:
              context.push('/dashboard/admin/analytics');
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
          icon: Icons.refresh,
          onPressed: () {
            ref.read(analyticsProvider.notifier).loadOverview();
            ref.read(analyticsProvider.notifier).loadUserStats();
          },
          tooltip: 'Refresh',
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
    final analytics = ref.watch(analyticsProvider);
    final overview = analytics.overview;
    final isLoading = analytics.isLoading && overview == null;

    if (isLoading) {
      return Column(
        children: [
          Row(
            children: [
              const Expanded(child: TeaShimmer(width: double.infinity, height: 90)),
              const SizedBox(width: TeaSpacing.smd),
              const Expanded(child: TeaShimmer(width: double.infinity, height: 90)),
            ],
          ),
          const SizedBox(height: TeaSpacing.smd),
          Row(
            children: [
              const Expanded(child: TeaShimmer(width: double.infinity, height: 90)),
              const SizedBox(width: TeaSpacing.smd),
              const Expanded(child: TeaShimmer(width: double.infinity, height: 90)),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TeaMetricCard(
                label: 'Total Users',
                value: '${overview?['total_users'] ?? 0}',
                icon: Icons.people_outlined,
                iconColor: TeaColors.infoSky,
              ),
            ),
            const SizedBox(width: TeaSpacing.smd),
            Expanded(
              child: TeaMetricCard(
                label: 'Total Scans',
                value: '${overview?['total_scans'] ?? 0}',
                icon: Icons.document_scanner_outlined,
                iconColor: TeaColors.matureLeaf,
              ),
            ),
          ],
        ),
        const SizedBox(height: TeaSpacing.smd),
        Row(
          children: [
            Expanded(
              child: TeaMetricCard(
                label: 'Health Rate',
                value: '${((overview?['health_rate'] ?? 0) as num).toStringAsFixed(1)}%',
                icon: Icons.health_and_safety_outlined,
                iconColor: TeaColors.healthyGreen,
              ),
            ),
            const SizedBox(width: TeaSpacing.smd),
            Expanded(
              child: TeaMetricCard(
                label: 'Scans (7d)',
                value: '${overview?['recent_scans_7d'] ?? 0}',
                icon: Icons.trending_up,
                iconColor: TeaColors.warmAmber,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTeamActivity() {
    final analytics = ref.watch(analyticsProvider);
    final userStats = analytics.userStats;
    final topScanners = (userStats?['top_scanners'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TeaSectionHeader(
          title: 'Team Activity',
          icon: Icons.group_outlined,
          actionLabel: 'View All',
          onAction: () => context.push('/dashboard/manager/users'),
        ),
        const SizedBox(height: TeaSpacing.smd),
        if (topScanners.isEmpty)
          TeaCard.elevated(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: TeaColors.infoSky.withOpacity(0.12),
                    borderRadius: TeaRadius.radiusMd,
                  ),
                  child: const Icon(Icons.people_outlined, color: TeaColors.infoSky, size: 22),
                ),
                const SizedBox(width: TeaSpacing.smd),
                Expanded(
                  child: Text(
                    'Loading team data...',
                    style: TeaTypography.bodySmall.copyWith(color: TeaColors.darkGray),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: topScanners.length > 5 ? 5 : topScanners.length,
              separatorBuilder: (_, __) => const SizedBox(width: TeaSpacing.smd),
              itemBuilder: (context, index) {
                final scanner = topScanners[index];
                final name = scanner['full_name'] ?? 'Unknown';
                final scanCount = scanner['scan_count'] ?? 0;
                final initials = _getInitials(name);

                return SizedBox(
                  width: 100,
                  child: TeaCard.elevated(
                    padding: const EdgeInsets.all(TeaSpacing.smd),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: TeaColors.freshLeaf.withOpacity(0.15),
                          child: Text(
                            initials,
                            style: TeaTypography.labelMedium.copyWith(
                              color: TeaColors.matureLeaf,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: TeaSpacing.xs),
                        Text(
                          name.split(' ').first,
                          style: TeaTypography.labelSmall.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$scanCount scans',
                          style: TeaTypography.labelSmall.copyWith(
                            color: TeaColors.darkGray,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    )
        .animate()
        .fadeIn(delay: 50.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
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

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }
}
