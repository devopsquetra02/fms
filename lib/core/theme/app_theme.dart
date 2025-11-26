import 'package:flutter/material.dart';

/// Defines the application's theme configuration.
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    const primary = Color(0xFF1B63FF); // clean blue
    const surface = Color(0xFFF7F8FA);
    const text = Color(0xFF0F172A);
    const subtleText = Color(0xFF64748B);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      surface: surface,
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: text,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.2),
        ),
      ),
      textTheme: Typography.blackMountainView.copyWith(
        bodyMedium: const TextStyle(color: subtleText, height: 1.25),
        bodyLarge: const TextStyle(color: text, height: 1.3),
        titleMedium: const TextStyle(color: text, fontWeight: FontWeight.w600),
      ),
      useMaterial3: true,
    );
  }
}
