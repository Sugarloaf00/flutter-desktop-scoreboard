import 'dart:math';
import 'package:flutter/material.dart';

class ThreeDTrophyWidget extends StatefulWidget {
  final double size;
  final String? leaderName;

  const ThreeDTrophyWidget({
    super.key,
    this.size = 120,
    this.leaderName,
  });

  @override
  State<ThreeDTrophyWidget> createState() => _ThreeDTrophyWidgetState();
}

class _ThreeDTrophyWidgetState extends State<ThreeDTrophyWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        final angle = _rotationController.value * 2 * pi;
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _IsometricTrophyPainter(angle: angle),
        );
      },
    );
  }
}

class _IsometricTrophyPainter extends CustomPainter {
  final double angle;

  _IsometricTrophyPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = size.width / 120.0;

    final cosA = cos(angle);

    // Dynamic metallic lighting
    final lightFactor = (cosA * 0.4 + 0.6).clamp(0.4, 1.0);
    final goldBright = Color.lerp(const Color(0xFFD97706), const Color(0xFFFFE066), lightFactor)!;
    final goldDark = Color.lerp(const Color(0xFF78350F), const Color(0xFFB45309), lightFactor)!;

    final cupPaint = Paint()
      ..shader = LinearGradient(
        colors: [goldBright, goldDark, goldBright],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(cx - 30 * scale, cy - 40 * scale, 60 * scale, 60 * scale))
      ..style = PaintingStyle.fill;

    // Pedestal
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 35 * scale), width: 50 * scale, height: 18 * scale),
      Radius.circular(4 * scale),
    );
    final basePaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawRRect(baseRect, basePaint);

    // Stem
    final stemPaint = Paint()..color = goldDark;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy + 18 * scale), width: 12 * scale, height: 20 * scale),
      stemPaint,
    );

    // Trophy Bowl
    final cupPath = Path();
    cupPath.moveTo(cx - 28 * scale, cy - 25 * scale);
    cupPath.lineTo(cx + 28 * scale, cy - 25 * scale);
    cupPath.quadraticBezierTo(cx + 24 * scale, cy + 10 * scale, cx + 10 * scale, cy + 12 * scale);
    cupPath.lineTo(cx - 10 * scale, cy + 12 * scale);
    cupPath.quadraticBezierTo(cx - 24 * scale, cy + 10 * scale, cx - 28 * scale, cy - 25 * scale);
    cupPath.close();
    canvas.drawPath(cupPath, cupPaint);

    // 3D Projected Handles
    final handleWidth = 14 * scale * cosA.abs();
    final handlePaint = Paint()
      ..color = goldBright
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * scale;

    if (cosA >= 0) {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx - 28 * scale, cy - 10 * scale), width: handleWidth + 10, height: 26 * scale),
        pi / 2,
        pi,
        false,
        handlePaint,
      );
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx + 28 * scale, cy - 10 * scale), width: handleWidth + 10, height: 26 * scale),
        -pi / 2,
        pi,
        false,
        handlePaint,
      );
    }

    // Star icon inside cup
    final starPaint = Paint()..color = Colors.white.withOpacity(0.9);
    canvas.drawCircle(Offset(cx, cy - 8 * scale), 4 * scale, starPaint);
  }

  @override
  bool shouldRepaint(covariant _IsometricTrophyPainter oldDelegate) =>
      oldDelegate.angle != angle;
}
