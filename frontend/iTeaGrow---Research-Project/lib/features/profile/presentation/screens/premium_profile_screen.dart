import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iteagrow/l10n/app_localizations.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/data/providers/auth_provider.dart';

/// Premium Profile Screen
class PremiumProfileScreen extends ConsumerStatefulWidget {
  const PremiumProfileScreen({super.key});

  @override
  ConsumerState<PremiumProfileScreen> createState() =>
      _PremiumProfileScreenState();
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
    _addressController = TextEditingController();
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
                decoration: const BoxDecoration(
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
                                child: const Icon(
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

                // Profile Form
                if (_isEditing) _buildEditForm() else _buildProfileInfo(),

                const SizedBox(height: TeaSpacing.xxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    final l10n = AppLocalizations.of(context)!;
    return TeaCard.elevated(
      child: Column(
        children: [
          _buildInfoRow(Icons.person_outline, l10n.profile_name_label, _nameController.text),
          const Divider(),
          _buildInfoRow(Icons.email_outlined, l10n.contact_email, _emailController.text),
          const Divider(),
          _buildInfoRow(Icons.phone_outlined, l10n.contact_phone, _phoneController.text),
          const Divider(),
          _buildInfoRow(
              Icons.location_on_outlined, l10n.contact_address, _addressController.text),
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
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: TeaCard.elevated(
        child: Column(
          children: [
            TeaTextField(
              label: l10n.profile_full_name,
              controller: _nameController,
              prefixIcon: const Icon(Icons.person_outline),
            ),
            const SizedBox(height: TeaSpacing.md),
            TeaTextField(
              label: l10n.contact_email,
              controller: _emailController,
              prefixIcon: const Icon(Icons.email_outlined),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: TeaSpacing.md),
            TeaTextField(
              label: l10n.contact_phone,
              controller: _phoneController,
              prefixIcon: const Icon(Icons.phone_outlined),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: TeaSpacing.md),
            TeaTextField(
              label: l10n.contact_address,
              controller: _addressController,
              prefixIcon: const Icon(Icons.location_on_outlined),
              maxLines: 2,
            ),
            const SizedBox(height: TeaSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: TeaButton.primary(
                label: l10n.profile_save_changes,
                icon: Icons.save,
                onPressed: _saveProfile,
              ),
            ),
          ],
        ),
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
    final l10n = AppLocalizations.of(context)!;
    switch (role.toLowerCase()) {
      case 'admin':
        return l10n.profile_role_admin;
      case 'manager':
        return l10n.profile_role_manager;
      case 'farmer':
        return l10n.profile_role_farmer;
      default:
        return l10n.profile_role_default;
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final authNotifier = ref.read(authStateProvider.notifier);

      final success = await authNotifier.updateProfile(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
      );

      if (success && mounted) {
        setState(() => _isEditing = false);
        TeaSnackbar.success(context, AppLocalizations.of(context)!.profile_updated);
      } else if (mounted) {
        TeaSnackbar.error(context, AppLocalizations.of(context)!.profile_update_failed);
      }
    }
  }
}
