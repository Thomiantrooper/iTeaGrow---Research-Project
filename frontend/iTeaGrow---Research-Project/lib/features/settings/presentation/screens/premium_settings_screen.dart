import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iteagrow/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../auth/data/providers/auth_provider.dart';

/// Premium Settings Screen
class PremiumSettingsScreen extends ConsumerStatefulWidget {
  final bool allowBiometricAndPin;

  const PremiumSettingsScreen({
    super.key,
    this.allowBiometricAndPin = true,
  });

  @override
  ConsumerState<PremiumSettingsScreen> createState() =>
      _PremiumSettingsScreenState();
}

class _PremiumSettingsScreenState extends ConsumerState<PremiumSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _pinEnabled = false;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final authNotifier = ref.read(authStateProvider.notifier);
    final available = await authNotifier.isBiometricAvailable();
    final enabled = authNotifier.isBiometricEnabled;
    final pinEnabled =
        await ref.read(authStateProvider.notifier).isPinLoginEnabled();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
        _pinEnabled = pinEnabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          l10n.settings_title,
          style: TeaTypography.titleLarge.copyWith(color: TeaColors.nearBlack),
        ),
      ),
      body: SingleChildScrollView(
        padding: TeaSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Section
            _buildSectionHeader(l10n.settings_section_account),
            TeaCard.elevated(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildSettingsTile(
                    icon: Icons.person_outline,
                    title: l10n.settings_profile,
                    subtitle: l10n.settings_profile_sub,
                    onTap: () => context.push('/profile'),
                  ),
                  const Divider(height: 1),
                  _buildSettingsTile(
                    icon: Icons.lock_outline,
                    title: l10n.settings_change_password,
                    subtitle: l10n.settings_change_password_sub,
                    onTap: () => _showChangePasswordDialog(),
                  ),
                  if (widget.allowBiometricAndPin && _biometricAvailable) ...[
                    const Divider(height: 1),
                    _buildSwitchTile(
                      icon: Icons.fingerprint,
                      title: l10n.settings_biometric,
                      subtitle: _biometricEnabled
                          ? l10n.settings_biometric_enabled_sub
                          : l10n.settings_biometric_disabled_sub,
                      value: _biometricEnabled,
                      onChanged: (value) {
                        if (value) {
                          _showEnableBiometricDialog();
                        } else {
                          _disableBiometric();
                        }
                      },
                    ),
                  ],
                  if (widget.allowBiometricAndPin) ...[
                    const Divider(height: 1),
                    _buildSwitchTile(
                      icon: Icons.pin_outlined,
                      title: l10n.settings_pin,
                      subtitle: _pinEnabled
                          ? l10n.settings_pin_enabled_sub
                          : l10n.settings_pin_disabled_sub,
                      value: _pinEnabled,
                      onChanged: (value) {
                        if (value) {
                          _showEnablePinDialog();
                        } else {
                          _disablePin();
                        }
                      },
                    ),
                    if (_pinEnabled) ...[
                      const Divider(height: 1),
                      _buildSettingsTile(
                        icon: Icons.lock_reset,
                        title: l10n.settings_change_pin,
                        subtitle: l10n.settings_change_pin_sub,
                        onTap: _showChangePinDialog,
                      ),
                    ],
                  ],
                ],
              ),
            ),

            const SizedBox(height: TeaSpacing.lg),

            // Preferences Section
            _buildSectionHeader(l10n.settings_section_preferences),
            TeaCard.elevated(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildSwitchTile(
                    icon: Icons.notifications_outlined,
                    title: l10n.settings_notifications,
                    subtitle: l10n.settings_notifications_sub,
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() => _notificationsEnabled = value);
                    },
                  ),
                  const Divider(height: 1),
                  _buildDropdownTile(
                    icon: Icons.language,
                    title: l10n.settings_language,
                    value: _selectedLanguage,
                    options: ['English', 'සිංහල', 'தமிழ்'],
                    onChanged: (value) {
                      setState(() => _selectedLanguage = value!);
                      final locale = _getLocaleFromName(value!);
                      ref
                          .read(persistentLocaleProvider.notifier)
                          .setLocale(locale);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: TeaSpacing.lg),

            // Connectivity Section
            _buildSectionHeader(l10n.settings_section_connectivity),
            TeaCard.elevated(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildSettingsTile(
                    icon: Icons.bluetooth,
                    title: l10n.settings_iot_devices,
                    subtitle: l10n.settings_iot_devices_sub,
                    onTap: () => context.push('/iot-devices'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: TeaSpacing.lg),

            // Support Section
            _buildSectionHeader(l10n.settings_section_support),
            TeaCard.elevated(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildSettingsTile(
                    icon: Icons.help_outline,
                    title: l10n.settings_help,
                    subtitle: l10n.settings_help_sub,
                    onTap: () => context.push('/help-center'),
                  ),
                  const Divider(height: 1),
                  _buildSettingsTile(
                    icon: Icons.info_outline,
                    title: l10n.settings_about,
                    subtitle: l10n.settings_about_sub,
                    onTap: () => _showAboutDialog(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: TeaSpacing.lg),

            // Danger Zone
            _buildSectionHeader(l10n.settings_section_danger),
            TeaCard.outlined(
              padding: EdgeInsets.zero,
              child: _buildSettingsTile(
                icon: Icons.logout,
                title: l10n.settings_logout,
                subtitle: l10n.settings_logout_sub,
                iconColor: TeaColors.alertRust,
                titleColor: TeaColors.alertRust,
                onTap: () => _showLogoutDialog(),
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
      trailing: trailing ??
          const Icon(Icons.chevron_right, color: TeaColors.mediumGray),
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
        thumbColor: WidgetStatePropertyAll(TeaColors.freshLeaf),
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settings_dialog_change_password),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.settings_dialog_current_password),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.settings_dialog_new_password),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.settings_dialog_confirm_password),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.common_cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              TeaSnackbar.success(context, l10n.settings_dialog_password_changed);
            },
            child: Text(l10n.settings_dialog_change),
          ),
        ],
      ),
    );
  }



  void _showAboutDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.eco, color: TeaColors.freshLeaf),
            SizedBox(width: 8),
            Text('iTeaGrow'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 2.0.0'),
            const SizedBox(height: 8),
            const Text('AI-Powered Tea Plantation Management System'),
            const SizedBox(height: 8),
            const Text(
              'Helping Sri Lankan tea farmers and estate managers make smarter, data-driven decisions — from leaf to market.',
            ),
            const SizedBox(height: 16),
            const Text(
              '© 2026 iTeaGrow Research Project',
              style: TextStyle(color: TeaColors.darkGray),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.settings_dialog_close),
          ),
        ],
      ),
    );
  }

  void _showEnableBiometricDialog() {
    final l10n = AppLocalizations.of(context)!;
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settings_dialog_biometric),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.settings_dialog_biometric_desc),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.settings_dialog_password,
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.common_cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(authStateProvider.notifier)
                  .enableBiometricLogin(passwordController.text);
              if (mounted) {
                if (success) {
                  setState(() => _biometricEnabled = true);
                  TeaSnackbar.success(context, l10n.settings_biometric_enabled_msg);
                } else {
                  final error = ref.read(authStateProvider).errorMessage;
                  TeaSnackbar.error(
                      context, error ?? l10n.settings_biometric_login_failed);
                }
              }
              passwordController.dispose();
            },
            child: Text(l10n.settings_dialog_enable),
          ),
        ],
      ),
    );
  }

  Future<void> _disableBiometric() async {
    final l10n = AppLocalizations.of(context)!;
    await ref.read(authStateProvider.notifier).disableBiometricLogin();
    if (mounted) {
      setState(() => _biometricEnabled = false);
      TeaSnackbar.info(context, l10n.settings_biometric_disabled_msg);
    }
  }

  void _showLogoutDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settings_logout),
        content: Text(l10n.settings_dialog_logout_desc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.common_cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authStateProvider.notifier).logout();
              if (mounted) {
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TeaColors.alertRust,
            ),
            child: Text(l10n.settings_logout_btn),
          ),
        ],
      ),
    );
  }

  void _showChangePinDialog() {
    final l10n = AppLocalizations.of(context)!;
    final passwordController = TextEditingController();
    final newPinController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.settings_dialog_change_pin),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.settings_dialog_change_pin_desc),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.settings_dialog_account_password,
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return l10n.settings_required;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 8,
                decoration: InputDecoration(
                  labelText: l10n.settings_dialog_new_pin,
                  prefixIcon: const Icon(Icons.pin),
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return l10n.settings_pin_required;
                  if (value.length < 4) return l10n.settings_pin_too_short;
                  if (value.length > 8) return l10n.settings_pin_too_long;
                  if (!RegExp(r'^[0-9]+$').hasMatch(value))
                    return l10n.settings_pin_numbers_only;
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.common_cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                final success = await ref
                    .read(authStateProvider.notifier)
                    .enablePinLogin(
                        passwordController.text, newPinController.text);

                if (mounted) {
                  if (success) {
                    TeaSnackbar.success(context, l10n.settings_pin_changed_msg);
                  } else {
                    final error = ref.read(authStateProvider).errorMessage;
                    TeaSnackbar.error(context, error ?? l10n.settings_pin_change_failed);
                  }
                }
                passwordController.dispose();
                newPinController.dispose();
              }
            },
            child: Text(l10n.settings_changing_pin_btn),
          ),
        ],
      ),
    );
  }

  void _showEnablePinDialog() {
    final l10n = AppLocalizations.of(context)!;
    final passwordController = TextEditingController();
    final pinController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.settings_dialog_enable_pin),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.settings_dialog_enable_pin_desc),
              const SizedBox(height: 16),
              TextFormField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 8,
                decoration: InputDecoration(
                  labelText: l10n.settings_dialog_new_pin,
                  prefixIcon: const Icon(Icons.pin),
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return l10n.settings_pin_required;
                  if (value.length < 4) return l10n.settings_pin_too_short;
                  if (value.length > 8) return l10n.settings_pin_too_long;
                  if (!RegExp(r'^[0-9]+$').hasMatch(value))
                    return l10n.settings_pin_numbers_only;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.settings_dialog_account_password,
                  prefixIcon: const Icon(Icons.lock_outline),
                  helperText: l10n.settings_pin_helper_text,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return l10n.settings_required;
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _pinEnabled = false);
            },
            child: Text(l10n.common_cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                // Optimistic update so the switch flips immediately after
                // the dialog closes, without waiting for the async call.
                setState(() => _pinEnabled = true);
                final success = await ref
                    .read(authStateProvider.notifier)
                    .enablePinLogin(
                        passwordController.text, pinController.text);
                if (mounted) {
                  if (success) {
                    TeaSnackbar.success(context, l10n.settings_pin_login_enabled_msg);
                  } else {
                    final error = ref.read(authStateProvider).errorMessage;
                    setState(() => _pinEnabled = false);
                    TeaSnackbar.error(
                        context, error ?? l10n.settings_pin_login_failed);
                  }
                }
                passwordController.dispose();
                pinController.dispose();
              }
            },
            child: Text(l10n.settings_dialog_enable),
          ),
        ],
      ),
    );
  }

  Future<void> _disablePin() async {
    final l10n = AppLocalizations.of(context)!;
    await ref.read(authStateProvider.notifier).disablePinLogin();
    if (mounted) {
      setState(() => _pinEnabled = false);
      TeaSnackbar.info(context, l10n.settings_pin_login_disabled_msg);
    }
  }
}
