import 'package:flutter/material.dart';

class WinnerGlow extends StatefulWidget {
  final Widget child;
  final bool isLeading;
  final Color baseColor;

  const WinnerGlow({
    super.key,
    required this.child,
    required this.isLeading,
    required this.baseColor,
  });

  @override
  State<WinnerGlow> createState() => _WinnerGlowState();
}

class _WinnerGlowState extends State<WinnerGlow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _glowAnimation = Tween<double>(begin: 3.0, end: 14.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isLeading) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(WinnerGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLeading && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isLeading && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLeading) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.65), // Golden leader glow
                blurRadius: _glowAnimation.value,
                spreadRadius: _glowAnimation.value / 3,
              ),
              BoxShadow(
                color: widget.baseColor.withOpacity(0.4),
                blurRadius: _glowAnimation.value * 1.5,
                spreadRadius: 2,
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
