import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iteagrow/l10n/app_localizations.dart';
import '../../../../core/design_system/design_system.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: TeaColors.mistGreen,
      body: CustomScrollView(
        slivers: [
          // ── Premium App Bar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            stretch: true,
            backgroundColor: TeaColors.freshLeaf,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                l10n.contact_title,
                style: TeaTypography.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: TeaColors.primaryGradient,
                    ),
                  ),
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(
                      Icons.contact_support,
                      size: 200,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Contact Information Content ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(TeaSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: TeaSpacing.md),
                  Text(
                    l10n.contact_get_in_touch,
                    style: TeaTypography.headlineSmall.copyWith(
                      color: TeaColors.nearBlack,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.1, end: 0),
                  const SizedBox(height: TeaSpacing.sm),
                  Text(
                    l10n.contact_description,
                    style: TeaTypography.bodyMedium
                        .copyWith(color: TeaColors.darkGray),
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                  const SizedBox(height: TeaSpacing.xl),

                  // ── Email Support Card ──────────────────────────────────────
                  _buildContactCard(
                    icon: Icons.email_rounded,
                    title: l10n.contact_email_support,
                    subtitle: l10n.contact_email_support_address,
                    color: TeaColors.infoSky,
                    delay: 200,
                  ),

                  const SizedBox(height: TeaSpacing.lg),

                  Text(
                    l10n.contact_our_locations,
                    style: TeaTypography.titleLarge.copyWith(
                      color: TeaColors.nearBlack,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                  const SizedBox(height: TeaSpacing.md),

                  // ── Research Location Card ──────────────────────────────────
                  _buildContactCard(
                    icon: Icons.science_rounded,
                    title: l10n.contact_location_research,
                    subtitle: l10n.contact_location_research_address,
                    color: TeaColors.freshLeaf,
                    delay: 400,
                  ),

                  const SizedBox(height: TeaSpacing.md),

                  // ── Academic Site Card ────────────────────────────────────
                  _buildContactCard(
                    icon: Icons.school_rounded,
                    title: l10n.contact_location_academic,
                    subtitle: l10n.contact_location_academic_address,
                    color: TeaColors.matureLeaf,
                    delay: 500,
                  ),

                  const SizedBox(height: TeaSpacing.xxl),

                  // ── Footer ──────────────────────────────────────────────────
                  Center(
                    child: Text(
                      l10n.contact_footer,
                      style: TeaTypography.labelSmall
                          .copyWith(color: TeaColors.mediumGray),
                    ),
                  ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
                  const SizedBox(height: TeaSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required int delay,
  }) {
    return Container(
      padding: const EdgeInsets.all(TeaSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TeaRadius.lg),
        boxShadow: TeaShadows.cardShadow,
        border: Border.all(color: color.withOpacity(0.1), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(TeaSpacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(TeaRadius.md),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: TeaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TeaTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: TeaColors.nearBlack,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  subtitle,
                  style: TeaTypography.bodyMedium.copyWith(
                    color: TeaColors.darkGray,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: delay.ms, duration: 400.ms)
        .slideX(begin: 0.05, end: 0);
  }
}
