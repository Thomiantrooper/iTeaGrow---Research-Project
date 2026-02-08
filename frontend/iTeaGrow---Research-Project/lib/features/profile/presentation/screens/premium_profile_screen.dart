import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/data/providers/auth_provider.dart';

/// Premium Profile Screen
class PremiumProfileScreen extends ConsumerStatefulWidget {
  const PremiumProfileScreen({super.key});

  @override
  ConsumerState<PremiumProfileScreen> createState() => _PremiumProfileScreenState();
}

class _PremiumProfileScreenState extends ConsumerState<PremiumProfileScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authStateProvider);
    final user = authState.user;
    _nameController = TextEditingController(text: user?.fullName ?? 'User');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _addressController = TextEditingController(text: 'Uva Province, Sri Lanka');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: TeaColors.mistGreen,
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: TeaColors.freshLeaf,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: TeaColors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isEditing ? Icons.close : Icons.edit,
                  color: TeaColors.white,
                ),
                onPressed: () {
                  setState(() => _isEditing = !_isEditing);
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      TeaColors.freshLeaf,
                      TeaColors.matureLeaf,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Avatar
                      Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: TeaColors.white,
                              boxShadow: TeaShadows.cardShadowMedium,
                            ),
                            child: Center(
                              child: Text(
                                _getInitials(user?.fullName ?? 'U'),
                                style: TeaTypography.displayMedium.copyWith(
                                  color: TeaColors.freshLeaf,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: TeaColors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: TeaShadows.buttonShadow,
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: TeaColors.freshLeaf,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: TeaSpacing.md),
                      Text(
                        user?.fullName ?? 'User',
                        style: TeaTypography.headlineMedium.copyWith(
                          color: TeaColors.white,
                        ),
                      ),
                      const SizedBox(height: TeaSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: TeaSpacing.md,
                          vertical: TeaSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: TeaColors.white.withOpacity(0.2),
                          borderRadius: TeaRadius.radiusRound,
                        ),
                        child: Text(
                          _getRoleDisplayName(user?.role.name ?? 'farmer'),
                          style: TeaTypography.labelMedium.copyWith(
                            color: TeaColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Profile Content
          SliverPadding(
            padding: TeaSpacing.screenPadding,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: TeaSpacing.md),

                // Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.eco,
                        value: '12,450',
                        label: 'Plants Managed',
                        color: TeaColors.freshLeaf,
                      ),
                    ),
                    const SizedBox(width: TeaSpacing.smd),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.camera_alt,
                        value: '234',
                        label: 'Scans Done',
                        color: TeaColors.infoSky,
                      ),
                    ),
                    const SizedBox(width: TeaSpacing.smd),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.inventory_2,
                        value: '1,245',
                        label: 'kg Harvested',
                        color: TeaColors.goldenSunlight,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 300.ms),

                const SizedBox(height: TeaSpacing.lg),

                // Profile Form
                if (_isEditing)
                  _buildEditForm()
                else
                  _buildProfileInfo(),

                const SizedBox(height: TeaSpacing.lg),

                // Achievements Section
                TeaSectionHeader(
                  title: 'Achievements',
                  icon: Icons.emoji_events_outlined,
                ),
                const SizedBox(height: TeaSpacing.sm),
                _buildAchievements(),

                const SizedBox(height: TeaSpacing.lg),

                // Activity Summary
                TeaSectionHeader(
                  title: 'Activity Summary',
                  icon: Icons.insights,
                ),
                const SizedBox(height: TeaSpacing.sm),
                _buildActivitySummary(),

                const SizedBox(height: TeaSpacing.xxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return TeaCard.elevated(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: TeaSpacing.xs),
          Text(
            value,
            style: TeaTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TeaTypography.labelSmall.copyWith(
              color: TeaColors.darkGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    return TeaCard.elevated(
      child: Column(
        children: [
          _buildInfoRow(Icons.person_outline, 'Name', _nameController.text),
          const Divider(),
          _buildInfoRow(Icons.email_outlined, 'Email', _emailController.text),
          const Divider(),
          _buildInfoRow(Icons.phone_outlined, 'Phone', _phoneController.text),
          const Divider(),
          _buildInfoRow(Icons.location_on_outlined, 'Address', _addressController.text),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TeaSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: TeaColors.freshLeaf, size: 20),
          const SizedBox(width: TeaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TeaTypography.labelSmall.copyWith(
                    color: TeaColors.darkGray,
                  ),
                ),
                Text(value, style: TeaTypography.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: TeaCard.elevated(
        child: Column(
          children: [
            TeaTextField(
              label: 'Full Name',
              controller: _nameController,
              prefixIcon: const Icon(Icons.person_outline),
            ),
            const SizedBox(height: TeaSpacing.md),
            TeaTextField(
              label: 'Email',
              controller: _emailController,
              prefixIcon: const Icon(Icons.email_outlined),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: TeaSpacing.md),
            TeaTextField(
              label: 'Phone',
              controller: _phoneController,
              prefixIcon: const Icon(Icons.phone_outlined),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: TeaSpacing.md),
            TeaTextField(
              label: 'Address',
              controller: _addressController,
              prefixIcon: const Icon(Icons.location_on_outlined),
              maxLines: 2,
            ),
            const SizedBox(height: TeaSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: TeaButton.primary(
                label: 'Save Changes',
                icon: Icons.save,
                onPressed: _saveProfile,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievements() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildAchievementBadge(
            icon: Icons.eco,
            title: 'Green Thumb',
            subtitle: '1000+ plants',
            color: TeaColors.healthyGreen,
            isEarned: true,
          ),
          _buildAchievementBadge(
            icon: Icons.camera_alt,
            title: 'Scanner Pro',
            subtitle: '100+ scans',
            color: TeaColors.infoSky,
            isEarned: true,
          ),
          _buildAchievementBadge(
            icon: Icons.local_florist,
            title: 'Disease Fighter',
            subtitle: '50+ detections',
            color: TeaColors.alertRust,
            isEarned: true,
          ),
          _buildAchievementBadge(
            icon: Icons.analytics,
            title: 'Data Analyst',
            subtitle: 'View 500 reports',
            color: TeaColors.mediumGray,
            isEarned: false,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isEarned,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: TeaSpacing.smd),
      child: Opacity(
        opacity: isEarned ? 1.0 : 0.4,
        child: TeaCard.elevated(
          padding: TeaSpacing.cardPaddingMd,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(TeaSpacing.md),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: TeaSpacing.sm),
              Text(
                title,
                style: TeaTypography.titleSmall,
              ),
              Text(
                subtitle,
                style: TeaTypography.labelSmall.copyWith(
                  color: TeaColors.darkGray,
                ),
              ),
              if (isEarned)
                Padding(
                  padding: const EdgeInsets.only(top: TeaSpacing.xs),
                  child: Icon(
                    Icons.verified,
                    color: TeaColors.healthyGreen,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivitySummary() {
    return TeaCard.elevated(
      child: Column(
        children: [
          _buildActivityRow('This Week', '23 scans', '156 kg harvested'),
          const Divider(),
          _buildActivityRow('This Month', '87 scans', '623 kg harvested'),
          const Divider(),
          _buildActivityRow('This Year', '892 scans', '5,420 kg harvested'),
        ],
      ),
    );
  }

  Widget _buildActivityRow(String period, String scans, String harvest) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TeaSpacing.sm),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              period,
              style: TeaTypography.titleSmall,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  scans,
                  style: TeaTypography.bodyMedium.copyWith(
                    color: TeaColors.infoSky,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Scans',
                  style: TeaTypography.labelSmall.copyWith(
                    color: TeaColors.darkGray,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  harvest,
                  style: TeaTypography.bodyMedium.copyWith(
                    color: TeaColors.goldenSunlight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Harvest',
                  style: TeaTypography.labelSmall.copyWith(
                    color: TeaColors.darkGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrator';
      case 'manager':
        return 'Plantation Manager';
      case 'farmer':
      default:
        return 'Field Officer';
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final authNotifier = ref.read(authStateProvider.notifier);

      final success = await authNotifier.updateProfile(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      );

      if (success && mounted) {
        setState(() => _isEditing = false);
        TeaSnackbar.success(context, 'Profile updated successfully!');
      } else if (mounted) {
        TeaSnackbar.error(context, 'Failed to update profile');
      }
    }
  }
}
