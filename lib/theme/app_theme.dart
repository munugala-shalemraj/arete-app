import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Colour-blind-safe semantic colours ───────────────────────────────────────
// Correct = blue  (safe for protanopia, deuteranopia, tritanopia)
// Wrong   = orange (safe for all types; never red)
// Selected = gold (brand colour)
class AColors {
  AColors._();
  static const correct  = Color(0xFF2563EB); // blue
  static const wrong    = Color(0xFFEA580C); // orange
  static const selected = Color(0xFFF59E0B); // gold/amber

  static const gold   = Color(0xFFFFD700);
  static const teal   = Color(0xFF00D4AA);
  static const blue   = Color(0xFF4B8BBE);
  static const purple = Color(0xFF9B59B6);
  static const indigo = Color(0xFF6C5CE7);
}

// ── Context extension for theme-aware backgrounds ─────────────────────────────
extension AppColorsX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Backgrounds
  Color get bgPrimary => isDark
      ? const Color(0xFF0A0A1F) : const Color(0xFFF0F2FF);
  Color get bgCard => isDark
      ? const Color(0xFF12122A) : Colors.white;
  Color get bgSurface => isDark
      ? const Color(0xFF1A1A2E) : const Color(0xFFE8EAFF);

  // Text
  Color get textPrimary   => isDark ? Colors.white        : const Color(0xFF0D0F1A);
  Color get textSecondary => isDark ? Colors.white54      : const Color(0xFF4A4A6A);
  Color get textHint      => isDark ? Colors.white38      : const Color(0xFF8888AA);
  Color get textDisabled  => isDark ? Colors.white24      : const Color(0xFFBBBBCC);

  // Borders
  Color get borderSubtle => isDark
      ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.08);
  Color get borderMid => isDark
      ? Colors.white12 : Colors.black12;
}

// ── ThemeData builders ────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData dark() => _build(Brightness.dark);
  static ThemeData light() => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final bg      = isDark ? const Color(0xFF0A0A1F) : const Color(0xFFF0F2FF);
    final card    = isDark ? const Color(0xFF12122A) : Colors.white;
    final surface = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFE8EAFF);
    final onBg    = isDark ? Colors.white            : const Color(0xFF0D0F1A);
    final onCard  = isDark ? Colors.white            : const Color(0xFF0D0F1A);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AColors.gold,
        onPrimary: Colors.black,
        secondary: AColors.blue,
        onSecondary: Colors.white,
        tertiary: AColors.teal,
        onTertiary: Colors.black,
        error: AColors.wrong,
        onError: Colors.white,
        surface: card,
        onSurface: onCard,
        surfaceContainerHighest: surface,
        outline: isDark ? Colors.white12 : Colors.black12,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ).apply(bodyColor: onBg, displayColor: onBg),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: onBg),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20, fontWeight: FontWeight.w700, color: onBg),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        indicatorColor: AColors.gold.withOpacity(0.15),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.outfit(fontSize: 12)),
        iconTheme: WidgetStateProperty.resolveWith((states) =>
          IconThemeData(color: states.contains(WidgetState.selected)
            ? AColors.gold : (isDark ? Colors.white30 : Colors.black38))),
      ),
      cardColor: card,
      cardTheme: CardThemeData(
        color: card,
        elevation: isDark ? 0 : 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogBackgroundColor: surface,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: TextStyle(color: onCard),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AColors.gold,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF0A0A1F) : const Color(0xFFEEEEFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12)),
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : const Color(0xFF8888AA)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AColors.gold : Colors.grey),
        trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
            ? AColors.gold.withOpacity(0.4) : Colors.grey.withOpacity(0.3)),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AColors.purple,
        thumbColor: AColors.purple,
        inactiveTrackColor: Color(0x22000000),
      ),
      dividerColor: isDark ? Colors.white10 : Colors.black12,
    );
  }
}
