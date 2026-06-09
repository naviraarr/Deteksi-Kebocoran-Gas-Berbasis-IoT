import 'package:flutter/material.dart';

// Palet warna terinspirasi dari tabung gas LPG:
// - Biru tabung Pertamina / Elpiji (biru tua industrial)
// - Oranye api & warna branding gas
// - Abu-abu metal tabung
// - Merah bahaya bocor
// - Hijau aman

class AppColors {
  // Background — biru gelap industrial (warna badan tabung LPG gelap)
  static const bg = Color(0xFF07101F);
  static const bgCard = Color(0xFF0C1A2E);
  static const bgCardLight = Color(0xFF112340);
  static const border = Color(0xFF1E3558);

  // Text
  static const textPrimary = Color(0xFFE8F0FF);
  static const textSecondary = Color(0xFF7A9CC4);
  static const textMuted = Color(0xFF4A6A90);

  // Status aman — hijau gas aman
  static const normal = Color(0xFF00D97E);
  static const normalBg = Color(0xFF012A1A);
  static const normalBorder = Color(0xFF015535);

  // Waspada — oranye api / flame
  static const waspada = Color(0xFFFF7C20);
  static const waspadaBg = Color(0xFF1F0D00);
  static const waspadaBorder = Color(0xFF5A2200);

  // Bocor — merah darurat
  static const bocor = Color(0xFFFF2D55);
  static const bocorBg = Color(0xFF1F0008);
  static const bocorBorder = Color(0xFF6B0018);

  // Accent utama — biru Elpiji / Pertamina
  static const accent = Color(0xFF1E90FF);
  static const accentDark = Color(0xFF1266CC);

  // Ekstra
  static const flame = Color(0xFFFF5E00);      // warna api LPG
  static const flameYellow = Color(0xFFFFBE00); // ujung api
  static const steelBlue = Color(0xFF4A90C4);   // tabung baja
  static const metalGray = Color(0xFF8AAABB);   // logam tabung
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: 'Poppins',
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        surface: AppColors.bgCard,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0C1A2E),
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: AppColors.textSecondary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0C1A2E),
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      dividerColor: AppColors.border,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontFamily: 'Poppins'),
        bodyMedium: TextStyle(fontFamily: 'Poppins'),
        bodySmall: TextStyle(fontFamily: 'Poppins'),
        labelLarge: TextStyle(fontFamily: 'Poppins'),
        labelMedium: TextStyle(fontFamily: 'Poppins'),
        labelSmall: TextStyle(fontFamily: 'Poppins'),
      ),
    );
  }
}