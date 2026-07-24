import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Single premium dark/gradient identity — this product deliberately does
/// not offer a flat light theme; the gradient + glassmorphism look IS the
/// brand, in both "light" and "dark" system settings.
class AppTheme {
  AppTheme._();

  static const double radiusCard = 20;
  static const double radiusControl = 14;
  static const double radiusPill = 999;

  static ThemeData build() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.navyDeep,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.goldMid,
        secondary: AppColors.goldLight,
        surface: AppColors.navyMid,
        error: AppColors.statusRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: _textTheme(),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.goldMid,
          foregroundColor: AppColors.navyDeep,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPill)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.goldLight),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassFill,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: const BorderSide(color: AppColors.goldMid, width: 1.5),
        ),
      ),
      dividerColor: AppColors.glassBorder,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.navyMid,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusControl)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static TextTheme _textTheme() {
    const primary = AppColors.textPrimary;
    const secondary = AppColors.textSecondary;
    return const TextTheme(
      displayLarge: TextStyle(fontSize: 34, height: 1.2, fontWeight: FontWeight.w800, color: primary),
      headlineMedium: TextStyle(fontSize: 24, height: 1.3, fontWeight: FontWeight.w700, color: primary),
      titleLarge: TextStyle(fontSize: 19, height: 1.35, fontWeight: FontWeight.w700, color: primary),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: primary),
      bodyMedium: TextStyle(fontSize: 14, height: 1.43, color: secondary),
      bodySmall: TextStyle(fontSize: 12, height: 1.33, fontWeight: FontWeight.w600, color: secondary),
    );
  }
}
