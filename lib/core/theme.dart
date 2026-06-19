import 'package:flutter/material.dart';

class AppTheme {
  static const Color scaffoldBg = Color(0xFF0E0E10);
  static const Color cardBg = Color(0xFF1A1A1D);
  static const Color surface = Color(0xFF242429);
  static const Color primary = Color(0xFF6366F1);
  static const Color accent = Color(0xFF22D3EE);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFFF3F4F6);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color border = Color(0xFF374151);

  static ThemeData get dark {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: scaffoldBg,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surface,
        error: danger,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: textPrimary,
      ),
      cardTheme: CardTheme(
        color: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
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
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      appBarTheme: const AppBarTheme(
        backgroundColor: scaffoldBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: cardBg,
        selectedIconTheme: const IconThemeData(color: primary),
        selectedLabelTextStyle: const TextStyle(color: primary, fontWeight: FontWeight.w600),
        unselectedIconTheme: const IconThemeData(color: textSecondary),
        unselectedLabelTextStyle: const TextStyle(color: textSecondary),
        indicatorColor: primary.withOpacity(0.15),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(surface),
        dataRowColor: WidgetStateProperty.all(cardBg),
        dividerThickness: 1,
        headingTextStyle: const TextStyle(fontWeight: FontWeight.w600, color: textPrimary),
        dataTextStyle: const TextStyle(color: textPrimary),
      ),
    );
  }
}
