import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

class AppTheme {
  static const cardRadius = 16.0;
  static const prominentCardRadius = 24.0;
  static const primaryColor = Color(0xFF287344);
  static const secondaryColor = Color(0xFF287344);
  static const accentColor = primaryColor;
  static const backgroundColor = Color(0xFFF7F8FA);
  static const darkBackgroundColor = Color(0xFF141715);
  static const surfaceColor = Colors.white;
  static const darkSurfaceColor = Color(0xFF202B24);
  static Color link(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFA3D8AE)
      : secondaryColor;

  static String formatMoney(double amount, String symbol, {String? locale}) {
    final number = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: amount == amount.roundToDouble() ? 0 : 2,
    );
    return '${number.format(amount)} $symbol';
  }

  static Color parseColor(String? value) {
    if (value == null) return primaryColor;
    var hex = value.replaceAll('#', '').replaceAll('0x', '');
    if (hex.length == 6) hex = 'FF$hex';
    return hex.length == 8
        ? Color(int.tryParse(hex, radix: 16) ?? primaryColor.toARGB32())
        : primaryColor;
  }

  static final lightTheme = _build(Brightness.light);
  static final darkTheme = _build(Brightness.dark);
  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final background = dark ? darkBackgroundColor : backgroundColor;
    final ink = dark ? const Color(0xFFEDEDED) : const Color(0xFF202B24);
    final muted = dark ? const Color(0xFFA1A1A1) : const Color(0xFF666666);
    final border = dark ? const Color(0xFF303030) : const Color(0xFFDCE5DE);
    final link = dark ? const Color(0xFFA3D8AE) : secondaryColor;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: brightness,
        ).copyWith(
          primary: primaryColor,
          onPrimary: const Color(0xFFFFFFFF),
          secondary: link,
          primaryContainer: dark
              ? const Color(0xFF284B35)
              : const Color(0xFFD5EBD9),
          surfaceContainerLow: dark
              ? darkSurfaceColor
              : const Color(0xFFF1F7F2),
          surface: background,
          onSurface: ink,
          onSurfaceVariant: muted,
          outline: border,
          surfaceContainerHighest: dark
              ? darkSurfaceColor
              : const Color(0xFFE5F0E8),
          error: dark ? const Color(0xFFFF8B95) : const Color(0xFFB42332),
        );
    final text =
        GoogleFonts.aBeeZeeTextTheme(
              ThemeData(brightness: brightness).textTheme,
            )
            .apply(bodyColor: ink, displayColor: ink)
            .copyWith(
              headlineMedium: GoogleFonts.aBeeZee(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                letterSpacing: -.8,
                color: ink,
              ),
              titleLarge: GoogleFonts.aBeeZee(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                letterSpacing: -.8,
                color: ink,
              ),
              titleMedium: GoogleFonts.aBeeZee(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: -.3,
                color: ink,
              ),
              bodyLarge: GoogleFonts.aBeeZee(fontSize: 14, color: ink),
              bodyMedium: GoogleFonts.aBeeZee(fontSize: 14, color: ink),
              bodySmall: GoogleFonts.aBeeZee(fontSize: 12, color: muted),
            );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: text,
      scaffoldBackgroundColor: background,
      cardColor: scheme.surfaceContainerLow,
      dropdownMenuTheme: DropdownMenuThemeData(textStyle: text.bodyMedium),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        elevation: 0,
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(text.bodySmall),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: text.bodyMedium,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      dividerColor: border,
      disabledColor: muted,
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 22,
        titleTextStyle: text.headlineMedium,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: shape,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? darkSurfaceColor : Colors.white,
        contentPadding: const EdgeInsets.all(13),
        labelStyle: text.bodyMedium,
        hintStyle: text.bodySmall,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: link, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(48, 48),
          shape: shape,
          textStyle: GoogleFonts.aBeeZee(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: GoogleFonts.aBeeZee(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          backgroundColor: secondaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          shape: shape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: GoogleFonts.aBeeZee(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          foregroundColor: ink,
          side: BorderSide(color: border),
          minimumSize: const Size(48, 48),
          shape: shape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: link,
          textStyle: GoogleFonts.aBeeZee(fontSize: 14),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: shape,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        clipBehavior: Clip.antiAlias,
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        titleTextStyle: text.bodyMedium,
        subtitleTextStyle: text.bodySmall,
        iconColor: muted,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark
            ? const Color(0xFF303030)
            : const Color(0xFF202B24),
        contentTextStyle: GoogleFonts.aBeeZee(
          color: Colors.white,
          fontSize: 15,
        ),
      ),
    );
  }
}
