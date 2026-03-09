import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/validators/tea_validators.dart';
import '../../../../core/enums/app_enums.dart';
import '../../data/providers/auth_provider.dart';
import 'package:iteagrow/l10n/app_localizations.dart';

/// Premium Login Screen with glass-morphism and animations
class PremiumLoginScreen extends ConsumerStatefulWidget {
  const PremiumLoginScreen({super.key});

  @override
  ConsumerState<PremiumLoginScreen> createState() => _PremiumLoginScreenState();
}

class _PremiumLoginScreenState extends ConsumerState<PremiumLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _rememberMe = false;
  String? _errorMessage;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _pinEnabled = false;

  // PIN Input State
  bool _isEnteringPin = false;
  String _enteredPin = '';

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    final authNotifier = ref.read(authStateProvider.notifier);
    final available = await authNotifier.isBiometricAvailable();
    final enabled = authNotifier.isBiometricEnabled;
    final pinEnabled = authNotifier.isPinEnabled;

    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
        _pinEnabled = pinEnabled;
      });
    }
  }

  Future<void> _handleLogin() async {
    final l10n = AppLocalizations.of(context)!;
    // Clear previous error
    setState(() => _errorMessage = null);

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authNotifier = ref.read(authStateProvider.notifier);
      final success = await authNotifier.login(
        _usernameController.text.trim(),
        _passwordController.text,
        rememberMe: _rememberMe,
      );

      if (success && mounted) {
        // Navigate based on user role
        final authState = ref.read(authStateProvider);
        final user = authState.user;
        if (user != null) {
          switch (user.role) {
            case UserRole.admin:
              context.go('/dashboard/admin');
              break;
            case UserRole.manager:
              context.go('/dashboard/manager');
              break;
            case UserRole.farmer:
              context.go('/dashboard/farmer');
              break;
          }
        }
      } else if (mounted) {
        final authState = ref.read(authStateProvider);
        setState(() {
          _errorMessage =
              authState.errorMessage ?? l10n.login_error;
        });
        // Shake animation on error
        _formKey.currentState?.validate();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = l10n.login_error_generic;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handlePinLoginButton() {
    setState(() {
      _isEnteringPin = true;
      _enteredPin = '';
      _errorMessage = null;
    });
  }

  void _onPinDigitPressed(String digit) {
    if (_enteredPin.length < 8) {
      setState(() {
        _enteredPin += digit;
        _errorMessage = null;
      });

      // Auto-submit if we reach 8 digits (or let user press enter for less)
      if (_enteredPin.length == 8) {
        _submitPin();
      }
    }
  }

  void _onPinBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _submitPin() async {
    final l10n = AppLocalizations.of(context)!;
    if (_enteredPin.length < 4) {
      setState(() {
        _errorMessage = l10n.login_pin_min_digits;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authNotifier = ref.read(authStateProvider.notifier);
      final success = await authNotifier.loginWithPin(_enteredPin);

      if (success && mounted) {
        // Navigation will be handled by router redirect
      } else if (mounted) {
        final authState = ref.read(authStateProvider);
        setState(() {
          _errorMessage = authState.errorMessage ?? l10n.login_pin_invalid;
          _enteredPin = ''; // Reset on failure
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = l10n.login_pin_failed;
          _enteredPin = '';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final authNotifier = ref.read(authStateProvider.notifier);
      final success = await authNotifier.loginWithBiometrics();

      if (success && mounted) {
        // Navigation will be handled by router redirect
      } else if (mounted) {
        final authState = ref.read(authStateProvider);
        setState(() {
          _errorMessage =
              authState.errorMessage ?? l10n.login_biometric_failed_auth;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = l10n.login_biometric_failed;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final authNotifier = ref.read(authStateProvider.notifier);
      final success = await authNotifier.loginWithGoogle();

      if (success && mounted) {
        // Navigation will be handled by router redirect
      } else if (mounted) {
        final authState = ref.read(authStateProvider);
        setState(() {
          _errorMessage = authState.errorMessage ?? l10n.login_google_failed;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = l10n.login_google_failed_retry;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Scaffold(
      body: Stack(
        children: [
          // Background
          _buildBackground(size),

          // Floating leaves decoration
          const FloatingLeavesBackground(
            leafCount: 6,
            opacity: 0.1,
            child: SizedBox.expand(),
          ),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: TeaSpacing.screenPadding,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isSmallScreen) ...[
                      // Logo
                      _buildLogo(),
                      const SizedBox(height: TeaSpacing.xxl),
                    ],

                    // Main Card (Login or PIN)
                    _isEnteringPin
                        ? _buildPinCard(isSmallScreen)
                        : _buildLoginCard(isSmallScreen),

                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(Size size) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TeaColors.mistGreen,
            TeaColors.white,
            TeaColors.leafPale,
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(TeaSpacing.md),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: TeaColors.white,
            boxShadow: TeaShadows.cardShadowMedium,
          ),
          child: const Icon(
            Icons.eco,
            size: 48,
            color: TeaColors.freshLeaf,
          ),
        ).animate().fadeIn(duration: 400.ms).scale(
            begin: const Offset(0.8, 0.8),
            duration: 400.ms,
            curve: Curves.easeOutBack),
        const SizedBox(height: TeaSpacing.md),
        Text(
          'iTeaGrow',
          style: TeaTypography.headlineLarge.copyWith(
            color: TeaColors.matureLeaf,
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
        Text(
          l10n.login_app_tagline,
          style: TeaTypography.bodyMedium.copyWith(
            color: TeaColors.darkGray,
          ),
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildLoginCard(bool isSmallScreen) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: TeaCard.glass(
        padding: EdgeInsets.all(isSmallScreen ? TeaSpacing.lg : TeaSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              if (isSmallScreen) ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(TeaSpacing.sm),
                      decoration: BoxDecoration(
                        color: TeaColors.freshLeaf.withOpacity(0.1),
                        borderRadius: TeaRadius.radiusSm,
                      ),
                      child: const Icon(
                        Icons.eco,
                        color: TeaColors.freshLeaf,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: TeaSpacing.smd),
                    Text(
                      l10n.login_welcome_back_heading,
                      style: TeaTypography.headlineSmall,
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  l10n.login_welcome_back_heading,
                  style: TeaTypography.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: TeaSpacing.xs),
                Text(
                  l10n.login_subtitle,
                  style: TeaTypography.bodyMedium.copyWith(
                    color: TeaColors.darkGray,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: TeaSpacing.xl),

              // Error message
              if (_errorMessage != null) ...[
                TeaAlertCard.error(
                  title: _errorMessage!,
                  onDismiss: () => setState(() => _errorMessage = null),
                ).animate().shake(duration: 400.ms),
                const SizedBox(height: TeaSpacing.md),
              ],

              // Username field
              TeaTextField(
                controller: _usernameController,
                focusNode: _usernameFocus,
                label: l10n.login_username,
                hint: l10n.login_username_hint,
                prefixIcon: const Icon(Icons.person_outline),
                textInputAction: TextInputAction.next,
                validator: TeaValidators.username,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onSubmitted: (_) => _passwordFocus.requestFocus(),
              )
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 300.ms)
                  .slideX(begin: -0.05, end: 0),

              const SizedBox(height: TeaSpacing.md),

              // Password field
              TeaTextField.password(
                controller: _passwordController,
                focusNode: _passwordFocus,
                label: l10n.login_password,
                hint: l10n.login_password_hint,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.login_password_required;
                  }
                  return null;
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onSubmitted: (_) => _handleLogin(),
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 300.ms)
                  .slideX(begin: -0.05, end: 0),

              const SizedBox(height: TeaSpacing.md),

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () => context.push('/forgot-password'),
                  borderRadius: TeaRadius.radiusSm,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: TeaColors.freshLeaf.withOpacity(0.08),
                      borderRadius: TeaRadius.radiusSm,
                      border: Border.all(
                          color: TeaColors.freshLeaf.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_reset,
                          size: 16,
                          color: TeaColors.freshLeaf,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.login_forgot_password,
                          style: TeaTypography.bodySmall.copyWith(
                            color: TeaColors.freshLeaf,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 300.ms),

              const SizedBox(height: TeaSpacing.xl),

              // Sign in button
              TeaButton.primary(
                label: l10n.login_button,
                icon: Icons.login,
                isLoading: _isLoading,
                isFullWidth: true,
                size: TeaButtonSize.large,
                onPressed: _isLoading ? null : _handleLogin,
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 300.ms)
                  .slideY(begin: 0.1, end: 0),

              // PIN login button (if enabled)
              if (_pinEnabled) ...[
                const SizedBox(height: TeaSpacing.md),
                TeaButton.secondary(
                  label: l10n.login_sign_in_pin,
                  icon: Icons.pin_outlined,
                  isLoading: _isLoading,
                  isFullWidth: true,
                  size: TeaButtonSize.large,
                  onPressed: _isLoading ? null : _handlePinLoginButton,
                )
                    .animate()
                    .fadeIn(delay: 425.ms, duration: 300.ms)
                    .slideY(begin: 0.1, end: 0),
              ],

              // Biometric login button (if enabled)
              if (_biometricAvailable && _biometricEnabled) ...[
                const SizedBox(height: TeaSpacing.md),
                TeaButton.secondary(
                  label: l10n.login_sign_in_biometrics,
                  icon: Icons.fingerprint,
                  isLoading: _isLoading,
                  isFullWidth: true,
                  size: TeaButtonSize.large,
                  onPressed: _isLoading ? null : _handleBiometricLogin,
                )
                    .animate()
                    .fadeIn(delay: 450.ms, duration: 300.ms)
                    .slideY(begin: 0.1, end: 0),
              ],

              const SizedBox(height: TeaSpacing.lg),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: TeaSpacing.md),
                    child: Text(
                      l10n.login_or_continue_with,
                      style: TeaTypography.labelSmall,
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ).animate().fadeIn(delay: 500.ms, duration: 300.ms),

              const SizedBox(height: TeaSpacing.lg),

              // Premium Google Login Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoading ? null : _handleGoogleSignIn,
                  borderRadius: TeaRadius.radiusMd,
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: TeaSpacing.md),
                    decoration: BoxDecoration(
                      color: TeaColors.white,
                      border: Border.all(color: TeaColors.lightGray),
                      borderRadius: TeaRadius.radiusMd,
                      boxShadow: [
                        BoxShadow(
                          color: TeaColors.nearBlack.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.g_mobiledata,
                            size: 28,
                            color: TeaColors.nearBlack,
                          ),
                        ),
                        const SizedBox(width: TeaSpacing.sm),
                        Text(
                          l10n.login_continue_google,
                          style: TeaTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: TeaColors.nearBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 300.ms),

              const SizedBox(height: TeaSpacing.lg),

              // Create account link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      l10n.login_no_account,
                      style: TeaTypography.bodySmall.copyWith(
                        color: TeaColors.darkGray,
                      ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(horizontal: TeaSpacing.sm),
                    ),
                    onPressed: () => context.push('/register'),
                    child: Text(
                      l10n.login_create_account,
                      style: TeaTypography.bodySmall.copyWith(
                        color: TeaColors.freshLeaf,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 700.ms, duration: 300.ms),

              const SizedBox(height: TeaSpacing.md),

              // Contact Us Link below Register
              Center(
                child: TextButton(
                  onPressed: () => context.push('/contact-us'),
                  child: Text(
                    l10n.login_contact_support,
                    style: TeaTypography.bodySmall.copyWith(
                      color: TeaColors.darkGray,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms, duration: 300.ms),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .scale(begin: const Offset(0.95, 0.95), duration: 500.ms);
  }



  Widget _buildPinCard(bool isSmallScreen) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: TeaCard.glass(
        padding: EdgeInsets.all(isSmallScreen ? TeaSpacing.lg : TeaSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(TeaSpacing.sm),
                  decoration: BoxDecoration(
                    color: TeaColors.freshLeaf.withOpacity(0.1),
                    borderRadius: TeaRadius.radiusSm,
                  ),
                  child: const Icon(
                    Icons.pin,
                    color: TeaColors.freshLeaf,
                    size: 24,
                  ),
                ),
                const SizedBox(width: TeaSpacing.smd),
                Expanded(
                  child: Text(
                    l10n.login_pin_title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: TeaColors.nearBlack,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() {
                    _isEnteringPin = false;
                    _errorMessage = null;
                  }),
                  tooltip: 'Cancel',
                )
              ],
            ),
            const SizedBox(height: TeaSpacing.xl),

            // Error message
            if (_errorMessage != null) ...[
              TeaAlertCard.error(
                title: _errorMessage!,
                onDismiss: () => setState(() => _errorMessage = null),
              ).animate().shake(duration: 400.ms),
              const SizedBox(height: TeaSpacing.md),
            ],

            // PIN Dots Indicator
            _buildPinDots(),

            const SizedBox(height: TeaSpacing.xl),

            // Numeric Keypad
            _buildKeypad(),

            const SizedBox(height: TeaSpacing.lg),

            // Submit Button
            TeaButton.primary(
              label: l10n.login_pin_button,
              icon: Icons.login,
              isLoading: _isLoading,
              isFullWidth: true,
              size: TeaButtonSize.large,
              onPressed:
                  _isLoading || _enteredPin.length < 4 ? null : _submitPin,
            ).animate().fadeIn(duration: 300.ms),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(8, (index) {
        bool isFilled = index < _enteredPin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled
                ? TeaColors.freshLeaf
                : TeaColors.mediumGray.withOpacity(0.3),
            border: Border.all(
              color: isFilled ? TeaColors.matureLeaf : TeaColors.mediumGray,
              width: 1,
            ),
          ),
        );
      }),
    ).animate().fadeIn();
  }

  Widget _buildKeypad() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      childAspectRatio: 1.5,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (int i = 1; i <= 9; i++) _buildKeypadButton('$i'),
        _buildKeypadButton('C', isAction: true, onTap: () {
          setState(() {
            _enteredPin = '';
            _errorMessage = null;
          });
        }),
        _buildKeypadButton('0'),
        _buildKeypadButton('<', isAction: true, onTap: _onPinBackspace),
      ],
    ).animate().fadeIn();
  }

  Widget _buildKeypadButton(String label,
      {bool isAction = false, VoidCallback? onTap}) {
    return Material(
      color: isAction ? TeaColors.white.withOpacity(0.5) : TeaColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: TeaColors.mediumGray.withOpacity(0.5),
          width: 1,
        ),
      ),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => _onPinDigitPressed(label),
        child: Center(
          child: isAction && label == '<'
              ? const Icon(Icons.backspace_outlined, color: TeaColors.nearBlack)
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: isAction ? FontWeight.bold : FontWeight.w600,
                    color: isAction && label == 'C'
                        ? TeaColors.alertRust
                        : TeaColors.nearBlack,
                  ),
                ),
        ),
      ),
    );
  }
}
