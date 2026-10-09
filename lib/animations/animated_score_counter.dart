import 'package:flutter/material.dart';

class AnimatedScoreCounter extends StatelessWidget {
  final int score;
  final TextStyle textStyle;
  final Duration duration;

  const AnimatedScoreCounter({
    super.key,
    required this.score,
    required this.textStyle,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: score.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Text(
          value.round().toString(),
          style: textStyle,
        );
      },
    );
  }
}
