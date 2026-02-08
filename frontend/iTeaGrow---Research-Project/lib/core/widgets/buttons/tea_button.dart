import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../design_system/design_system.dart';

/// Button variants
enum TeaButtonVariant {
  primary,
  secondary,
  outlined,
  text,
  destructive,
  success,
}

/// Button sizes
enum TeaButtonSize {
  small,
  medium,
  large,
}

/// Premium Tea Button with micro-interactions
class TeaButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final TeaButtonVariant variant;
  final TeaButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;

  const TeaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = TeaButtonVariant.primary,
    this.size = TeaButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.width,
  });

  /// Primary filled button
  factory TeaButton.primary({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    TeaButtonSize size = TeaButtonSize.medium,
    IconData? icon,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    return TeaButton(
      key: key,
      label: label,
      onPressed: onPressed,
      variant: TeaButtonVariant.primary,
      size: size,
      icon: icon,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
    );
  }

  /// Secondary filled button
  factory TeaButton.secondary({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    TeaButtonSize size = TeaButtonSize.medium,
    IconData? icon,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    return TeaButton(
      key: key,
      label: label,
      onPressed: onPressed,
      variant: TeaButtonVariant.secondary,
      size: size,
      icon: icon,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
    );
  }

  /// Outlined button
  factory TeaButton.outlined({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    TeaButtonSize size = TeaButtonSize.medium,
    IconData? icon,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    return TeaButton(
      key: key,
      label: label,
      onPressed: onPressed,
      variant: TeaButtonVariant.outlined,
      size: size,
      icon: icon,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
    );
  }

  /// Text button
  factory TeaButton.text({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    TeaButtonSize size = TeaButtonSize.medium,
    IconData? icon,
  }) {
    return TeaButton(
      key: key,
      label: label,
      onPressed: onPressed,
      variant: TeaButtonVariant.text,
      size: size,
      icon: icon,
    );
  }

  /// Destructive action button
  factory TeaButton.destructive({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    TeaButtonSize size = TeaButtonSize.medium,
    IconData? icon,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    return TeaButton(
      key: key,
      label: label,
      onPressed: onPressed,
      variant: TeaButtonVariant.destructive,
      size: size,
      icon: icon,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
    );
  }

  @override
  State<TeaButton> createState() => _TeaButtonState();
}

class _TeaButtonState extends State<TeaButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: SizedBox(
        width: widget.isFullWidth ? double.infinity : widget.width,
        child: _buildButton(isEnabled),
      ),
    );
  }

  Widget _buildButton(bool isEnabled) {
    switch (widget.variant) {
      case TeaButtonVariant.primary:
        return _buildPrimaryButton(isEnabled);
      case TeaButtonVariant.secondary:
        return _buildSecondaryButton(isEnabled);
      case TeaButtonVariant.outlined:
        return _buildOutlinedButton(isEnabled);
      case TeaButtonVariant.text:
        return _buildTextButton(isEnabled);
      case TeaButtonVariant.destructive:
        return _buildDestructiveButton(isEnabled);
      case TeaButtonVariant.success:
        return _buildSuccessButton(isEnabled);
    }
  }

  Widget _buildPrimaryButton(bool isEnabled) {
    return _wrapWithGesture(
      isEnabled,
      Container(
        decoration: BoxDecoration(
          gradient: isEnabled ? TeaColors.primaryGradient : null,
          color: isEnabled ? null : TeaColors.lightGray,
          borderRadius: TeaRadius.radiusMd,
          boxShadow: isEnabled ? TeaShadows.buttonShadow : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? widget.onPressed : null,
            borderRadius: TeaRadius.radiusMd,
            splashColor: TeaColors.white.withOpacity(0.2),
            highlightColor: TeaColors.white.withOpacity(0.1),
            child: Padding(
              padding: _getPadding(),
              child: _buildContent(TeaColors.white, isEnabled),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(bool isEnabled) {
    return _wrapWithGesture(
      isEnabled,
      Container(
        decoration: BoxDecoration(
          color: isEnabled ? TeaColors.goldenSunlight : TeaColors.lightGray,
          borderRadius: TeaRadius.radiusMd,
          boxShadow: isEnabled
              ? TeaShadows.glow(TeaColors.goldenSunlight, intensity: 0.2)
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? widget.onPressed : null,
            borderRadius: TeaRadius.radiusMd,
            splashColor: TeaColors.white.withOpacity(0.2),
            child: Padding(
              padding: _getPadding(),
              child: _buildContent(TeaColors.richSoil, isEnabled),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlinedButton(bool isEnabled) {
    return _wrapWithGesture(
      isEnabled,
      Container(
        decoration: BoxDecoration(
          borderRadius: TeaRadius.radiusMd,
          border: Border.all(
            color: isEnabled ? TeaColors.freshLeaf : TeaColors.lightGray,
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? widget.onPressed : null,
            borderRadius: TeaRadius.radiusMd,
            splashColor: TeaColors.freshLeaf.withOpacity(0.1),
            child: Padding(
              padding: _getPadding(),
              child: _buildContent(
                isEnabled ? TeaColors.freshLeaf : TeaColors.mediumGray,
                isEnabled,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextButton(bool isEnabled) {
    return TextButton(
      onPressed: isEnabled ? widget.onPressed : null,
      style: TextButton.styleFrom(
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: TeaRadius.radiusSm,
        ),
      ),
      child: _buildContent(
        isEnabled ? TeaColors.freshLeaf : TeaColors.mediumGray,
        isEnabled,
      ),
    );
  }

  Widget _buildDestructiveButton(bool isEnabled) {
    return _wrapWithGesture(
      isEnabled,
      Container(
        decoration: BoxDecoration(
          color: isEnabled ? TeaColors.alertRust : TeaColors.lightGray,
          borderRadius: TeaRadius.radiusMd,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? widget.onPressed : null,
            borderRadius: TeaRadius.radiusMd,
            splashColor: TeaColors.white.withOpacity(0.2),
            child: Padding(
              padding: _getPadding(),
              child: _buildContent(TeaColors.white, isEnabled),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessButton(bool isEnabled) {
    return _wrapWithGesture(
      isEnabled,
      Container(
        decoration: BoxDecoration(
          gradient: isEnabled ? TeaColors.successGradient : null,
          color: isEnabled ? null : TeaColors.lightGray,
          borderRadius: TeaRadius.radiusMd,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? widget.onPressed : null,
            borderRadius: TeaRadius.radiusMd,
            splashColor: TeaColors.white.withOpacity(0.2),
            child: Padding(
              padding: _getPadding(),
              child: _buildContent(TeaColors.white, isEnabled),
            ),
          ),
        ),
      ),
    );
  }

  Widget _wrapWithGesture(bool isEnabled, Widget child) {
    if (!isEnabled) return child;

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) => _pressController.reverse(),
      onTapCancel: () => _pressController.reverse(),
      child: child,
    );
  }

  Widget _buildContent(Color color, bool isEnabled) {
    final textStyle = _getTextStyle().copyWith(
      color: isEnabled ? color : TeaColors.darkGray,
    );

    if (widget.isLoading) {
      return SizedBox(
        height: _getIconSize(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: _getIconSize() - 4,
              height: _getIconSize() - 4,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(width: 8),
            Text(widget.label, style: textStyle),
          ],
        ),
      ).animate(onPlay: (c) => c.repeat()).shimmer(
            duration: const Duration(milliseconds: 1000),
            color: TeaColors.white.withOpacity(0.3),
          );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: _getIconSize(), color: color),
          const SizedBox(width: 8),
        ],
        Text(widget.label, style: textStyle),
        if (widget.trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(widget.trailingIcon, size: _getIconSize(), color: color),
        ],
      ],
    );
  }

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case TeaButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case TeaButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
      case TeaButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 28, vertical: 16);
    }
  }

  TextStyle _getTextStyle() {
    switch (widget.size) {
      case TeaButtonSize.small:
        return TeaTypography.buttonSmall;
      case TeaButtonSize.medium:
        return TeaTypography.buttonMedium;
      case TeaButtonSize.large:
        return TeaTypography.buttonLarge;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case TeaButtonSize.small:
        return 16;
      case TeaButtonSize.medium:
        return 20;
      case TeaButtonSize.large:
        return 24;
    }
  }
}

/// Icon Button with Tea styling
class TeaIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final String? tooltip;
  final bool hasBadge;
  final String? badgeText;

  const TeaIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.size = 24,
    this.tooltip,
    this.hasBadge = false,
    this.badgeText,
  });

  @override
  State<TeaIconButton> createState() => _TeaIconButtonState();
}

class _TeaIconButtonState extends State<TeaIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final button = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? Colors.transparent,
            borderRadius: TeaRadius.radiusSm,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(widget.icon),
                onPressed: widget.onPressed,
                color: widget.color ?? TeaColors.nearBlack,
                iconSize: widget.size,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              if (widget.hasBadge)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: TeaColors.alertRust,
                      borderRadius: TeaRadius.radiusRound,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      widget.badgeText ?? '',
                      style: TeaTypography.labelSmall.copyWith(
                        color: TeaColors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return button;
  }
}
