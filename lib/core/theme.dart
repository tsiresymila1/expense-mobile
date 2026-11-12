import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

class AppTheme {
  static const cardRadius = 20.0;
  static const prominentCardRadius = 28.0;
  static const primaryColor = Color(0xFF287344);
  static const secondaryColor = Color(0xFF287344);
  static const accentColor = primaryColor;
  static const backgroundColor = Color(0xFFF3F7F4);
  static const darkBackgroundColor = Color(0xFF0F1511);
  static const surfaceColor = Colors.white;
  static const darkSurfaceColor = Color(0xFF18201B);
  // v6 tokens: income is the only value tinted green, expenses stay neutral.
  static const darkPrimary = Color(0xFF5BBE7B);
  static const heroLight = [Color(0xFF2E8050), Color(0xFF1B5733)];
  static const heroDark = [Color(0xFF245C3B), Color(0xFF153A26)];
  static Color link(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF7ED69A)
      : const Color(0xFF1B6A38);
  static Color expenseAccent(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFF2A073)
      : const Color(0xFF9A4A1F);

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
    final primary = dark ? darkPrimary : primaryColor;
    final onPrimary = dark ? const Color(0xFF07140C) : Colors.white;
    final ink = dark ? const Color(0xFFEAF1EC) : const Color(0xFF13201A);
    final muted = dark ? const Color(0xFF9DB0A3) : const Color(0xFF55665B);
    final border = dark ? const Color(0xFF2B3730) : const Color(0xFFD9E3DC);
    final link = dark ? const Color(0xFF7ED69A) : const Color(0xFF1B6A38);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: brightness,
        ).copyWith(
          primary: primary,
          onPrimary: onPrimary,
          secondary: link,
          primaryContainer: dark
              ? const Color(0xFF1F3427)
              : const Color(0xFFE0EFE4),
          surfaceContainerLow: dark
              ? darkSurfaceColor
              : const Color(0xFFFFFFFF),
          surface: background,
          onSurface: ink,
          onSurfaceVariant: muted,
          outline: border,
          surfaceContainerHighest: dark
              ? darkSurfaceColor
              : const Color(0xFFEAF1EC),
          error: dark ? const Color(0xFFFF8B95) : const Color(0xFFB42332),
        );
    final text =
        GoogleFonts.geistTextTheme(
              ThemeData(brightness: brightness).textTheme,
            )
            .apply(bodyColor: ink, displayColor: ink)
            .copyWith(
              headlineMedium: GoogleFonts.geist(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                letterSpacing: -.8,
                color: ink,
              ),
              titleLarge: GoogleFonts.geist(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                letterSpacing: -.8,
                color: ink,
              ),
              titleMedium: GoogleFonts.geist(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: -.3,
                color: ink,
              ),
              bodyLarge: GoogleFonts.geist(fontSize: 14, color: ink),
              bodyMedium: GoogleFonts.geist(fontSize: 14, color: ink),
              bodySmall: GoogleFonts.geist(fontSize: 12, color: muted),
            );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(cardRadius),
      side: BorderSide(color: border),
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
        height: 72,
        elevation: 0,
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(text.bodySmall),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: border),
        shape: const StadiumBorder(),
        labelStyle: text.bodyMedium,
        showCheckmark: false,
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
        shape: cardShape,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
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
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          minimumSize: const Size(48, 48),
          shape: shape,
          textStyle: GoogleFonts.geist(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: GoogleFonts.geist(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size(48, 48),
          shape: shape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: GoogleFonts.geist(
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
          textStyle: GoogleFonts.geist(fontSize: 14),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        clipBehavior: Clip.antiAlias,
        backgroundColor: scheme.surfaceContainerLow,
        showDragHandle: true,
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
        contentTextStyle: GoogleFonts.geist(
          color: Colors.white,
          fontSize: 15,
        ),
      ),
    );
  }
}
