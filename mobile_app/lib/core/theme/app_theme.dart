import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryBlue = Color(0xFF3461E5);
  static const Color accentBlue = Color(0xFF6E8EFB);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF8F9FB);

  // Status Colors
  static const Color riskHigh = Color(0xFFFF9800);
  static const Color riskHighLight = Color(0xFFFFF3E0);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color xpGradientStart = Color(0xFF2EBE71);
  static const Color xpGradientEnd = Color(0xFF8CC63F);

  static const Color infoBoxBg = Color(0xFFEBF3FF);
  static const Color infoBoxBorder = Color(0xFFB3D4FF);
  static const Color infoBoxText = Color(0xFF003A8C);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        surface: surfaceWhite,
      ),
      textTheme: GoogleFonts.outfitTextTheme(),
      cardTheme: CardThemeData(
        elevation: 10,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
