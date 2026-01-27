import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

class AppTheme {
  static String formatMoney(double amount, String symbol, {String? locale}) {
    final capitalizedSymbol = symbol.isNotEmpty
        ? '${symbol[0].toUpperCase()}${symbol.substring(1).toLowerCase()}'
        : '';
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: "$capitalizedSymbol ",
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  static const primaryColor = Color(0xFF3ECF8E); // Supabase Green
  static const secondaryColor = Color(0xFF2EAA7B);
  static const accentColor = Color(0xFF34D399);
  static const backgroundColor = Color(0xFFF5F5F5);
  static const darkBackgroundColor = Color(0xFF161616);
  static const surfaceColor = Color(0xFFF4F4F4);
  static const darkSurfaceColor = Color(0xFF1F1F1F);

  static Color parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) {
      return primaryColor;
    }

    try {
      String hex = colorStr.replaceAll('#', '').replaceAll('0x', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      if (hex.length != 8) {
        return primaryColor;
      }
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return primaryColor;
    }
  }

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
      surface: Colors.white,
    ),
    textTheme: _buildScaledTextTheme(ThemeData.light().textTheme, isDark: false),
    scaffoldBackgroundColor: const Color(0xFFF9FAFB), // Very light gray
    dividerTheme: const DividerThemeData(
      color: Color(0xFFF3F4F6),
      thickness: 1,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFFF9FAFB),
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: Color(0xFF4B5563)),
      titleTextStyle: GoogleFonts.inter(
        color: const Color(0xFF111827),
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFF3F4F6), width: 1),
      ),
      color: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 18,
        color: const Color(0xFF111827),
      ),
      contentTextStyle: GoogleFonts.inter(
        fontSize: 14,
        color: const Color(0xFF4B5563),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF1F2937),
      contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: primaryColor,
      secondary: secondaryColor,
      surface: const Color(0xFF1C1C1C),
    ),
    textTheme: _buildScaledTextTheme(ThemeData.dark().textTheme, isDark: true),
    scaffoldBackgroundColor: const Color(0xFF111111),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF2E2E2E),
      thickness: 1,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF111111),
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF2E2E2E), width: 1),
      ),
      color: const Color(0xFF1C1C1C),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1C1C1C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2E2E2E)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2E2E2E)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF1C1C1C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 18,
        color: Colors.white,
      ),
      contentTextStyle: GoogleFonts.inter(
        fontSize: 14,
        color: const Color(0xFFE5E7EB),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF2E2E2E),
      contentTextStyle: GoogleFonts.inter(color: Color(0xFFE5E7EB), fontSize: 13),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  static TextTheme _buildScaledTextTheme(TextTheme base, {required bool isDark}) {
    final bodyColor = isDark ? const Color(0xFFE5E7EB) : const Color(0xFF1F2937);
    final displayColor = isDark ? Colors.white : const Color(0xFF111827);

    return base.copyWith(
      displayLarge: GoogleFonts.outfit(textStyle: base.displayLarge, color: displayColor, fontSize: (base.displayLarge?.fontSize ?? 32) * 0.9 - 0.5),
      displayMedium: GoogleFonts.outfit(textStyle: base.displayMedium, color: displayColor, fontSize: (base.displayMedium?.fontSize ?? 28) * 0.9 - 0.5),
      displaySmall: GoogleFonts.outfit(textStyle: base.displaySmall, color: displayColor, fontSize: (base.displaySmall?.fontSize ?? 24) * 0.9 - 0.5),
      headlineLarge: GoogleFonts.outfit(textStyle: base.headlineLarge, color: displayColor, fontSize: (base.headlineLarge?.fontSize ?? 22) * 0.9 - 0.5),
      headlineMedium: GoogleFonts.outfit(textStyle: base.headlineMedium, color: displayColor, fontSize: (base.headlineMedium?.fontSize ?? 20) * 0.9 - 0.5),
      headlineSmall: GoogleFonts.outfit(textStyle: base.headlineSmall, color: displayColor, fontSize: (base.headlineSmall?.fontSize ?? 18) * 0.9 - 0.5),
      titleLarge: GoogleFonts.outfit(textStyle: base.titleLarge, color: displayColor, fontSize: (base.titleLarge?.fontSize ?? 16) * 0.9 - 0.5),
      titleMedium: GoogleFonts.outfit(textStyle: base.titleMedium, color: bodyColor, fontSize: (base.titleMedium?.fontSize ?? 14) * 0.9 - 0.5),
      titleSmall: GoogleFonts.outfit(textStyle: base.titleSmall, color: bodyColor, fontSize: (base.titleSmall?.fontSize ?? 12) * 0.9 - 0.5),
      bodyLarge: GoogleFonts.outfit(textStyle: base.bodyLarge, color: bodyColor, fontSize: (base.bodyLarge?.fontSize ?? 16) * 0.9 - 0.5),
      bodyMedium: GoogleFonts.outfit(textStyle: base.bodyMedium, color: bodyColor, fontSize: (base.bodyMedium?.fontSize ?? 14) * 0.9 - 0.5),
      bodySmall: GoogleFonts.outfit(textStyle: base.bodySmall, color: bodyColor, fontSize: (base.bodySmall?.fontSize ?? 12) * 0.9 - 0.5),
      labelLarge: GoogleFonts.outfit(textStyle: base.labelLarge, color: bodyColor, fontSize: (base.labelLarge?.fontSize ?? 14) * 0.9 - 0.5),
      labelMedium: GoogleFonts.outfit(textStyle: base.labelMedium, color: bodyColor, fontSize: (base.labelMedium?.fontSize ?? 12) * 0.9 - 0.5),
      labelSmall: GoogleFonts.outfit(textStyle: base.labelSmall, color: bodyColor, fontSize: (base.labelSmall?.fontSize ?? 10) * 0.9 - 0.5),
    );
  }
}
