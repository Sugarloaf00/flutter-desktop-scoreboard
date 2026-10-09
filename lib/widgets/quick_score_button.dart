import 'package:flutter/material.dart';

class QuickScoreButton extends StatelessWidget {
  final int delta;
  final VoidCallback onPressed;
  final Color? color;
  final String? label;

  const QuickScoreButton({
    super.key,
    required this.delta,
    required this.onPressed,
    this.color,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = delta > 0;
    final text = isPositive ? '+$delta' : '$delta';
    final btnColor = color ?? (isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444));

    return Material(
      color: btnColor.withOpacity(0.14),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: btnColor.withOpacity(0.35), width: 1.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label != null) ...[
                Text(
                  label!.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: btnColor.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: btnColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
