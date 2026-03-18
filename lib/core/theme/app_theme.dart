import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Home / Image-to-PDF palette (navy/indigo/cyan)
  static const Color primaryIndigo = Color(0xFF4F46E5);
  static const Color primaryIndigoLight = Color(0xFF6366F1);
  static const Color accentCyan = Color(0xFF22D3EE);
  static const Color backgroundDarkNavy = Color(0xFF0F172A);
  static const Color cardDark = Color(0x661E293B); // rgba(30,41,59,0.4)
  static const Color cardBorder = Color(0x0DFFFFFF); // rgba(255,255,255,0.05)

  // History / Settings palette (brown/orange)
  static const Color primaryOrange = Color(0xFFEC5B13);
  static const Color backgroundDarkBrown = Color(0xFF1A120E);
  static const Color backgroundDarkBrownSettings = Color(0xFF221610);

  // Common
  static const Color textPrimary = Color(0xFFF1F5F9); // slate-100
  static const Color textSecondary = Color(0xFF94A3B8); // slate-400
  static const Color textTertiary = Color(0xFF64748B); // slate-500
  static const Color surfaceLight = Color(0x08FFFFFF); // white/[0.03]
  static const Color divider = Color(0x0DFFFFFF); // white/5

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDarkNavy,
      primaryColor: primaryIndigo,
      colorScheme: const ColorScheme.dark(
        primary: primaryIndigo,
        secondary: accentCyan,
        surface: backgroundDarkNavy,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.publicSansTextTheme(
        ThemeData.dark().textTheme,
      ),
      fontFamily: GoogleFonts.publicSans().fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.publicSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundDarkNavy,
        selectedItemColor: primaryIndigo,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8F6F6),
      primaryColor: primaryIndigo,
      colorScheme: const ColorScheme.light(
        primary: primaryIndigo,
        secondary: accentCyan,
        surface: Color(0xFFF8F6F6),
        onPrimary: Colors.white,
      ),
      textTheme: GoogleFonts.publicSansTextTheme(
        ThemeData.light().textTheme,
      ),
      fontFamily: GoogleFonts.publicSans().fontFamily,
    );
  }
}
