import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../design_system/design_system.dart';

/// Card variants for different use cases
enum TeaCardVariant {
  elevated,
  outlined,
  filled,
  glass,
}

/// Premium Tea Card with depth and animations
class TeaCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final TeaCardVariant variant;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderRadius;
  final List<BoxShadow>? shadow;
  final bool animateOnTap;
  final Gradient? gradient;

  const TeaCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
    this.variant = TeaCardVariant.elevated,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.shadow,
    this.animateOnTap = true,
    this.gradient,
  });

  /// Elevated card with shadow
  factory TeaCard.elevated({
    Key? key,
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    VoidCallback? onTap,
    Color? backgroundColor,
    double? borderRadius,
  }) {
    return TeaCard(
      key: key,
      variant: TeaCardVariant.elevated,
      padding: padding,
      margin: margin,
      onTap: onTap,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      child: child,
    );
  }

  /// Outlined card with border
  factory TeaCard.outlined({
    Key? key,
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    VoidCallback? onTap,
    Color? borderColor,
    double? borderRadius,
  }) {
    return TeaCard(
      key: key,
      variant: TeaCardVariant.outlined,
      padding: padding,
      margin: margin,
      onTap: onTap,
      borderColor: borderColor,
      borderRadius: borderRadius,
      child: child,
    );
  }

  /// Filled card with background color
  factory TeaCard.filled({
    Key? key,
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    VoidCallback? onTap,
    Color? backgroundColor,
    double? borderRadius,
  }) {
    return TeaCard(
      key: key,
      variant: TeaCardVariant.filled,
      padding: padding,
      margin: margin,
      onTap: onTap,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      child: child,
    );
  }

  /// Glass morphism card
  factory TeaCard.glass({
    Key? key,
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    VoidCallback? onTap,
    double? borderRadius,
  }) {
    return TeaCard(
      key: key,
      variant: TeaCardVariant.glass,
      padding: padding,
      margin: margin,
      onTap: onTap,
      borderRadius: borderRadius,
      child: child,
    );
  }

  @override
  State<TeaCard> createState() => _TeaCardState();
}

class _TeaCardState extends State<TeaCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null && widget.animateOnTap) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.animateOnTap) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.animateOnTap) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Padding(
        padding: widget.margin ?? EdgeInsets.zero,
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: _buildCard(),
        ),
      ),
    );
  }

  Widget _buildCard() {
    switch (widget.variant) {
      case TeaCardVariant.elevated:
        return _buildElevatedCard();
      case TeaCardVariant.outlined:
        return _buildOutlinedCard();
      case TeaCardVariant.filled:
        return _buildFilledCard();
      case TeaCardVariant.glass:
        return _buildGlassCard();
    }
  }

  Widget _buildElevatedCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? TeaColors.white,
        borderRadius: BorderRadius.circular(
          widget.borderRadius ?? TeaRadius.lg,
        ),
        gradient: widget.gradient,
        boxShadow: widget.shadow ??
            (_isPressed ? TeaShadows.cardShadow : TeaShadows.cardShadowMedium),
      ),
      child: Material(
        color: Colors.transparent,
        child: widget.onTap != null
            ? InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(
                  widget.borderRadius ?? TeaRadius.lg,
                ),
                splashColor: TeaColors.freshLeaf.withOpacity(0.1),
                highlightColor: TeaColors.freshLeaf.withOpacity(0.05),
                child: Padding(
                  padding: widget.padding ?? TeaSpacing.cardPaddingMd,
                  child: widget.child,
                ),
              )
            : Padding(
                padding: widget.padding ?? TeaSpacing.cardPaddingMd,
                child: widget.child,
              ),
      ),
    );
  }

  Widget _buildOutlinedCard() {
    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? TeaColors.white,
        borderRadius: BorderRadius.circular(
          widget.borderRadius ?? TeaRadius.lg,
        ),
        border: Border.all(
          color: widget.borderColor ?? TeaColors.lightGray,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: widget.onTap != null
            ? InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(
                  widget.borderRadius ?? TeaRadius.lg,
                ),
                splashColor: TeaColors.freshLeaf.withOpacity(0.1),
                highlightColor: TeaColors.freshLeaf.withOpacity(0.05),
                child: Padding(
                  padding: widget.padding ?? TeaSpacing.cardPaddingMd,
                  child: widget.child,
                ),
              )
            : Padding(
                padding: widget.padding ?? TeaSpacing.cardPaddingMd,
                child: widget.child,
              ),
      ),
    );
  }

  Widget _buildFilledCard() {
    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? TeaColors.leafPale,
        borderRadius: BorderRadius.circular(
          widget.borderRadius ?? TeaRadius.lg,
        ),
        gradient: widget.gradient,
      ),
      child: Material(
        color: Colors.transparent,
        child: widget.onTap != null
            ? InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(
                  widget.borderRadius ?? TeaRadius.lg,
                ),
                splashColor: TeaColors.freshLeaf.withOpacity(0.1),
                highlightColor: TeaColors.freshLeaf.withOpacity(0.05),
                child: Padding(
                  padding: widget.padding ?? TeaSpacing.cardPaddingMd,
                  child: widget.child,
                ),
              )
            : Padding(
                padding: widget.padding ?? TeaSpacing.cardPaddingMd,
                child: widget.child,
              ),
      ),
    );
  }

  Widget _buildGlassCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        widget.borderRadius ?? TeaRadius.lg,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: TeaColors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(
            widget.borderRadius ?? TeaRadius.lg,
          ),
          border: Border.all(
            color: TeaColors.white.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: TeaColors.shadowVale,
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: widget.onTap != null
              ? InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(
                    widget.borderRadius ?? TeaRadius.lg,
                  ),
                  child: Padding(
                    padding: widget.padding ?? TeaSpacing.cardPaddingMd,
                    child: widget.child,
                  ),
                )
              : Padding(
                  padding: widget.padding ?? TeaSpacing.cardPaddingMd,
                  child: widget.child,
                ),
        ),
      ),
    );
  }
}

