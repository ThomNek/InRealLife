import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF181926);
  static const surface = Color(0xFF202231);
  static const surfaceAlt = Color(0xFF262A3D);
  static const orange = Color(0xFFFF6B00);
  static const cyan = Color(0xFF00E5FF);
  static const muted = Color(0xFF94A3B8);
  static const border = Color(0x14FFFFFF);
}

abstract final class AppTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.orange,
      secondary: AppColors.cyan,
      surface: AppColors.surface,
    ),
    actionIconTheme: ActionIconThemeData(
      backButtonIconBuilder: (BuildContext context) =>
          const Icon(Icons.arrow_back_rounded),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.w900),
      titleMedium: TextStyle(fontWeight: FontWeight.w800),
      bodyMedium: TextStyle(color: Color(0xFFC6CEDF), height: 1.45),
    ),
    dividerColor: AppColors.border,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: Color(0xFF64748B)),
      prefixIconColor: AppColors.muted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.cyan),
      ),
    ),
  );
}
