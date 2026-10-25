import 'package:flutter/material.dart';

class AdminColors {
  static const Color primary = Color(0xFF4338CA); // Indigo 700
  static const Color primaryDark = Color(0xFF312E81); // Indigo 900
  static const Color primaryLight = Color(0xFFEEF2FF); // Indigo 50
  static const Color sidebarBg = Color(0xFF0F172A); // Slate 900

  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF1F5F9); // Slate 100
  static const Color border = Color(0xFFE2E8F0); // Slate 200

  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  static const Color success = Color(0xFF16A34A); // Emerald 600
  static const Color successBg = Color(0xFFDCFCE7); // Emerald 100
  static const Color warning = Color(0xFFD97706); // Amber 600
  static const Color warningBg = Color(0xFFFEF3C7); // Amber 100
  static const Color error = Color(0xFFDC2626); // Red 600
  static const Color errorBg = Color(0xFFFEE2E2); // Red 100
  static const Color info = Color(0xFF0284C7); // Sky 600
  static const Color infoBg = Color(0xFFE0F2FE); // Sky 100
}

class AdminTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AdminColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AdminColors.primary,
        surface: AdminColors.surface,
        error: AdminColors.error,
      ),
      cardTheme: CardThemeData(
        color: AdminColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AdminColors.border, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AdminColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
