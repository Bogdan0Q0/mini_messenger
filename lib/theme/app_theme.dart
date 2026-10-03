import 'package:flutter/material.dart';

/// Акцентные цвета, одинаковые в обеих темах.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF3478F6);
  static const success = Color(0xFF34C759);
  static const error = Color(0xFFFF3B30);
}

/// Цвета, которые зависят от темы.
///
/// Лежат внутри [ThemeData] (как [ThemeExtension]), поэтому все виджеты,
/// читающие их через `context.palette`, автоматически перестраиваются
/// при смене темы — в том числе экраны, уже лежащие в стеке навигации.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color bg;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final Color bubbleIn;
  final Color unreadBg;

  const AppPalette({
    required this.bg,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.bubbleIn,
    required this.unreadBg,
  });

  static const light = AppPalette(
    bg: Color(0xFFF7F8FA),
    surface: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF17181A),
    textSecondary: Color(0xFF777B85),
    divider: Color(0xFFE7E8EC),
    bubbleIn: Color(0xFFEEEFF2),
    unreadBg: Color(0xFFE0F2FE),
  );

  static const dark = AppPalette(
    bg: Color(0xFF0F0F10),
    surface: Color(0xFF1C1C1E),
    textPrimary: Color(0xFFF2F2F7),
    textSecondary: Color(0xFF8E8E93),
    divider: Color(0xFF2C2C2E),
    bubbleIn: Color(0xFF2C2C2E),
    unreadBg: Color(0xFF1A2D45),
  );

  @override
  AppPalette copyWith({
    Color? bg,
    Color? surface,
    Color? textPrimary,
    Color? textSecondary,
    Color? divider,
    Color? bubbleIn,
    Color? unreadBg,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      divider: divider ?? this.divider,
      bubbleIn: bubbleIn ?? this.bubbleIn,
      unreadBg: unreadBg ?? this.unreadBg,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      bubbleIn: Color.lerp(bubbleIn, other.bubbleIn, t)!,
      unreadBg: Color.lerp(unreadBg, other.unreadBg, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  /// Цвета текущей темы: `context.palette.textPrimary`.
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

final ThemeData lightTheme = _buildTheme(Brightness.light, AppPalette.light);
final ThemeData darkTheme = _buildTheme(Brightness.dark, AppPalette.dark);

ThemeData _buildTheme(Brightness brightness, AppPalette p) {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: brightness,
  ).copyWith(
    primary: AppColors.primary,
    error: AppColors.error,
    surface: p.surface,
    onSurface: p.textPrimary,
    onSurfaceVariant: p.textSecondary,
    outline: p.divider,
    outlineVariant: p.divider,
  );

  OutlineInputBorder border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg,
    canvasColor: p.surface,
    dividerColor: p.divider,
    extensions: [p],
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.primary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border(p.divider),
      enabledBorder: border(p.divider),
      focusedBorder: border(AppColors.primary, 1.5),
      hintStyle: TextStyle(color: p.textSecondary),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: p.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: TextStyle(color: p.textSecondary, fontSize: 15),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      modalBackgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
    ),
    listTileTheme: ListTileThemeData(
      textColor: p.textPrimary,
      iconColor: p.textSecondary,
    ),
  );
}
