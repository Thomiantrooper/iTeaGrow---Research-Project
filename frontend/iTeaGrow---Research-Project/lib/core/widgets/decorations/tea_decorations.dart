import 'dart:math';
import 'package:flutter/material.dart';
import '../../design_system/design_system.dart';

/// Floating tea leaves background decoration
class FloatingLeavesBackground extends StatefulWidget {
  final int leafCount;
  final Widget child;
  final Color? leafColor;
  final double opacity;

  const FloatingLeavesBackground({
    super.key,
    this.leafCount = 8,
    required this.child,
    this.leafColor,
    this.opacity = 0.15,
  });

  @override
  State<FloatingLeavesBackground> createState() =>
      _FloatingLeavesBackgroundState();
}

class _FloatingLeavesBackgroundState extends State<FloatingLeavesBackground>
    with TickerProviderStateMixin {
  late List<_LeafData> _leaves;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _initLeaves();
  }

  void _initLeaves() {
    _leaves = List.generate(widget.leafCount, (index) {
      return _LeafData(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 16 + _random.nextDouble() * 24,
        rotation: _random.nextDouble() * 2 * pi,
        speed: 0.3 + _random.nextDouble() * 0.5,
        rotationSpeed: 0.5 + _random.nextDouble() * 1.0,
        delay: _random.nextDouble() * 2,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Leaves
        ...List.generate(widget.leafCount, (index) {
          final leaf = _leaves[index];
          return _AnimatedLeaf(
            leaf: leaf,
            color: widget.leafColor ?? TeaColors.freshLeaf,
            opacity: widget.opacity,
          );
        }),
        // Content
        widget.child,
      ],
    );
  }
}

class _LeafData {
  final double x;
  final double y;
  final double size;
  final double rotation;
  final double speed;
  final double rotationSpeed;
  final double delay;

  _LeafData({
    required this.x,
    required this.y,
    required this.size,
    required this.rotation,
    required this.speed,
    required this.rotationSpeed,
    required this.delay,
  });
}

class _AnimatedLeaf extends StatefulWidget {
  final _LeafData leaf;
  final Color color;
  final double opacity;

  const _AnimatedLeaf({
    required this.leaf,
    required this.color,
    required this.opacity,
  });

  @override
  State<_AnimatedLeaf> createState() => _AnimatedLeafState();
}

class _AnimatedLeafState extends State<_AnimatedLeaf>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: (8 / widget.leaf.speed).round()),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final yOffset = sin(progress * 2 * pi) * 20;
        final xOffset = sin(progress * 2 * pi * 0.5) * 10;
        final rotation =
            widget.leaf.rotation + (progress * 2 * pi * widget.leaf.rotationSpeed);

        return Positioned(
          left: MediaQuery.of(context).size.width * widget.leaf.x + xOffset,
          top: MediaQuery.of(context).size.height * widget.leaf.y + yOffset,
          child: Transform.rotate(
            angle: rotation,
            child: Opacity(
              opacity: widget.opacity,
              child: Icon(
                Icons.eco,
                size: widget.leaf.size,
                color: widget.color,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Mist effect gradient background
class MistBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  const MistBackground({
    super.key,
    required this.child,
    this.colors,
    this.begin = Alignment.topCenter,
    this.end = Alignment.bottomCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: colors ??
              [
                TeaColors.mistGreen,
                TeaColors.white,
              ],
        ),
      ),
      child: child,
    );
  }
}

/// Parallax container with depth effect
class ParallaxContainer extends StatefulWidget {
  final Widget child;
  final double intensity;
  final bool enableTilt;

  const ParallaxContainer({
    super.key,
    required this.child,
    this.intensity = 10,
    this.enableTilt = true,
  });

  @override
  State<ParallaxContainer> createState() => _ParallaxContainerState();
}

class _ParallaxContainerState extends State<ParallaxContainer> {
  double _rotateX = 0;
  double _rotateY = 0;

  void _onHover(PointerEvent event) {
    if (!widget.enableTilt) return;

    final box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(event.position);
    final centerX = box.size.width / 2;
    final centerY = box.size.height / 2;

    setState(() {
      _rotateY = (localPosition.dx - centerX) / centerX * widget.intensity;
      _rotateX = -(localPosition.dy - centerY) / centerY * widget.intensity;
    });
  }

  void _onExit(PointerEvent event) {
    setState(() {
      _rotateX = 0;
      _rotateY = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: _onHover,
      onExit: _onExit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(_rotateX * pi / 180)
          ..rotateY(_rotateY * pi / 180),
        transformAlignment: Alignment.center,
        child: widget.child,
      ),
    );
  }
}

/// Gradient border decoration
class GradientBorderContainer extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  final double borderWidth;
  final double borderRadius;
  final Color? backgroundColor;

  const GradientBorderContainer({
    super.key,
    required this.child,
    required this.gradient,
    this.borderWidth = 2,
    this.borderRadius = TeaRadius.lg,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: EdgeInsets.all(borderWidth),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor ?? TeaColors.white,
          borderRadius: BorderRadius.circular(borderRadius - borderWidth),
        ),
        child: child,
      ),
    );
  }
}

