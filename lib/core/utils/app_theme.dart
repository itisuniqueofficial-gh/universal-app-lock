import 'package:flutter/material.dart';

/// Central theme for Universal App Lock: dark, minimal, **sharp** (zero corner
/// radius), blue accent, thin borders, high contrast, no gradients/shadows.
/// Presentation-only; no business/security logic.
class AppTheme {
  AppTheme._();

  static const Color blue = Color(0xFF3B82F6);
  static const Color background = Color(0xFF0B0F14);
  static const Color surface = Color(0xFF11161D);
  static const Color border = Color(0xFF1E2833);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Sharp design rule: rectangular surfaces, no rounded corners.
  static const RoundedRectangleBorder _sharp = RoundedRectangleBorder(
    borderRadius: BorderRadius.zero,
  );

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: blue,
      brightness: Brightness.dark,
    ).copyWith(primary: blue, surface: surface, outline: border, error: error);

    OutlineInputBorder inputBorder(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: c),
    );

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
        border: inputBorder(border),
        enabledBorder: inputBorder(border),
        focusedBorder: inputBorder(blue),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: _sharp),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(shape: _sharp, elevation: 0),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: _sharp,
          side: const BorderSide(color: border),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: _sharp),
      ),
      dialogTheme: const DialogThemeData(
        shape: _sharp,
        backgroundColor: surface,
      ),
      snackBarTheme: const SnackBarThemeData(
        shape: _sharp,
        behavior: SnackBarBehavior.fixed,
      ),
      chipTheme: const ChipThemeData(shape: _sharp),
    );
  }
}
