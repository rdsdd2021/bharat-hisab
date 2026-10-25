import 'package:flutter/material.dart';
import 'google_fonts.dart';

class EzoColors {
  // Brand Colors
  static const Color primary = Color(0xFF2563EB); // Electric Royal Blue
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFFEFF6FF); // Blue 50
  
  // Slate Neutral Hierarchy
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceSecondary = Color(0xFFF1F5F9); // Slate 100
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color borderSubtle = Color(0xFFF1F5F9);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF64748B); // Slate 500
  static const Color textDisabled = Color(0xFF94A3B8); // Slate 400
  
  // Semantic Accents
  static const Color success = Color(0xFF16A34A); // Green 600
  static const Color successBg = Color(0xFFDCFCE7); // Green 100
  static const Color warning = Color(0xFFD97706); // Amber 600
  static const Color warningBg = Color(0xFFFEF3C7); // Amber 100
  static const Color error = Color(0xFFDC2626); // Red 600
  static const Color errorBg = Color(0xFFFEE2E2); // Red 100
  
  // Special Accents
  static const Color whatsapp = Color(0xFF25D366);
  static const Color upiPurple = Color(0xFF5F259F);
}

class EzoTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: EzoColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: EzoColors.primary,
        surface: EzoColors.surface,
        primary: EzoColors.primary,
        onPrimary: Colors.white,
      ),
      fontFamilyFallback: GoogleFonts.plusJakartaSans().fontFamilyFallback,
      appBarTheme: AppBarTheme(
        backgroundColor: EzoColors.surface,
        foregroundColor: EzoColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: EzoColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: EzoColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: EzoColors.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: EzoColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: EzoColors.textPrimary,
          side: const BorderSide(color: EzoColors.border, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: EzoColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: EzoColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: EzoColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: EzoColors.primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: EzoColors.textMuted,
          fontSize: 13,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: EzoColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
