import 'package:flutter/material.dart';

class AppColors {
  static bool isDark = false;

  static void applyDark(bool dark) {
    isDark = dark;
  }

  static Color get bg =>
      isDark ? const Color(0xFF0F0F10) : const Color(0xFFF7F8FA);
  static Color get surface =>
      isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);
  static Color get textPrimary =>
      isDark ? const Color(0xFFF2F2F7) : const Color(0xFF17181A);
  static Color get textSecondary =>
      isDark ? const Color(0xFF8E8E93) : const Color(0xFF777B85);
  static Color get divider =>
      isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE7E8EC);
  static Color get bubbleIn =>
      isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEEEFF2);

  static const primary = Color(0xFF3478F6);
  static const success = Color(0xFF34C759);
  static const error = Color(0xFFFF3B30);
}

ThemeData buildAppTheme() {
  final dark = AppColors.isDark;
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      brightness: dark ? Brightness.dark : Brightness.light,
      surface: AppColors.surface,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      hintStyle: TextStyle(color: AppColors.textSecondary),
    ),
  );
}
