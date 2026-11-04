import 'package:flutter/material.dart';

class AppColors {
  // Brand colors (FPT & Startup energy)
  static const Color primary = Color(0xFFF26522); // FPT Orange
  static const Color primaryDark = Color(0xFFD84315);
  static const Color primaryLight = Color(0xFFFFE0B2);

  static const Color secondary = Color(0xFF1E293B); // Slate Navy
  static const Color accentNavy = Color(0xFF0F172A);
  static const Color accentTeal = Color(0xFF0D9488); // Success / Qualified

  // Status & Warning (BR-18, BR-19)
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color warningBackground = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);

  static const Color success = Color(0xFF10B981);
  static const Color successBackground = Color(0xFFECFDF5);

  static const Color error = Color(0xFFEF4444);
  static const Color errorBackground = Color(0xFFFEF2F2);

  // Background & Surface
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Chuyên ngành Badges
  static Color getMajorColor(String major) {
    switch (major.trim().toUpperCase()) {
      case 'SE':
        return const Color(0xFF2563EB); // Royal Blue
      case 'BA':
        return const Color(0xFF7C3AED); // Purple
      case 'MKT':
        return const Color(0xFFEA580C); // Warm Orange
      case 'GD':
        return const Color(0xFFDB2777); // Pink
      case 'IA':
        return const Color(0xFF059669); // Emerald
      default:
        return const Color(0xFF475569); // Slate
    }
  }
}
