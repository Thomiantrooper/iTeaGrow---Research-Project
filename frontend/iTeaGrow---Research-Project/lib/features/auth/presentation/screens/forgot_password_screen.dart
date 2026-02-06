import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/widgets/widgets.dart';

/// Forgot Password Screen
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeaColors.mistGreen,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TeaColors.nearBlack),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: TeaSpacing.screenPadding,
          child: _emailSent ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: TeaSpacing.xl),

          // Icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(TeaSpacing.xl),
              decoration: BoxDecoration(
                color: TeaColors.freshLeaf.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_reset,
                size: 64,
                color: TeaColors.freshLeaf,
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),

          const SizedBox(height: TeaSpacing.xl),

          // Title
          Text(
            'Forgot Password?',
            style: TeaTypography.headlineMedium,
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

          const SizedBox(height: TeaSpacing.sm),

          // Description
          Text(
            "Don't worry! It happens. Please enter the email address associated with your account.",
            style: TeaTypography.bodyMedium.copyWith(
              color: TeaColors.darkGray,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

          const SizedBox(height: TeaSpacing.xxl),

          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'Enter your email',
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              fillColor: TeaColors.white,
              border: OutlineInputBorder(
                borderRadius: TeaRadius.radiusMd,
                borderSide: BorderSide(color: TeaColors.lightGray),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: TeaRadius.radiusMd,
                borderSide: BorderSide(color: TeaColors.lightGray),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: TeaRadius.radiusMd,
                borderSide: BorderSide(color: TeaColors.freshLeaf, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: TeaSpacing.xl),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: TeaColors.freshLeaf,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: TeaSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: TeaRadius.radiusMd,
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Send Reset Link'),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: TeaSpacing.lg),

          // Back to Login
          Center(
            child: TextButton(
              onPressed: () => context.pop(),
              child: Text(
                'Back to Login',
                style: TeaTypography.bodyMedium.copyWith(
                  color: TeaColors.freshLeaf,
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        const SizedBox(height: TeaSpacing.xxl),

        // Success Icon
        Container(
          padding: const EdgeInsets.all(TeaSpacing.xl),
          decoration: BoxDecoration(
            color: TeaColors.healthyGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mark_email_read_outlined,
            size: 80,
            color: TeaColors.healthyGreen,
          ),
        ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.5, 0.5)),

        const SizedBox(height: TeaSpacing.xl),

        // Success Title
        Text(
          'Check Your Email',
          style: TeaTypography.headlineMedium,
          textAlign: TextAlign.center,
        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

        const SizedBox(height: TeaSpacing.sm),

        // Success Description
        Text(
          'We have sent a password reset link to:',
          style: TeaTypography.bodyMedium.copyWith(
            color: TeaColors.darkGray,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

        const SizedBox(height: TeaSpacing.sm),

        Text(
          _emailController.text,
          style: TeaTypography.titleMedium.copyWith(
            color: TeaColors.freshLeaf,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

        const SizedBox(height: TeaSpacing.xl),

        // Instructions
        TeaCard.elevated(
          padding: TeaSpacing.cardPaddingMd,
          child: Column(
            children: [
              _buildInstructionItem(
                icon: Icons.email_outlined,
                text: 'Open the email we sent you',
              ),
              const Divider(height: TeaSpacing.lg),
              _buildInstructionItem(
                icon: Icons.link,
                text: 'Click on the reset password link',
              ),
              const Divider(height: TeaSpacing.lg),
              _buildInstructionItem(
                icon: Icons.lock_outline,
                text: 'Create your new password',
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 500.ms).slideY(begin: 0.1, end: 0),

        const SizedBox(height: TeaSpacing.xl),

        // Resend Button
        TextButton.icon(
          onPressed: () {
            TeaSnackbar.success(context, 'Reset link sent again!');
          },
          icon: const Icon(Icons.refresh),
          label: const Text("Didn't receive the email? Resend"),
          style: TextButton.styleFrom(
            foregroundColor: TeaColors.freshLeaf,
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 600.ms),

        const SizedBox(height: TeaSpacing.md),

        // Back to Login Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.go('/login'),
            style: OutlinedButton.styleFrom(
              foregroundColor: TeaColors.freshLeaf,
              side: BorderSide(color: TeaColors.freshLeaf),
              padding: const EdgeInsets.symmetric(vertical: TeaSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: TeaRadius.radiusMd,
              ),
            ),
            child: const Text('Back to Login'),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 700.ms),
      ],
    );
  }

  Widget _buildInstructionItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(TeaSpacing.sm),
          decoration: BoxDecoration(
            color: TeaColors.freshLeaf.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: TeaColors.freshLeaf, size: 20),
        ),
        const SizedBox(width: TeaSpacing.md),
        Expanded(
          child: Text(
            text,
            style: TeaTypography.bodyMedium,
          ),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
        _emailSent = true;
      });
    }
  }
}
