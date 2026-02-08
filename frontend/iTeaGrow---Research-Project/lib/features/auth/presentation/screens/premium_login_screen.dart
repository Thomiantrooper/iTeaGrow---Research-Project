import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/validators/tea_validators.dart';
import '../../../../core/animations/tea_animations.dart';
import '../../../../core/enums/app_enums.dart';
import '../../data/providers/auth_provider.dart';

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
    
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
      });
    }
  }

  Future<void> _handleLogin() async {
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
          _errorMessage = authState.errorMessage ?? 'Invalid username or password';
        });
        // Shake animation on error
        _formKey.currentState?.validate();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
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
          _errorMessage = authState.errorMessage ?? 'Biometric authentication failed';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Biometric login failed. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
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
          _errorMessage = authState.errorMessage ?? 'Google Sign-In failed';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Google Sign-In failed. Please try again.';
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

                    // Login Card
                    _buildLoginCard(isSmallScreen),

                    const SizedBox(height: TeaSpacing.lg),

                    // Demo credentials hint
                    _buildDemoHint(),
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
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(begin: const Offset(0.8, 0.8), duration: 400.ms, curve: Curves.easeOutBack),
        const SizedBox(height: TeaSpacing.md),
        Text(
          'iTeaGrow',
          style: TeaTypography.headlineLarge.copyWith(
            color: TeaColors.matureLeaf,
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
        Text(
          'Tea Plantation Management',
          style: TeaTypography.bodyMedium.copyWith(
            color: TeaColors.darkGray,
          ),
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildLoginCard(bool isSmallScreen) {
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
                      'Welcome Back',
                      style: TeaTypography.headlineSmall,
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  'Welcome Back',
                  style: TeaTypography.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: TeaSpacing.xs),
                Text(
                  'Sign in to continue to your plantation',
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
                label: 'Username',
                hint: 'Enter your username',
                prefixIcon: const Icon(Icons.person_outline),
                textInputAction: TextInputAction.next,
                validator: TeaValidators.username,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onSubmitted: (_) => _passwordFocus.requestFocus(),
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideX(begin: -0.05, end: 0),

              const SizedBox(height: TeaSpacing.md),

              // Password field
              TeaTextField.password(
                controller: _passwordController,
                focusNode: _passwordFocus,
                label: 'Password',
                hint: 'Enter your password',
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  return null;
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onSubmitted: (_) => _handleLogin(),
              ).animate().fadeIn(delay: 200.ms, duration: 300.ms).slideX(begin: -0.05, end: 0),

              const SizedBox(height: TeaSpacing.md),

              // Remember me & Forgot password
              Row(
                children: [
                  // Remember me
                  GestureDetector(
                    onTap: () => setState(() => _rememberMe = !_rememberMe),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _rememberMe
                                ? TeaColors.freshLeaf
                                : Colors.transparent,
                            border: Border.all(
                              color: _rememberMe
                                  ? TeaColors.freshLeaf
                                  : TeaColors.mediumGray,
                              width: 2,
                            ),
                            borderRadius: TeaRadius.radiusXs,
                          ),
                          child: _rememberMe
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: TeaColors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: TeaSpacing.sm),
                        Text(
                          'Remember me',
                          style: TeaTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Forgot password
                  TextButton(
                    onPressed: () {
                      context.push('/forgot-password');
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TeaTypography.bodySmall.copyWith(
                        color: TeaColors.freshLeaf,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms, duration: 300.ms),

              const SizedBox(height: TeaSpacing.xl),

              // Sign in button
              TeaButton.primary(
                label: 'Sign In',
                icon: Icons.login,
                isLoading: _isLoading,
                isFullWidth: true,
                size: TeaButtonSize.large,
                onPressed: _isLoading ? null : _handleLogin,
              ).animate().fadeIn(delay: 400.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),

              // Biometric login button (if enabled)
              if (_biometricAvailable && _biometricEnabled) ...[
                const SizedBox(height: TeaSpacing.md),
                TeaButton.secondary(
                  label: 'Sign In with Biometrics',
                  icon: Icons.fingerprint,
                  isLoading: _isLoading,
                  isFullWidth: true,
                  size: TeaButtonSize.large,
                  onPressed: _isLoading ? null : _handleBiometricLogin,
                ).animate().fadeIn(delay: 450.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),
              ],

              const SizedBox(height: TeaSpacing.lg),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: TeaSpacing.md),
                    child: Text(
                      'Or continue with',
                      style: TeaTypography.labelSmall,
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ).animate().fadeIn(delay: 500.ms, duration: 300.ms),

              const SizedBox(height: TeaSpacing.lg),

              // Social login buttons (placeholder)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialButton(Icons.g_mobiledata, 'Google'),
                  const SizedBox(width: TeaSpacing.md),
                  _buildSocialButton(Icons.apple, 'Apple'),
                  const SizedBox(width: TeaSpacing.md),
                  _buildSocialButton(Icons.business, 'SSO'),
                ],
              ).animate().fadeIn(delay: 600.ms, duration: 300.ms),

              const SizedBox(height: TeaSpacing.lg),

              // Create account link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TeaTypography.bodySmall.copyWith(
                      color: TeaColors.darkGray,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/register'),
                    child: Text(
                      'Create Account',
                      style: TeaTypography.bodySmall.copyWith(
                        color: TeaColors.freshLeaf,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 700.ms, duration: 300.ms),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95), duration: 500.ms);
  }

  Widget _buildSocialButton(IconData icon, String label) {
    return Tooltip(
      message: 'Sign in with $label',
      child: InkWell(
        onTap: _isLoading
            ? null
            : () {
                if (label == 'Google') {
                  _handleGoogleSignIn();
                } else {
                  TeaSnackbar.info(context, '$label sign in coming soon!');
                }
              },
        borderRadius: TeaRadius.radiusSm,
        child: Container(
          padding: const EdgeInsets.all(TeaSpacing.smd),
          decoration: BoxDecoration(
            border: Border.all(color: TeaColors.lightGray),
            borderRadius: TeaRadius.radiusSm,
          ),
          child: Icon(
            icon,
            size: 24,
            color: _isLoading ? TeaColors.mediumGray : TeaColors.darkGray,
          ),
        ),
      ),
    );
  }

  Widget _buildDemoHint() {
    return Container(
      padding: TeaSpacing.cardPaddingMd,
      decoration: BoxDecoration(
        color: TeaColors.infoSky.withOpacity(0.1),
        borderRadius: TeaRadius.radiusMd,
        border: Border.all(
          color: TeaColors.infoSky.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 16,
                color: TeaColors.infoSky,
              ),
              const SizedBox(width: TeaSpacing.xs),
              Text(
                'Demo Credentials',
                style: TeaTypography.labelMedium.copyWith(
                  color: TeaColors.infoSky,
                ),
              ),
            ],
          ),
          const SizedBox(height: TeaSpacing.sm),
          _buildCredentialRow('Admin', 'admin', 'admin123'),
          _buildCredentialRow('Manager', 'manager', 'manager123'),
          _buildCredentialRow('Farmer', 'farmer', 'farmer123'),
        ],
      ),
    ).animate().fadeIn(delay: 700.ms, duration: 400.ms);
  }

  Widget _buildCredentialRow(String role, String username, String password) {
    return Padding(
      padding: const EdgeInsets.only(top: TeaSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              role,
              style: TeaTypography.labelSmall.copyWith(
                color: TeaColors.darkGray,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                _usernameController.text = username;
                _passwordController.text = password;
                TeaSnackbar.info(context, '$role credentials filled');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TeaSpacing.sm,
                  vertical: TeaSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: TeaColors.white.withOpacity(0.5),
                  borderRadius: TeaRadius.radiusXs,
                ),
                child: Text(
                  '$username / $password',
                  style: TeaTypography.dataSmall.copyWith(
                    color: TeaColors.darkGray,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
