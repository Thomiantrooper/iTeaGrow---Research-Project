import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../data/providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and conditions'),
          backgroundColor: TeaColors.alertRust,
        ),
      );
      return;
    }

    final authNotifier = ref.read(authStateProvider.notifier);

    final success = await authNotifier.register(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      phone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
    );

    if (success && mounted) {
      // Navigate to dashboard
      context.go('/farmer-dashboard');
    } else if (mounted) {
      final errorMessage = ref.read(authStateProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Registration failed'),
          backgroundColor: TeaColors.alertRust,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: TeaColors.mistGreen,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TeaSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Back Button
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  color: TeaColors.nearBlack,
                ),
              ),

              const SizedBox(height: TeaSpacing.md),

              // Logo and Title
              _buildHeader(),

              const SizedBox(height: TeaSpacing.xl),

              // Registration Form
              _buildForm(isLoading),

              const SizedBox(height: TeaSpacing.lg),

              // Login Link
              _buildLoginLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [TeaColors.freshLeaf, TeaColors.matureLeaf],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: TeaRadius.radiusLg,
            boxShadow: [
              BoxShadow(
                color: TeaColors.freshLeaf.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_add_outlined,
            color: TeaColors.white,
            size: 40,
          ),
        ).animate().scale(
              duration: 600.ms,
              curve: Curves.elasticOut,
            ),

        const SizedBox(height: TeaSpacing.md),

        Text(
          'Create Account',
          style: TeaTypography.headlineMedium.copyWith(
            color: TeaColors.nearBlack,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: TeaSpacing.xs),

        Text(
          'Join iTeaGrow to manage your tea plantation',
          style: TeaTypography.bodyMedium.copyWith(
            color: TeaColors.darkGray,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _buildForm(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(TeaSpacing.lg),
      decoration: BoxDecoration(
        color: TeaColors.white,
        borderRadius: TeaRadius.radiusLg,
        boxShadow: const [
          BoxShadow(
            color: TeaColors.shadowVale,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Full Name Field
            _buildTextField(
              controller: _fullNameController,
              label: 'Full Name',
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your full name';
                }
                if (value.length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: TeaSpacing.md),

            // Username Field
            _buildTextField(
              controller: _usernameController,
              label: 'Username',
              icon: Icons.alternate_email,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a username';
                }
                if (value.length < 3) {
                  return 'Username must be at least 3 characters';
                }
                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                  return 'Username can only contain letters, numbers, and underscores';
                }
                return null;
              },
            ),

            const SizedBox(height: TeaSpacing.md),

            // Email Field (Optional)
            _buildTextField(
              controller: _emailController,
              label: 'Email (Optional)',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                }
                return null;
              },
            ),

            const SizedBox(height: TeaSpacing.md),

            // Phone Field (Optional)
            _buildTextField(
              controller: _phoneController,
              label: 'Phone (Optional)',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: TeaSpacing.md),

            // Password Field
            _buildTextField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: TeaColors.mediumGray,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: TeaSpacing.md),

            // Confirm Password Field
            _buildTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              icon: Icons.lock_outline,
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: TeaColors.mediumGray,
                ),
                onPressed: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),

            const SizedBox(height: TeaSpacing.md),

            // Terms and Conditions
            Row(
              children: [
                Checkbox(
                  value: _acceptTerms,
                  onChanged: (value) => setState(() => _acceptTerms = value ?? false),
                  activeColor: TeaColors.freshLeaf,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                    child: Text.rich(
                      TextSpan(
                        text: 'I agree to the ',
                        style: TeaTypography.bodySmall,
                        children: [
                          TextSpan(
                            text: 'Terms and Conditions',
                            style: TeaTypography.bodySmall.copyWith(
                              color: TeaColors.freshLeaf,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: TeaSpacing.lg),

            // Register Button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TeaColors.freshLeaf,
                  foregroundColor: TeaColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: TeaRadius.radiusMd,
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: TeaColors.white,
                        ),
                      )
                    : Text(
                        'Create Account',
                        style: TeaTypography.titleSmall.copyWith(
                          color: TeaColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: TeaTypography.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TeaTypography.bodyMedium.copyWith(
          color: TeaColors.mediumGray,
        ),
        prefixIcon: Icon(icon, color: TeaColors.freshLeaf),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: TeaColors.leafPale,
        border: OutlineInputBorder(
          borderRadius: TeaRadius.radiusMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: TeaRadius.radiusMd,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: TeaRadius.radiusMd,
          borderSide: const BorderSide(color: TeaColors.freshLeaf, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: TeaRadius.radiusMd,
          borderSide: const BorderSide(color: TeaColors.alertRust, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: TeaRadius.radiusMd,
          borderSide: const BorderSide(color: TeaColors.alertRust, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TeaSpacing.md,
          vertical: TeaSpacing.md,
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TeaTypography.bodyMedium.copyWith(
            color: TeaColors.darkGray,
          ),
        ),
        TextButton(
          onPressed: () => context.pop(),
          child: Text(
            'Sign In',
            style: TeaTypography.bodyMedium.copyWith(
              color: TeaColors.freshLeaf,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }
}
