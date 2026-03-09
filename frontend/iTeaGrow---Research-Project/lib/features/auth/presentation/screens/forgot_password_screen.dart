import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import 'package:iteagrow/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
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
              child: const Icon(
                Icons.lock_reset,
                size: 64,
                color: TeaColors.freshLeaf,
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),

          const SizedBox(height: TeaSpacing.xl),

          // Title
          Text(
            l10n.forgot_title,
            style: TeaTypography.headlineMedium,
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

          const SizedBox(height: TeaSpacing.sm),

          // Description
          Text(
            l10n.forgot_description,
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
              labelText: l10n.forgot_email_label,
              hintText: l10n.forgot_email_hint,
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              fillColor: TeaColors.white,
              border: OutlineInputBorder(
                borderRadius: TeaRadius.radiusMd,
                borderSide: const BorderSide(color: TeaColors.lightGray),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: TeaRadius.radiusMd,
                borderSide: const BorderSide(color: TeaColors.lightGray),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: TeaRadius.radiusMd,
                borderSide: const BorderSide(color: TeaColors.freshLeaf, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.forgot_email_required;
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return l10n.forgot_email_invalid;
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
                  : Text(l10n.forgot_send_button),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: TeaSpacing.lg),

          // Back to Login
          Center(
            child: TextButton(
              onPressed: () => context.pop(),
              child: Text(
                l10n.forgot_back_to_login,
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
    final l10n = AppLocalizations.of(context)!;
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
          child: const Icon(
            Icons.mark_email_read_outlined,
            size: 80,
            color: TeaColors.healthyGreen,
          ),
        ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.5, 0.5)),

        const SizedBox(height: TeaSpacing.xl),

        // Success Title
        Text(
          l10n.forgot_success_title,
          style: TeaTypography.headlineMedium,
          textAlign: TextAlign.center,
        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

        const SizedBox(height: TeaSpacing.sm),

        // Success Description
        Text(
          l10n.forgot_success_desc,
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
                text: l10n.forgot_step_open_email,
              ),
              const Divider(height: TeaSpacing.lg),
              _buildInstructionItem(
                icon: Icons.link,
                text: l10n.forgot_step_click_link,
              ),
              const Divider(height: TeaSpacing.lg),
              _buildInstructionItem(
                icon: Icons.lock_outline,
                text: l10n.forgot_step_new_password,
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 500.ms).slideY(begin: 0.1, end: 0),

        const SizedBox(height: TeaSpacing.xl),

        // Resend Button
        TextButton.icon(
          onPressed: () {
            TeaSnackbar.success(context, l10n.forgot_resend_success);
          },
          icon: const Icon(Icons.refresh),
          label: Text(l10n.forgot_resend),
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
              side: const BorderSide(color: TeaColors.freshLeaf),
              padding: const EdgeInsets.symmetric(vertical: TeaSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: TeaRadius.radiusMd,
              ),
            ),
            child: Text(l10n.forgot_back_to_login),
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
