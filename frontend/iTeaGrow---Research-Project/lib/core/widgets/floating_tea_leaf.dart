import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/jarvis_theme.dart';

/// Animated floating tea leaf widget for 3D visual effects
class FloatingTeaLeaf extends StatefulWidget {
  final double size;
  final Duration duration;
  final double delay;
  final Color? color;
  final bool isHealthy;

  const FloatingTeaLeaf({
    super.key,
    this.size = 40,
    this.duration = const Duration(seconds: 4),
    this.delay = 0,
    this.color,
    this.isHealthy = true,
  });

  @override
  State<FloatingTeaLeaf> createState() => _FloatingTeaLeafState();
}

class _FloatingTeaLeafState extends State<FloatingTeaLeaf>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _rotateController;
  late Animation<double> _floatAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Float animation
    _floatController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _floatAnimation = Tween<double>(begin: -15, end: 15).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Rotate animation
    _rotateController = AnimationController(
      duration: Duration(seconds: widget.duration.inSeconds * 2),
      vsync: this,
    );

    _rotateAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.easeInOut),
    );

    // Start animations with delay
    Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
      if (mounted) {
        _floatController.repeat(reverse: true);
        _rotateController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leafColor = widget.color ??
        (widget.isHealthy ? JarvisTheme.teaGreen : JarvisTheme.warning);

    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _rotateController]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Transform.rotate(
            angle: _rotateAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: CustomPaint(
                size: Size(widget.size, widget.size * 1.5),
                painter: TeaLeafPainter(
                  color: leafColor,
                  isHealthy: widget.isHealthy,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for realistic tea leaf shape
class TeaLeafPainter extends CustomPainter {
  final Color color;
  final bool isHealthy;

  TeaLeafPainter({
    required this.color,
    this.isHealthy = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withOpacity(0.9),
          color,
          color.withOpacity(0.7),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final w = size.width;
    final h = size.height;

    // Draw leaf shape
    path.moveTo(w * 0.5, 0);
    path.quadraticBezierTo(w * 0.9, h * 0.2, w * 0.85, h * 0.5);
    path.quadraticBezierTo(w * 0.8, h * 0.8, w * 0.5, h);
    path.quadraticBezierTo(w * 0.2, h * 0.8, w * 0.15, h * 0.5);
    path.quadraticBezierTo(w * 0.1, h * 0.2, w * 0.5, 0);

    canvas.drawPath(path, paint);

    // Draw vein
    final veinPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final veinPath = Path();
    veinPath.moveTo(w * 0.5, h * 0.1);
    veinPath.lineTo(w * 0.5, h * 0.9);

    // Side veins
    for (var i = 0.25; i < 0.85; i += 0.15) {
      veinPath.moveTo(w * 0.5, h * i);
      veinPath.quadraticBezierTo(w * 0.65, h * (i + 0.05), w * 0.72, h * (i + 0.08));
      veinPath.moveTo(w * 0.5, h * i);
      veinPath.quadraticBezierTo(w * 0.35, h * (i + 0.05), w * 0.28, h * (i + 0.08));
    }

    canvas.drawPath(veinPath, veinPaint);

    // Add disease spots if unhealthy
    if (!isHealthy) {
      final spotPaint = Paint()
        ..color = JarvisTheme.critical.withOpacity(0.6)
        ..style = PaintingStyle.fill;

      final random = Random(42);
      for (var i = 0; i < 5; i++) {
        final spotX = w * (0.3 + random.nextDouble() * 0.4);
        final spotY = h * (0.2 + random.nextDouble() * 0.6);
        final spotSize = 2.0 + random.nextDouble() * 3;
        canvas.drawCircle(Offset(spotX, spotY), spotSize, spotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant TeaLeafPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isHealthy != isHealthy;
  }
}

/// Multiple floating leaves background
class FloatingLeavesBackground extends StatelessWidget {
  final int leafCount;
  final bool showDiseased;

  const FloatingLeavesBackground({
    super.key,
    this.leafCount = 6,
    this.showDiseased = false,
  });

  @override
  Widget build(BuildContext context) {
    final random = Random(DateTime.now().millisecondsSinceEpoch);

    return IgnorePointer(
      child: Stack(
        children: List.generate(leafCount, (index) {
          final isHealthy = showDiseased ? random.nextBool() : true;
          return Positioned(
            left: random.nextDouble() * MediaQuery.of(context).size.width * 0.8,
            top: random.nextDouble() * MediaQuery.of(context).size.height * 0.8,
            child: Opacity(
              opacity: 0.15 + random.nextDouble() * 0.15,
              child: FloatingTeaLeaf(
                size: 30 + random.nextDouble() * 30,
                duration: Duration(seconds: 3 + random.nextInt(3)),
                delay: random.nextDouble() * 2,
                isHealthy: isHealthy,
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Animated disease indicator leaf
class DiseaseIndicatorLeaf extends StatefulWidget {
  final String diseaseType;
  final double severity; // 0.0 to 1.0
  final double size;

  const DiseaseIndicatorLeaf({
    super.key,
    required this.diseaseType,
    required this.severity,
    this.size = 80,
  });

  @override
  State<DiseaseIndicatorLeaf> createState() => _DiseaseIndicatorLeafState();
}

class _DiseaseIndicatorLeafState extends State<DiseaseIndicatorLeaf>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(milliseconds: (2000 - widget.severity * 1000).toInt()),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color get _indicatorColor {
    if (widget.severity < 0.3) return JarvisTheme.healthy;
    if (widget.severity < 0.6) return JarvisTheme.warning;
    return JarvisTheme.critical;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size * 1.5,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: _indicatorColor.withOpacity(0.4 * widget.severity),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: CustomPaint(
              painter: TeaLeafPainter(
                color: Color.lerp(
                  JarvisTheme.teaGreen,
                  _indicatorColor,
                  widget.severity,
                )!,
                isHealthy: widget.severity < 0.3,
              ),
            ),
          ),
        );
      },
    );
  }
}
