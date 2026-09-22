import 'package:flutter/material.dart';

/// Central theme for Universal App Lock: dark, minimalist, flat, blue accent,
/// thin borders, high contrast, minimal shadows, no gradients.
/// Presentation-only; contains no business or security logic.
class AppTheme {
  AppTheme._();

  static const Color blue = Color(0xFF3B82F6);
  static const Color background = Color(0xFF0B0F14);
  static const Color surface = Color(0xFF11161D);
  static const Color border = Color(0xFF1E2833);

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: blue,
      brightness: Brightness.dark,
    ).copyWith(primary: blue, surface: surface, outline: border);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      dividerColor: border,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: blue),
        ),
      ),
    );
  }
}
