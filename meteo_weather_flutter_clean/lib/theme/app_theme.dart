import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors matching Kotlin M3 Palette
  static const Color primary = Color(0xFF38BDF8); // Sky blue
  static const Color secondary = Color(0xFFFFD54F); // Warm Amber
  static const Color tertiary = Color(0xFF67E8F9); // Cyan
  static const Color background = Color(0xFF0F172A); // Dark Slate 900
  static const Color surface = Color(0xFF1E293B); // Dark Slate 800
  static const Color cardColor = Color(0x331E293B); // Glassmorphism translucent
  static const Color borderLight = Color(0x22FFFFFF); // Border outline
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Severe Alert Colors
  static const Color alertEmergency = Color(0xFFEF4444); // Red
  static const Color alertWarning = Color(0xFFF97316); // Orange
  static const Color alertWatch = Color(0xFFF59E0B); // Amber
  static const Color alertAdvisory = Color(0xFF3B82F6); // Blue

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        surface: surface,
        onPrimary: Color(0xFF0F172A),
        onSecondary: Color(0xFF0F172A),
        onSurface: textPrimary,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface.withValues(alpha: 0.65),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
    );
  }
}