/// Metric Card for displaying key values
class TeaMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData icon;
  final Color? iconColor;
  final Color? valueColor;
  final String? trend;
  final bool? isPositiveTrend;
  final VoidCallback? onTap;

  const TeaMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    required this.icon,
    this.iconColor,
    this.valueColor,
    this.trend,
    this.isPositiveTrend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TeaCard.elevated(
      onTap: onTap,
      padding: TeaSpacing.cardPaddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(TeaSpacing.sm),
                decoration: BoxDecoration(
                  color: (iconColor ?? TeaColors.freshLeaf).withOpacity(0.1),
                  borderRadius: TeaRadius.radiusSm,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor ?? TeaColors.freshLeaf,
                ),
              ),
              const Spacer(),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TeaSpacing.xs,
                    vertical: TeaSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: (isPositiveTrend == true
                            ? TeaColors.healthyGreen
                            : TeaColors.alertRust)
                        .withOpacity(0.1),
                    borderRadius: TeaRadius.radiusXs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositiveTrend == true
                            ? Icons.trending_up
                            : Icons.trending_down,
                        size: 12,
                        color: isPositiveTrend == true
                            ? TeaColors.healthyGreen
                            : TeaColors.alertRust,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        trend!,
                        style: TeaTypography.labelSmall.copyWith(
                          color: isPositiveTrend == true
                              ? TeaColors.healthyGreen
                              : TeaColors.alertRust,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: TeaSpacing.smd),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TeaTypography.metricValue.copyWith(
                  color: valueColor ?? TeaColors.nearBlack,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: TeaSpacing.xxs),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unit!,
                    style: TeaTypography.labelMedium.copyWith(
                      color: TeaColors.darkGray,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: TeaSpacing.xs),
          Text(
            label,
            style: TeaTypography.metricLabel,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}

/// Alert Card for notifications
class TeaAlertCard extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;
  final Color severity;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final String? actionLabel;

  const TeaAlertCard({
    super.key,
    required this.title,
    this.message,
    required this.icon,
    this.severity = TeaColors.warningAmber,
    this.onTap,
    this.onDismiss,
    this.actionLabel,
  });

  factory TeaAlertCard.success({
    Key? key,
    required String title,
    String? message,
    VoidCallback? onTap,
    VoidCallback? onDismiss,
  }) {
    return TeaAlertCard(
      key: key,
      title: title,
      message: message,
      icon: Icons.check_circle_outline,
      severity: TeaColors.healthyGreen,
      onTap: onTap,
      onDismiss: onDismiss,
    );
  }

  factory TeaAlertCard.warning({
    Key? key,
    required String title,
    String? message,
    VoidCallback? onTap,
    VoidCallback? onDismiss,
  }) {
    return TeaAlertCard(
      key: key,
      title: title,
      message: message,
      icon: Icons.warning_amber_outlined,
      severity: TeaColors.warningAmber,
      onTap: onTap,
      onDismiss: onDismiss,
    );
  }

  factory TeaAlertCard.error({
    Key? key,
    required String title,
    String? message,
    VoidCallback? onTap,
    VoidCallback? onDismiss,
  }) {
    return TeaAlertCard(
      key: key,
      title: title,
      message: message,
      icon: Icons.error_outline,
      severity: TeaColors.alertRust,
      onTap: onTap,
      onDismiss: onDismiss,
    );
  }

  factory TeaAlertCard.info({
    Key? key,
    required String title,
    String? message,
    VoidCallback? onTap,
    VoidCallback? onDismiss,
  }) {
    return TeaAlertCard(
      key: key,
      title: title,
      message: message,
      icon: Icons.info_outline,
      severity: TeaColors.infoSky,
      onTap: onTap,
      onDismiss: onDismiss,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: severity.withOpacity(0.08),
        borderRadius: TeaRadius.radiusMd,
        border: Border.all(
          color: severity.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: TeaRadius.radiusMd,
          child: Padding(
            padding: TeaSpacing.cardPaddingMd,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(TeaSpacing.sm),
                  decoration: BoxDecoration(
                    color: severity.withOpacity(0.15),
                    borderRadius: TeaRadius.radiusSm,
                  ),
                  child: Icon(
                    icon,
                    color: severity,
                    size: 20,
                  ),
                ),
                const SizedBox(width: TeaSpacing.smd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TeaTypography.titleSmall.copyWith(
                          color: severity,
                        ),
                      ),
                      if (message != null) ...[
                        const SizedBox(height: TeaSpacing.xxs),
                        Text(
                          message!,
                          style: TeaTypography.bodySmall.copyWith(
                            color: TeaColors.darkGray,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (actionLabel != null)
                  TextButton(
                    onPressed: onTap,
                    child: Text(
                      actionLabel!,
                      style: TeaTypography.buttonSmall.copyWith(
                        color: severity,
                      ),
                    ),
                  )
                else if (onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: TeaColors.darkGray,
                    onPressed: onDismiss,
                  )
                else if (onTap != null)
                  Icon(
                    Icons.chevron_right,
                    color: severity,
                  ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideX(begin: -0.05, end: 0);
  }
}
