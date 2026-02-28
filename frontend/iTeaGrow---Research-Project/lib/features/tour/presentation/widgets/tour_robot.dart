import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/design_system/design_system.dart';

/// Cute animated robot character for the guided tour
class TourRobot extends StatefulWidget {
  final bool isVisible;
  final bool isTalking;
  final VoidCallback? onTap;

  const TourRobot({
    super.key,
    this.isVisible = true,
    this.isTalking = false,
    this.onTap,
  });

  @override
  State<TourRobot> createState() => _TourRobotState();
}

class _TourRobotState extends State<TourRobot>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late AnimationController _blinkController;
  late AnimationController _talkController;
  late Animation<double> _breathAnimation;
  late Animation<double> _blinkAnimation;
  late Animation<double> _talkAnimation;

  @override
  void initState() {
    super.initState();

    // Breathing animation (idle)
    _breathController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);
    _breathAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    // Blink animation
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.1).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
    _startBlinkLoop();

    // Talk animation (mouth)
    _talkController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _talkAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _talkController, curve: Curves.easeInOut),
    );
  }

  void _startBlinkLoop() async {
    while (mounted) {
      await Future.delayed(
        Duration(milliseconds: 2500 + Random().nextInt(2000)),
      );
      if (!mounted) return;
      await _blinkController.forward();
      await _blinkController.reverse();
    }
  }

  @override
  void didUpdateWidget(TourRobot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTalking && !oldWidget.isTalking) {
      _talkController.repeat(reverse: true);
    } else if (!widget.isTalking && oldWidget.isTalking) {
      _talkController.stop();
      _talkController.reverse();
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    _blinkController.dispose();
    _talkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _breathAnimation,
          _blinkAnimation,
          _talkAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _breathAnimation.value,
            child: SizedBox(
              width: 64,
              height: 72,
              child: CustomPaint(
                painter: _RobotPainter(
                  eyeOpenness: _blinkAnimation.value,
                  mouthOpenness: _talkAnimation.value,
                  bodyColor: TeaColors.freshLeaf,
                  accentColor: TeaColors.goldenSunlight,
                ),
              ),
            ),
          );
        },
      ),
    )
        .animate()
        .slideY(begin: 1.5, end: 0, duration: 500.ms, curve: Curves.easeOutBack)
        .fadeIn(duration: 300.ms);
  }
}

class _RobotPainter extends CustomPainter {
  final double eyeOpenness;
  final double mouthOpenness;
  final Color bodyColor;
  final Color accentColor;

  _RobotPainter({
    required this.eyeOpenness,
    required this.mouthOpenness,
    required this.bodyColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 4;
    final bodyW = size.width * 0.72;
    final bodyH = size.height * 0.55;

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, size.height - 4),
        width: bodyW * 0.8,
        height: 8,
      ),
      Paint()..color = Colors.black.withOpacity(0.1),
    );

    // Antenna stem
    final antennaPaint = Paint()
      ..color = bodyColor.withOpacity(0.8)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy - bodyH / 2 + 2),
      Offset(cx, cy - bodyH / 2 - 12),
      antennaPaint,
    );

    // Antenna ball
    canvas.drawCircle(
      Offset(cx, cy - bodyH / 2 - 14),
      5,
      Paint()..color = accentColor,
    );
    // Antenna glow
    canvas.drawCircle(
      Offset(cx, cy - bodyH / 2 - 14),
      7,
      Paint()..color = accentColor.withOpacity(0.25),
    );

    // Body (rounded rectangle)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: bodyW, height: bodyH),
      const Radius.circular(16),
    );
    // Body gradient
    final bodyGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [bodyColor, bodyColor.withOpacity(0.85)],
    );
    canvas.drawRRect(
      bodyRect,
      Paint()..shader = bodyGradient.createShader(bodyRect.outerRect),
    );

    // Face plate (lighter area)
    final faceRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy - 2),
        width: bodyW * 0.8,
        height: bodyH * 0.65,
      ),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      faceRect,
      Paint()..color = Colors.white.withOpacity(0.9),
    );

    // Eyes
    final eyeY = cy - 6;
    final eyeSpacing = bodyW * 0.2;
    final eyeRadius = 6.0;
    final eyeHeight = eyeRadius * 2 * eyeOpenness;

    // Left eye
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - eyeSpacing, eyeY),
        width: eyeRadius * 2,
        height: eyeHeight.clamp(1.0, eyeRadius * 2),
      ),
      Paint()..color = bodyColor,
    );
    // Right eye
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + eyeSpacing, eyeY),
        width: eyeRadius * 2,
        height: eyeHeight.clamp(1.0, eyeRadius * 2),
      ),
      Paint()..color = bodyColor,
    );

    // Eye shine
    if (eyeOpenness > 0.3) {
      canvas.drawCircle(
        Offset(cx - eyeSpacing + 2, eyeY - 2),
        2,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(cx + eyeSpacing + 2, eyeY - 2),
        2,
        Paint()..color = Colors.white,
      );
    }

    // Mouth
    final mouthY = cy + 8;
    final mouthWidth = bodyW * 0.25;
    final mouthHeight = 4 + (mouthOpenness * 6);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, mouthY),
          width: mouthWidth,
          height: mouthHeight,
        ),
        Radius.circular(mouthHeight / 2),
      ),
      Paint()..color = bodyColor.withOpacity(0.7),
    );

    // Arms (small rounded rects)
    final armPaint = Paint()..color = bodyColor.withOpacity(0.6);
    // Left arm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx - bodyW / 2 - 5, cy + 2),
          width: 8,
          height: 20,
        ),
        const Radius.circular(4),
      ),
      armPaint,
    );
    // Right arm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + bodyW / 2 + 5, cy + 2),
          width: 8,
          height: 20,
        ),
        const Radius.circular(4),
      ),
      armPaint,
    );

    // Feet
    final footPaint = Paint()..color = bodyColor.withOpacity(0.7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx - 10, cy + bodyH / 2 + 4),
          width: 14,
          height: 8,
        ),
        const Radius.circular(4),
      ),
      footPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + 10, cy + bodyH / 2 + 4),
          width: 14,
          height: 8,
        ),
        const Radius.circular(4),
      ),
      footPaint,
    );
  }

  @override
  bool shouldRepaint(_RobotPainter oldDelegate) =>
      eyeOpenness != oldDelegate.eyeOpenness ||
      mouthOpenness != oldDelegate.mouthOpenness;
}
