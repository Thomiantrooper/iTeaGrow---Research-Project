import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/jarvis_theme.dart';

/// 3D Hologram-style card with depth and glow effects
class HologramCard extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final bool enableGlow;
  final Color? glowColor;
  final bool enable3DEffect;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const HologramCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.enableGlow = true,
    this.glowColor,
    this.enable3DEffect = true,
    this.onTap,
    this.borderRadius,
  });

  @override
  State<HologramCard> createState() => _HologramCardState();
}

class _HologramCardState extends State<HologramCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  Offset _rotationOffset = Offset.zero;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    if (widget.enableGlow) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _updateRotation(Offset localPosition, Size size) {
    if (!widget.enable3DEffect) return;
    setState(() {
      _rotationOffset = Offset(
        (localPosition.dx - size.width / 2) / size.width * 0.1,
        (localPosition.dy - size.height / 2) / size.height * 0.1,
      );
    });
  }

  void _resetRotation() {
    setState(() {
      _rotationOffset = Offset.zero;
      _isHovered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(JarvisTheme.radiusLg);
    final glowColor = widget.glowColor ?? JarvisTheme.hologramGreen;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => _resetRotation(),
      onHover: (event) {
        if (widget.enable3DEffect && context.findRenderObject() != null) {
          final box = context.findRenderObject() as RenderBox;
          _updateRotation(event.localPosition, box.size);
        }
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onPanUpdate: widget.enable3DEffect
            ? (details) {
                if (context.findRenderObject() != null) {
                  final box = context.findRenderObject() as RenderBox;
                  _updateRotation(details.localPosition, box.size);
                }
              }
            : null,
        onPanEnd: widget.enable3DEffect ? (_) => _resetRotation() : null,
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: widget.width,
              height: widget.height,
              transform: widget.enable3DEffect
                  ? (Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateX(-_rotationOffset.dy)
                    ..rotateY(_rotationOffset.dx))
                  : Matrix4.identity(),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    JarvisTheme.mistWhitePure,
                    JarvisTheme.mistWhite,
                    JarvisTheme.mistGray.withOpacity(0.5),
                  ],
                ),
                border: Border.all(
                  color: _isHovered
                      ? glowColor.withOpacity(0.5)
                      : JarvisTheme.teaGreen.withOpacity(0.1),
                  width: _isHovered ? 2 : 1,
                ),
                boxShadow: [
                  // Base shadow
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                    spreadRadius: -5,
                  ),
                  // Glow effect
                  if (widget.enableGlow)
                    BoxShadow(
                      color: glowColor.withOpacity(
                        _isHovered ? _glowAnimation.value : _glowAnimation.value * 0.3,
                      ),
                      blurRadius: _isHovered ? 30 : 15,
                      spreadRadius: _isHovered ? 2 : 0,
                    ),
                  // Ambient light
                  BoxShadow(
                    color: JarvisTheme.teaGreen.withOpacity(0.05),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: Padding(
                  padding: widget.padding ?? const EdgeInsets.all(JarvisTheme.spacingMd),
                  child: widget.child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Animated status ring for Jarvis-style indicators
class StatusRing extends StatefulWidget {
  final double size;
  final double progress;
  final Color color;
  final Color? backgroundColor;
  final double strokeWidth;
  final Widget? child;
  final bool animate;

  const StatusRing({
    super.key,
    this.size = 100,
    required this.progress,
    this.color = JarvisTheme.teaGreen,
    this.backgroundColor,
    this.strokeWidth = 8,
    this.child,
    this.animate = true,
  });

  @override
  State<StatusRing> createState() => _StatusRingState();
}

class _StatusRingState extends State<StatusRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    if (widget.animate) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(StatusRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.progress,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background ring
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: RingPainter(
                  progress: 1.0,
                  color: widget.backgroundColor ??
                      widget.color.withOpacity(0.15),
                  strokeWidth: widget.strokeWidth,
                ),
              ),
              // Progress ring
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: RingPainter(
                  progress: widget.animate ? _animation.value : widget.progress,
                  color: widget.color,
                  strokeWidth: widget.strokeWidth,
                  hasGlow: true,
                ),
              ),
              // Child content
              if (widget.child != null) widget.child!,
            ],
          ),
        );
      },
    );
  }
}

class RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final bool hasGlow;

  RingPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 8,
    this.hasGlow = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Glow effect
    if (hasGlow && progress > 0) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        glowPaint,
      );
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// Animated metric display with hologram effect
class HologramMetric extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData icon;
  final Color? color;
  final double? progress;

  const HologramMetric({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    required this.icon,
    this.color,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final metricColor = color ?? JarvisTheme.teaGreen;

    return HologramCard(
      enableGlow: true,
      glowColor: metricColor,
      padding: const EdgeInsets.all(JarvisTheme.spacingMd),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon with glow
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  metricColor.withOpacity(0.2),
                  metricColor.withOpacity(0.05),
                ],
              ),
            ),
            child: Icon(icon, color: metricColor, size: 28),
          ),
          const SizedBox(height: JarvisTheme.spacingSm),

          // Label
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: JarvisTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: JarvisTheme.spacingXs),

          // Value
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: metricColor,
                ),
              ),
              if (unit != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 3),
                  child: Text(
                    unit!,
                    style: TextStyle(
                      fontSize: 12,
                      color: metricColor.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),

          // Progress bar if provided
          if (progress != null) ...[
            const SizedBox(height: JarvisTheme.spacingSm),
            ClipRRect(
              borderRadius: BorderRadius.circular(JarvisTheme.radiusRound),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: metricColor.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(metricColor),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
