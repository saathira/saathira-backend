import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Saathira design tokens.
class AppColors {
  static const primary = Color(0xFF7C4DFF); // single purple color
  static const secondary = Color(0xFF7C4DFF); // single purple color across complete app
  static const bg = Color(0xFF0F0E17);
  static const surface = Color(0xFF1A1826);
  static const text = Color(0xFFF4F2FF);
  static const muted = Color(0xFF9A96B5);

  static const brandGradient = LinearGradient(
    colors: [primary, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData dark() {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: GoogleFonts.outfit().fontFamily,
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        onSurface: AppColors.text,
      ),
      textTheme: base.textTheme
          .apply(bodyColor: AppColors.text, displayColor: AppColors.text),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
