import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/services/admin_service.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../auth/domain/models/user.dart';
import '../providers/analytics_provider.dart';

/// Read-only user management console for managers.
/// Shows user list with summary metrics, search, and role filtering.
class ManagerUsersScreen extends ConsumerStatefulWidget {
  const ManagerUsersScreen({super.key});

  @override
  ConsumerState<ManagerUsersScreen> createState() => _ManagerUsersScreenState();
}

class _ManagerUsersScreenState extends ConsumerState<ManagerUsersScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  String _searchQuery = '';
  UserRole? _selectedRole;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      ref.read(usersProvider.notifier).loadUsers();
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

  List<User> _filterUsers(List<User> users) {
    return users.where((user) {
      final matchesSearch = _searchQuery.isEmpty ||
          user.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (user.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      final matchesRole = _selectedRole == null || user.role == _selectedRole;
      return matchesSearch && matchesRole;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);

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
              _buildSliverAppBar(),
              SliverPadding(
                padding: TeaSpacing.screenPaddingHorizontal,
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: TeaSpacing.md),
                    _buildSummaryCards(),
                    const SizedBox(height: TeaSpacing.lg),
                    _buildSearchAndFilter(),
                    const SizedBox(height: TeaSpacing.md),
                    usersAsync.when(
                      loading: () => _buildLoadingState(),
                      error: (error, _) => _buildErrorState(error.toString()),
                      data: (users) {
                        final filtered = _filterUsers(users);
                        if (filtered.isEmpty) {
                          return _buildEmptyState(users.isEmpty);
                        }
                        return _buildUserList(filtered);
                      },
                    ),
                    const SizedBox(height: TeaSpacing.xxl),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: TeaBottomNavBar(
        currentIndex: 1,
        items: const [
          TeaNavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Home'),
          TeaNavItem(icon: Icons.people_outlined, activeIcon: Icons.people, label: 'Users'),
          TeaNavItem(icon: Icons.analytics_outlined, activeIcon: Icons.analytics, label: 'Analytics'),
          TeaNavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard/manager');
            case 2:
              context.push('/dashboard/admin/analytics');
            case 3:
              context.push('/profile');
          }
        },
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 80,
      floating: true,
      pinned: true,
      elevation: _isScrolled ? 2 : 0,
      backgroundColor: _isScrolled ? TeaColors.white : Colors.transparent,
      title: Text(
        'Team Members',
        style: TeaTypography.headlineSmall.copyWith(
          color: TeaColors.matureLeaf,
        ),
      ),
      actions: [
        TeaIconButton(
          icon: Icons.refresh,
          onPressed: () {
            ref.read(usersProvider.notifier).loadUsers();
            ref.read(analyticsProvider.notifier).loadOverview();
          },
          tooltip: 'Refresh',
        ),
        const SizedBox(width: TeaSpacing.sm),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final analytics = ref.watch(analyticsProvider);
    final overview = analytics.overview;
    final userStats = analytics.userStats;
    final isLoading = analytics.isLoading && overview == null;

    if (isLoading) {
      return Row(
        children: const [
          Expanded(child: TeaShimmer(width: double.infinity, height: 90)),
          SizedBox(width: TeaSpacing.smd),
          Expanded(child: TeaShimmer(width: double.infinity, height: 90)),
          SizedBox(width: TeaSpacing.smd),
          Expanded(child: TeaShimmer(width: double.infinity, height: 90)),
        ],
      );
    }

    final totalUsers = overview?['total_users'] ?? 0;
    final activeUsers = overview?['active_users'] ?? 0;
    final newUsers = userStats?['new_users_30d'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: TeaMetricCard(
            label: 'Total',
            value: '$totalUsers',
            icon: Icons.people,
            iconColor: TeaColors.infoSky,
          ),
        ),
        const SizedBox(width: TeaSpacing.smd),
        Expanded(
          child: TeaMetricCard(
            label: 'Active',
            value: '$activeUsers',
            icon: Icons.check_circle_outline,
            iconColor: TeaColors.healthyGreen,
          ),
        ),
        const SizedBox(width: TeaSpacing.smd),
        Expanded(
          child: TeaMetricCard(
            label: 'New (30d)',
            value: '$newUsers',
            icon: Icons.person_add_outlined,
            iconColor: TeaColors.freshLeaf,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSearchAndFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        Container(
          decoration: BoxDecoration(
            color: TeaColors.white,
            borderRadius: TeaRadius.radiusMd,
            boxShadow: TeaShadows.cardShadow,
          ),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search users...',
              hintStyle: TeaTypography.bodySmall.copyWith(color: TeaColors.mediumGray),
              prefixIcon: const Icon(Icons.search, color: TeaColors.mediumGray, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: TeaSpacing.md,
                vertical: TeaSpacing.smd,
              ),
            ),
            style: TeaTypography.bodySmall,
          ),
        ),
        const SizedBox(height: TeaSpacing.smd),
        // Role filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All', null),
              const SizedBox(width: TeaSpacing.sm),
              _buildFilterChip('Admin', UserRole.admin),
              const SizedBox(width: TeaSpacing.sm),
              _buildFilterChip('Manager', UserRole.manager),
              const SizedBox(width: TeaSpacing.sm),
              _buildFilterChip('Farmer', UserRole.farmer),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
  }

  Widget _buildFilterChip(String label, UserRole? role) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: TeaSpacing.smd,
          vertical: TeaSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? TeaColors.freshLeaf : TeaColors.white,
          borderRadius: TeaRadius.radiusRound,
          border: Border.all(
            color: isSelected ? TeaColors.freshLeaf : TeaColors.lightGray,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: TeaColors.freshLeaf.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          label,
          style: TeaTypography.labelSmall.copyWith(
            color: isSelected ? TeaColors.white : TeaColors.darkGray,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(4, (index) => Padding(
        padding: const EdgeInsets.only(bottom: TeaSpacing.smd),
        child: TeaShimmer(width: double.infinity, height: 100),
      )),
    );
  }

  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TeaSpacing.xl),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: TeaColors.alertRust.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, color: TeaColors.alertRust, size: 32),
          ),
          const SizedBox(height: TeaSpacing.md),
          Text(
            'Failed to load users',
            style: TeaTypography.titleSmall.copyWith(color: TeaColors.nearBlack),
          ),
          const SizedBox(height: TeaSpacing.xs),
          Text(
            error,
            style: TeaTypography.bodySmall.copyWith(color: TeaColors.darkGray),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TeaSpacing.md),
          TextButton.icon(
            onPressed: () => ref.read(usersProvider.notifier).loadUsers(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: TextButton.styleFrom(foregroundColor: TeaColors.freshLeaf),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool noUsersAtAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TeaSpacing.xl),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: TeaColors.infoSky.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline, color: TeaColors.infoSky, size: 32),
          ),
          const SizedBox(height: TeaSpacing.md),
          Text(
            noUsersAtAll ? 'No users found' : 'No matching users',
            style: TeaTypography.titleSmall.copyWith(color: TeaColors.nearBlack),
          ),
          const SizedBox(height: TeaSpacing.xs),
          Text(
            noUsersAtAll
                ? 'Users will appear here once they register'
                : 'Try adjusting your search or filter',
            style: TeaTypography.bodySmall.copyWith(color: TeaColors.darkGray),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(List<User> users) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: TeaSpacing.sm),
          child: Text(
            '${users.length} user${users.length != 1 ? 's' : ''}',
            style: TeaTypography.labelSmall.copyWith(color: TeaColors.darkGray),
          ),
        ),
        ...users.asMap().entries.map((entry) {
          final index = entry.key;
          final user = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: TeaSpacing.smd),
            child: _buildUserCard(user)
                .animate()
                .fadeIn(delay: (index * 50).ms, duration: 300.ms)
                .slideY(begin: 0.05, end: 0),
          );
        }),
      ],
    );
  }

  Widget _buildUserCard(User user) {
    final roleColor = _getRoleColor(user.role);
    final initials = _getInitials(user.fullName);
    final timeAgo = user.createdAt != null ? _formatTimeAgo(user.createdAt!) : '';

    return TeaCard.elevated(
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: roleColor.withOpacity(0.15),
                child: Text(
                  initials,
                  style: TeaTypography.labelMedium.copyWith(
                    color: roleColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: TeaSpacing.smd),
              // Name and username
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: TeaTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${user.username}',
                      style: TeaTypography.bodySmall.copyWith(color: TeaColors.darkGray),
                    ),
                  ],
                ),
              ),
              // Status and role
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _getRoleDisplayName(user.role),
                      style: TeaTypography.labelSmall.copyWith(
                        color: roleColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Active status
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: user.isActive ? TeaColors.healthyGreen : TeaColors.alertRust,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.isActive ? 'Active' : 'Inactive',
                        style: TeaTypography.labelSmall.copyWith(
                          color: user.isActive ? TeaColors.healthyGreen : TeaColors.alertRust,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Info row
          if ((user.email != null && user.email!.isNotEmpty) ||
              (user.phone != null && user.phone!.isNotEmpty) ||
              timeAgo.isNotEmpty) ...[
            const SizedBox(height: TeaSpacing.sm),
            Divider(color: TeaColors.lightGray.withOpacity(0.5), height: 1),
            const SizedBox(height: TeaSpacing.sm),
            Row(
              children: [
                if (user.email != null && user.email!.isNotEmpty) ...[
                  Icon(Icons.email_outlined, size: 13, color: TeaColors.mediumGray),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      user.email!,
                      style: TeaTypography.labelSmall.copyWith(
                        color: TeaColors.darkGray,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: TeaSpacing.smd),
                ],
                if (timeAgo.isNotEmpty) ...[
                  Icon(Icons.access_time, size: 13, color: TeaColors.mediumGray),
                  const SizedBox(width: 4),
                  Text(
                    timeAgo,
                    style: TeaTypography.labelSmall.copyWith(
                      color: TeaColors.darkGray,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return TeaColors.alertRust;
      case UserRole.manager:
        return TeaColors.infoSky;
      case UserRole.farmer:
        return TeaColors.freshLeaf;
    }
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.manager:
        return 'MANAGER';
      case UserRole.farmer:
        return 'FARMER';
    }
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()}y ago';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}mo ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else {
      return 'Just now';
    }
  }
}
