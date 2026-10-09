import 'package:flutter/material.dart';

class ColorPalette {
  static const Map<String, Color> standardColors = {
    'Red': Color(0xFFEF4444),
    'Blue': Color(0xFF3B82F6),
    'Green': Color(0xFF10B981),
    'Yellow': Color(0xFFF59E0B),
    'Orange': Color(0xFFF97316),
    'Purple': Color(0xFF8B5CF6),
  };

  static Color getColor(String nameOrHex) {
    if (standardColors.containsKey(nameOrHex)) {
      return standardColors[nameOrHex]!;
    }
    // Try hex parsing
    try {
      final hex = nameOrHex.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF6366F1); // fallback indigo
  }

  static Color getContrastTextColor(Color background) {
    // Calculate relative luminance to determine optimal text color
    final luminance = background.computeLuminance();
    return luminance > 0.45 ? Colors.black87 : Colors.white;
  }

  static LinearGradient getCardGradient(Color baseColor) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor.withOpacity(0.95),
        baseColor.withOpacity(0.75),
      ],
    );
  }
}
