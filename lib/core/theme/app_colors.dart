import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds
  static const background = Color(0xFF0B0F1A);
  static const surface = Color(0xFF121826);
  static const surfaceLight = Color(0xFF1B2336);
  static const surfaceBright = Color(0xFF24304A);

  // Primaries
  static const primary = Color(0xFF00D1B2);
  static const primaryDim = Color(0xFF0E9F8D);
  static const secondary = Color(0xFFFF6B6B);
  static const secondaryDim = Color(0xFFE65050);
  static const accent = Color(0xFFF2C14E);
  static const accentDim = Color(0xFFD9A63D);

  // Semantic
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const success = Color(0xFF22C55E);

  // Text
  static const textPrimary = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFFB7C0D0);
  static const textMuted = Color(0xFF6B7280);

  // Borders & Glass
  static const border = Color(0xFF24304A);
  static const glassBg = Color(0x14FFFFFF);
  static const glassStroke = Color(0x1FFFFFFF);

  // Rank medals
  static const gold = Color(0xFFFFD700);
  static const silver = Color(0xFFC0C0C0);
  static const bronze = Color(0xFFCD7F32);

  // Gradients
  static const neonGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const neonGradientVertical = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const darkGradient = LinearGradient(
    colors: [Color(0xFF0B0F1A), Color(0xFF121826)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const cardGradient = LinearGradient(
    colors: [Color(0x1A00D1B2), Color(0x14FF6B6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const silverGradient = LinearGradient(
    colors: [Color(0xFFC0C0C0), Color(0xFF808080)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const bronzeGradient = LinearGradient(
    colors: [Color(0xFFCD7F32), Color(0xFF8B4513)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color rankColor(int rank) {
    switch (rank) {
      case 1:
        return gold;
      case 2:
        return silver;
      case 3:
        return bronze;
      default:
        return primary;
    }
  }

  static LinearGradient rankGradient(int rank) {
    switch (rank) {
      case 1:
        return goldGradient;
      case 2:
        return silverGradient;
      case 3:
        return bronzeGradient;
      default:
        return neonGradient;
    }
  }
}
