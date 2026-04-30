import 'package:flutter/material.dart';

class AppTheme {
  static const bgPrimary = Color(0xFF0D1117);
  static const bgSurface = Color(0xFF161B22);
  static const bgElevated = Color(0xFF1C2128);
  static const tealPrimary = Color(0xFF00BFA5);
  static const tealDark = Color(0xFF00897B);
  static const tealLight = Color(0xFF4DD0E1);
  static const tealAlpha = Color(0x3300BFA5);
  static const textPrimary = Color(0xFFEAECEF);
  static const textSecondary = Color(0xFF8B949E);
  static const textHint = Color(0xFF4A5568);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgPrimary,
        colorScheme: const ColorScheme.dark(
          primary: tealPrimary,
          secondary: tealLight,
          surface: bgSurface,
          background: bgPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bgPrimary,
          foregroundColor: textPrimary,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: bgSurface,
          selectedItemColor: tealPrimary,
          unselectedItemColor: textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: textPrimary),
          bodyMedium: TextStyle(color: textSecondary),
          titleLarge: TextStyle(
              color: textPrimary, fontWeight: FontWeight.bold),
        ),
        cardTheme: const CardThemeData(
          color: bgSurface,
          elevation: 0,
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: tealPrimary,
          inactiveTrackColor: textHint,
          thumbColor: tealPrimary,
          overlayColor: tealAlpha,
          trackHeight: 3,
          thumbShape:
              RoundSliderThumbShape(enabledThumbRadius: 6),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: bgSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: textHint),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: bgSurface,
          titleTextStyle: const TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}
