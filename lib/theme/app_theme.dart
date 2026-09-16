import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFFF7F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFF3478F6);
  static const primaryDark = Color(0xFF2463D5);
  static const textPrimary = Color(0xFF17181A);
  static const textSecondary = Color(0xFF777B85);
  static const divider = Color(0xFFE7E8EC);
  static const success = Color(0xFF34C759);
  static const error = Color(0xFFFF3B30);
  static const bubbleIn = Color(0xFFEEEFF2);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      hintStyle: const TextStyle(color: Color(0xFFB0B4BC)),
    ),
  );
}
