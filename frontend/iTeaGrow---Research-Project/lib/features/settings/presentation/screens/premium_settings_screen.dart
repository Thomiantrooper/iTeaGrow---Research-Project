import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../auth/data/providers/auth_provider.dart';

/// Premium Settings Screen
class PremiumSettingsScreen extends ConsumerStatefulWidget {
  const PremiumSettingsScreen({super.key});

  @override
  ConsumerState<PremiumSettingsScreen> createState() => _PremiumSettingsScreenState();
}

class _PremiumSettingsScreenState extends ConsumerState<PremiumSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  bool _autoSync = true;
  bool _hapticFeedback = true;
  String _selectedLanguage = 'English';
  String _selectedUnit = 'Metric';

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(persistentLocaleProvider);
    _selectedLanguage = _getLanguageName(currentLocale.languageCode);

    return Scaffold(
      backgroundColor: TeaColors.mistGreen,
      appBar: AppBar(
        backgroundColor: TeaColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TeaColors.nearBlack),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings',
          style: TeaTypography.titleLarge.copyWith(color: TeaColors.nearBlack),
        ),
      ),
      body: SingleChildScrollView(
        padding: TeaSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Section
            _buildSectionHeader('Account'),
            TeaCard.elevated(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildSettingsTile(
                    icon: Icons.person_outline,
                    title: 'Profile',
                    subtitle: 'Edit your profile information',
                    onTap: () => context.push('/profile'),
                  ),
                  const Divider(height: 1),
                  _buildSettingsTile(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    subtitle: 'Update your password',
                    onTap: () => _showChangePasswordDialog(),
                  ),
                  const Divider(height: 1),
                  _buildSettingsTile(
                    icon: Icons.security,
                    title: 'Security',
                    subtitle: 'Two-factor authentication, login history',
                    onTap: () => TeaSnackbar.info(context, 'Security settings coming soon!'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: TeaSpacing.lg),

            // Preferences Section
            _buildSectionHeader('Preferences'),
            TeaCard.elevated(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildSwitchTile(
                    icon: Icons.notifications_outlined,
                    title: 'Push Notifications',
                    subtitle: 'Receive alerts and updates',
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() => _notificationsEnabled = value);
                    },
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    subtitle: 'Switch to dark theme',
                    value: _darkMode,
                    onChanged: (value) {
                      setState(() => _darkMode = value);
                      TeaSnackbar.info(context, 'Dark mode coming soon!');
                    },
                  ),
                  const Divider(height: 1),
                  _buildDropdownTile(
                    icon: Icons.language,
                    title: 'Language',
                    value: _selectedLanguage,
                    options: ['English', 'සිංහල', 'தமிழ்'],
                    onChanged: (value) {
                      setState(() => _selectedLanguage = value!);
                      final locale = _getLocaleFromName(value!);
                      ref.read(persistentLocaleProvider.notifier).setLocale(locale);
                    },
                  ),
                  const Divider(height: 1),
                  _buildDropdownTile(
                    icon: Icons.straighten,
                    title: 'Units',
                    value: _selectedUnit,
                    options: ['Metric', 'Imperial'],
                    onChanged: (value) {
                      setState(() => _selectedUnit = value!);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: TeaSpacing.lg),

            // Connectivity Section
            _buildSectionHeader('Connectivity'),
            TeaCard.elevated(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildSettingsTile(
                    icon: Icons.bluetooth,
                    title: 'IoT Devices',
                    subtitle: 'Manage connected sensors',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TeaSpacing.sm,
                        vertical: TeaSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: TeaColors.healthyGreen.withOpacity(0.1),
                        borderRadius: TeaRadius.radiusSm,
                      ),
                      child: Text(
                        '3 connected',
                        style: TeaTypography.labelSmall.copyWith(
                          color: TeaColors.healthyGreen,
                        ),
                      ),
                    ),
                    onTap: () => context.push('/iot-devices'),
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    icon: Icons.sync,
                    title: 'Auto Sync',
                    subtitle: 'Automatically sync data with cloud',
                    value: _autoSync,
                    onChanged: (value) {
                      setState(() => _autoSync = value);
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingsTile(
                    icon: Icons.wifi,
                    title: 'Network Settings',
                    subtitle: 'Configure WiFi and data usage',
                    onTap: () => TeaSnackbar.info(context, 'Network settings coming soon!'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: TeaSpacing.lg),

            // App Settings Section
            _buildSectionHeader('App Settings'),
            TeaCard.elevated(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildSwitchTile(
                    icon: Icons.vibration,
                    title: 'Haptic Feedback',
                    subtitle: 'Vibration on interactions',
                    value: _hapticFeedback,
                    onChanged: (value) {
                      setState(() => _hapticFeedback = value);
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingsTile(
                    icon: Icons.storage,
                    title: 'Storage',
                    subtitle: 'Manage cached data and downloads',
                    trailing: Text(
                      '245 MB',
                      style: TeaTypography.bodySmall.copyWith(
                        color: TeaColors.darkGray,
                      ),
                    ),
                    onTap: () => _showClearCacheDialog(),
                  ),
                  const Divider(height: 1),
                  _buildSettingsTile(
                    icon: Icons.download,
                    title: 'Export Data',
                    subtitle: 'Download your plantation data',
                    onTap: () => TeaSnackbar.info(context, 'Export feature coming soon!'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: TeaSpacing.lg),

            // Support Section
            _buildSectionHeader('Support'),
            TeaCard.elevated(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildSettingsTile(
                    icon: Icons.help_outline,
                    title: 'Help Center',
                    subtitle: 'FAQs and guides',
                    onTap: () => TeaSnackbar.info(context, 'Help center coming soon!'),
                  ),
                  const Divider(height: 1),
                  _buildSettingsTile(
                    icon: Icons.feedback_outlined,
                    title: 'Send Feedback',
                    subtitle: 'Help us improve the app',
                    onTap: () => _showFeedbackDialog(),
                  ),
                  const Divider(height: 1),
                  _buildSettingsTile(
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle: 'Version 1.0.0',
                    onTap: () => _showAboutDialog(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: TeaSpacing.lg),

            // Danger Zone
            _buildSectionHeader('Danger Zone'),
            TeaCard.outlined(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildSettingsTile(
                    icon: Icons.logout,
                    title: 'Log Out',
                    subtitle: 'Sign out from your account',
                    iconColor: TeaColors.alertRust,
                    titleColor: TeaColors.alertRust,
                    onTap: () => _showLogoutDialog(),
                  ),
                  const Divider(height: 1),
                  _buildSettingsTile(
                    icon: Icons.delete_forever,
                    title: 'Delete Account',
                    subtitle: 'Permanently delete your account',
                    iconColor: TeaColors.criticalRed,
                    titleColor: TeaColors.criticalRed,
                    onTap: () => _showDeleteAccountDialog(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: TeaSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: TeaSpacing.xs,
        bottom: TeaSpacing.sm,
      ),
      child: Text(
        title.toUpperCase(),
        style: TeaTypography.labelMedium.copyWith(
          color: TeaColors.darkGray,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    Color? iconColor,
    Color? titleColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? TeaColors.freshLeaf),
      title: Text(
        title,
        style: TeaTypography.titleSmall.copyWith(
          color: titleColor ?? TeaColors.nearBlack,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TeaTypography.bodySmall.copyWith(
          color: TeaColors.darkGray,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: TeaColors.mediumGray),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: TeaColors.freshLeaf),
      title: Text(
        title,
        style: TeaTypography.titleSmall,
      ),
      subtitle: Text(
        subtitle,
        style: TeaTypography.bodySmall.copyWith(
          color: TeaColors.darkGray,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: TeaColors.freshLeaf,
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: TeaColors.freshLeaf),
      title: Text(
        title,
        style: TeaTypography.titleSmall,
      ),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: options.map((option) {
          return DropdownMenuItem(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'si':
        return 'සිංහල';
      case 'ta':
        return 'தமிழ்';
      default:
        return 'English';
    }
  }

  Locale _getLocaleFromName(String name) {
    switch (name) {
      case 'සිංහල':
        return const Locale('si');
      case 'தமிழ்':
        return const Locale('ta');
      default:
        return const Locale('en');
    }
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password'),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm New Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              TeaSnackbar.success(context, 'Password changed successfully!');
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear all cached data and downloaded files. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              TeaSnackbar.success(context, 'Cache cleared successfully!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TeaColors.alertRust,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Tell us what you think...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              TeaSnackbar.success(context, 'Thank you for your feedback!');
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.eco, color: TeaColors.freshLeaf),
            const SizedBox(width: 8),
            const Text('iTeaGrow'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Version 1.0.0'),
            const SizedBox(height: 8),
            const Text('AI-Powered Tea Plantation Management System'),
            const SizedBox(height: 16),
            Text(
              '© 2024 iTeaGrow Research Project',
              style: TextStyle(color: TeaColors.darkGray),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authStateProvider.notifier).logout();
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TeaColors.alertRust,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all associated data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              TeaSnackbar.info(context, 'Account deletion is disabled in demo mode.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TeaColors.criticalRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
