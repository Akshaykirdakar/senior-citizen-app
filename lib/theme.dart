import 'package:flutter/material.dart';

/// Palette grounded in the association's banyan-tree emblem (green = longevity)
/// with an auspicious marigold accent, high-contrast for older eyes.
class AppColors {
  static const green = Color(0xFF14503C);
  static const greenDeep = Color(0xFF0D3A2B);
  static const greenSoft = Color(0xFFE4EFE9);
  static const marigold = Color(0xFFE29429);
  static const marigoldSoft = Color(0xFFFBEBD3);
  static const cream = Color(0xFFFAF6EC);
  static const card = Colors.white;
  static const ink = Color(0xFF22201B);
  static const muted = Color(0xFF6B6A63);
  static const line = Color(0xFFE7E1D3);
  static const male = Color(0xFF2F6DB0);
  static const female = Color(0xFFB0426F);
  static const danger = Color(0xFFB23B3B);
}

ThemeData buildTheme() {
  final base = ThemeData(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.cream,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.green,
      secondary: AppColors.marigold,
      surface: AppColors.card,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
  );
}