/// Shimmer loading effect
class TeaShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const TeaShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = TeaRadius.sm,
  });

  @override
  State<TeaShimmer> createState() => _TeaShimmerState();
}

class _TeaShimmerState extends State<TeaShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2 * _controller.value, 0),
              end: Alignment(1.0 + 2 * _controller.value, 0),
              colors: const [
                TeaColors.lightGray,
                TeaColors.surface,
                TeaColors.lightGray,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Animated section header with line
class TeaSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  const TeaSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TeaSpacing.sm),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: TeaColors.freshLeaf,
            ),
            const SizedBox(width: TeaSpacing.sm),
          ],
          Text(
            title,
            style: TeaTypography.titleMedium,
          ),
          const Spacer(),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: TeaTypography.labelMedium.copyWith(
                      color: TeaColors.freshLeaf,
                    ),
                  ),
                  const SizedBox(width: TeaSpacing.xxs),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: TeaColors.freshLeaf,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Status indicator badge
class TeaStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool showDot;
  final bool pulsing;

  const TeaStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.showDot = true,
    this.pulsing = false,
  });

  factory TeaStatusBadge.healthy({String label = 'Healthy'}) {
    return TeaStatusBadge(
      label: label,
      color: TeaColors.healthyGreen,
    );
  }

  factory TeaStatusBadge.warning({String label = 'Warning'}) {
    return TeaStatusBadge(
      label: label,
      color: TeaColors.warningAmber,
      pulsing: true,
    );
  }

  factory TeaStatusBadge.critical({String label = 'Critical'}) {
    return TeaStatusBadge(
      label: label,
      color: TeaColors.alertRust,
      pulsing: true,
    );
  }

  factory TeaStatusBadge.info({String label = 'Info'}) {
    return TeaStatusBadge(
      label: label,
      color: TeaColors.infoSky,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget badge = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TeaSpacing.sm,
        vertical: TeaSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: TeaRadius.radiusRound,
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: TeaSpacing.xs),
          ],
          Text(
            label,
            style: TeaTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (pulsing) {
      return _PulsingWidget(color: color, child: badge);
    }

    return badge;
  }
}

class _PulsingWidget extends StatefulWidget {
  final Widget child;
  final Color color;

  const _PulsingWidget({required this.child, required this.color});

  @override
  State<_PulsingWidget> createState() => _PulsingWidgetState();
}

class _PulsingWidgetState extends State<_PulsingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: TeaRadius.radiusRound,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3 * _controller.value),
                blurRadius: 8,
                spreadRadius: 2 * _controller.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Progress indicator with label
class TeaProgressBar extends StatelessWidget {
  final double value;
  final String? label;
  final Color? color;
  final Color? backgroundColor;
  final double height;
  final bool showPercentage;

  const TeaProgressBar({
    super.key,
    required this.value,
    this.label,
    this.color,
    this.backgroundColor,
    this.height = 8,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (value * 100).clamp(0, 100).toInt();
    final progressColor = color ?? TeaColors.getHealthColor(percentage.toDouble());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null || showPercentage)
          Padding(
            padding: const EdgeInsets.only(bottom: TeaSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null)
                  Text(
                    label!,
                    style: TeaTypography.labelMedium,
                  ),
                if (showPercentage)
                  Text(
                    '$percentage%',
                    style: TeaTypography.labelMedium.copyWith(
                      color: progressColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor ?? TeaColors.lightGray,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value.clamp(0, 1),
            child: Container(
              decoration: BoxDecoration(
                color: progressColor,
                borderRadius: BorderRadius.circular(height / 2),
                boxShadow: [
                  BoxShadow(
                    color: progressColor.withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
