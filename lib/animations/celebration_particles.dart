import 'dart:math';
import 'package:flutter/material.dart';

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;
  double alpha;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    this.alpha = 1.0,
  });
}

class CelebrationParticlesOverlay extends StatefulWidget {
  final Widget child;
  final bool isTriggered;

  const CelebrationParticlesOverlay({
    super.key,
    required this.child,
    this.isTriggered = false,
  });

  @override
  State<CelebrationParticlesOverlay> createState() => _CelebrationParticlesOverlayState();
}

class _CelebrationParticlesOverlayState extends State<CelebrationParticlesOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final Random _random = Random();

  final List<Color> _colors = const [
    Color(0xFFFFD700),
    Color(0xFFEF4444),
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF97316),
    Color(0xFF8B5CF6),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..addListener(_updateParticles);

    if (widget.isTriggered) {
      _spawnParticles();
    }
  }

  @override
  void didUpdateWidget(CelebrationParticlesOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTriggered && !oldWidget.isTriggered) {
      _spawnParticles();
    }
  }

  void _spawnParticles() {
    _particles.clear();
    for (int i = 0; i < 70; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = _random.nextDouble() * 300 + 100;
      _particles.add(
        Particle(
          x: 0,
          y: 0,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          size: _random.nextDouble() * 8 + 4,
          color: _colors[_random.nextInt(_colors.length)],
        ),
      );
    }
    _controller.forward(from: 0.0);
  }

  void _updateParticles() {
    final dt = 0.016;
    for (final p in _particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 250 * dt; // Gravity
      p.alpha = (1.0 - _controller.value).clamp(0.0, 1.0);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_controller.isAnimating)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ParticlePainter(_particles),
              ),
            ),
          ),
      ],
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 3);
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withOpacity(p.alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center + Offset(p.x, p.y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
