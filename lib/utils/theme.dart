import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Colores
      colorScheme: const ColorScheme.dark(
        primary: Color(AppColors.accentRed),
        secondary: Color(AppColors.accentSilver),
        surface: Color(AppColors.secondaryBlack),
        background: Color(AppColors.primaryBlack),
        error: Color(AppColors.danger),
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Color(AppColors.textPrimary),
        onBackground: Color(AppColors.textPrimary),
      ),
      
      // Scaffold
      scaffoldBackgroundColor: const Color(AppColors.primaryBlack),
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(AppColors.secondaryBlack),
        foregroundColor: const Color(AppColors.textPrimary),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.rajdhani(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(AppColors.textPrimary),
          letterSpacing: 1.5,
        ),
      ),
      
      // Cards
      cardTheme: CardTheme(
        color: const Color(AppColors.cardBlack),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: Color(AppColors.borderGray),
            width: 1,
          ),
        ),
      ),
      
      // Botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(AppColors.accentRed),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.rajdhani(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ),
      
      // Botones texto
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(AppColors.accentSilver),
          textStyle: GoogleFonts.rajdhani(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(AppColors.secondaryBlack),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(AppColors.borderGray)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(AppColors.borderGray)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(AppColors.accentRed), width: 2),
        ),
        hintStyle: GoogleFonts.rajdhani(
          color: const Color(AppColors.textMuted),
        ),
      ),
      
      // Texto
      textTheme: TextTheme(
        displayLarge: GoogleFonts.rajdhani(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: const Color(AppColors.textPrimary),
          letterSpacing: 2,
        ),
        displayMedium: GoogleFonts.rajdhani(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: const Color(AppColors.textPrimary),
          letterSpacing: 1.5,
        ),
        headlineLarge: GoogleFonts.rajdhani(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: const Color(AppColors.textPrimary),
        ),
        headlineMedium: GoogleFonts.rajdhani(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(AppColors.textPrimary),
        ),
        titleLarge: GoogleFonts.rajdhani(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: const Color(AppColors.textPrimary),
        ),
        bodyLarge: GoogleFonts.rajdhani(
          fontSize: 16,
          color: const Color(AppColors.textPrimary),
        ),
        bodyMedium: GoogleFonts.rajdhani(
          fontSize: 14,
          color: const Color(AppColors.textSecondary),
        ),
        bodySmall: GoogleFonts.rajdhani(
          fontSize: 12,
          color: const Color(AppColors.textMuted),
        ),
      ),
      
      // Iconos
      iconTheme: const IconThemeData(
        color: Color(AppColors.textPrimary),
        size: 24,
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: Color(AppColors.borderGray),
        thickness: 1,
      ),
      
      // BottomNav
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(AppColors.secondaryBlack),
        selectedItemColor: Color(AppColors.accentRed),
        unselectedItemColor: Color(AppColors.textMuted),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
