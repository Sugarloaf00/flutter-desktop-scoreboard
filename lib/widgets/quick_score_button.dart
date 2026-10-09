import 'package:flutter/material.dart';

class QuickScoreButton extends StatelessWidget {
  final int delta;
  final VoidCallback onPressed;
  final Color? color;

  const QuickScoreButton({
    super.key,
    required this.delta,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = delta > 0;
    final text = isPositive ? '+$delta' : '$delta';
    final btnColor = color ?? (isPositive ? Colors.green.shade700 : Colors.red.shade700);

    return Material(
      color: btnColor.withOpacity(0.15),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: btnColor.withOpacity(0.4), width: 1.5),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: btnColor,
            ),
          ),
        ),
      ),
    );
  }
}
