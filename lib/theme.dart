// lib/theme.dart
//
// Design system di GymTracker 2.0.
// Stessi preset colore della v1, superfici piu morbide, raggi e spaziature
// coerenti, tipografia piu leggibile.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── ACCENT PRESETS ─────────────────────────────────────────────────────────
class AccentPreset {
  final String id;
  final String nameIt;
  final String nameEn;
  final Color primary;
  final Color secondary;

  const AccentPreset({
    required this.id,
    required this.nameIt,
    required this.nameEn,
    required this.primary,
    required this.secondary,
  });
}

const accentPresets = [
  AccentPreset(id: 'obsidian', nameIt: 'Obsidian', nameEn: 'Obsidian', primary: Color(0xFF8B5CF6), secondary: Color(0xFF6366F1)),
  AccentPreset(id: 'ocean', nameIt: 'Oceano', nameEn: 'Ocean', primary: Color(0xFF3B82F6), secondary: Color(0xFF06B6D4)),
  AccentPreset(id: 'emerald', nameIt: 'Smeraldo', nameEn: 'Emerald', primary: Color(0xFF10B981), secondary: Color(0xFF34D399)),
  AccentPreset(id: 'crimson', nameIt: 'Cremisi', nameEn: 'Crimson', primary: Color(0xFFEF4444), secondary: Color(0xFFF97316)),
  AccentPreset(id: 'amber', nameIt: 'Ambra', nameEn: 'Amber', primary: Color(0xFFF59E0B), secondary: Color(0xFFFBBF24)),
  AccentPreset(id: 'rose', nameIt: 'Rosa', nameEn: 'Rose', primary: Color(0xFFEC4899), secondary: Color(0xFFF472B6)),
];

AccentPreset getPreset(String id) =>
    accentPresets.firstWhere((p) => p.id == id, orElse: () => accentPresets.first);

// ─── DYNAMIC THEME COLORS ───────────────────────────────────────────────────
// Colori "correnti", aggiornati da AppTheme.apply()
Color kAccent = const Color(0xFF8B5CF6);
Color kAccent2 = const Color(0xFF6366F1);
Color kBg = const Color(0xFF0A0A0C);
Color kSurface = const Color(0xFF131316);
Color kSurface2 = const Color(0xFF1B1B1F);
Color kSurface3 = const Color(0xFF2A2A30);
Color kText = const Color(0xFFF5F5F7);
Color kText2 = const Color(0xFFA6A6B0);
Color kText3 = const Color(0xFF5B5B66);
const kRed = Color(0xFFEF4444);
const kBlue = Color(0xFF60A5FA);
const kOrange = Color(0xFFFB923C);
const kGreen = Color(0xFF4ADE80);

// Raggi standard: card 18, controlli 12, sheet 28, pillole 999.
const kRadiusCard = 18.0;
const kRadiusControl = 12.0;
const kRadiusSheet = 28.0;
const kRadiusPill = 999.0;

// Spaziature standard: usare queste invece di numeri sparsi.
const kGapPage = 20.0; // margine laterale di pagina
const kGapCard = 12.0; // distanza fra due card
const kGapItem = 8.0; // distanza fra elementi dentro una card
/// Spazio libero in fondo alle liste, per non finire sotto FAB e navbar.
const kBottomSafeSpace = 96.0;

class AppTheme {
  static void apply(String mode, String presetId, {Color? customPrimary}) {
    final useCustom = presetId == 'custom' && customPrimary != null;
    final preset = getPreset(useCustom ? 'obsidian' : presetId);
    kAccent = useCustom ? customPrimary : preset.primary;
    kAccent2 = useCustom ? _deriveSecondary(kAccent) : preset.secondary;

    if (mode == 'dark') {
      kBg = const Color(0xFF0A0A0C);
      kSurface = const Color(0xFF131316);
      kSurface2 = const Color(0xFF1B1B1F);
      kSurface3 = const Color(0xFF2A2A30);
      kText = const Color(0xFFF5F5F7);
      kText2 = const Color(0xFFAFAFB9);
      // Il vecchio 0xFF5B5B66 stava sotto il rapporto 4.5:1 sul fondo scuro:
      // le info secondarie (date, conteggi) erano poco leggibili.
      kText3 = const Color(0xFF7C7C88);
    } else {
      kBg = const Color(0xFFF6F6F9);
      kSurface = const Color(0xFFFFFFFF);
      kSurface2 = const Color(0xFFEFEFF4);
      kSurface3 = const Color(0xFFD8D8DE);
      kText = const Color(0xFF17171B);
      kText2 = const Color(0xFF54545E);
      kText3 = const Color(0xFF80808C);
    }
  }
}

Color _deriveSecondary(Color color) {
  final hsl = HSLColor.fromColor(color);
  final shifted = hsl
      .withHue((hsl.hue + 24) % 360)
      .withSaturation((hsl.saturation * 0.92).clamp(0.0, 1.0))
      .withLightness((hsl.lightness + 0.10).clamp(0.0, 1.0));
  return shifted.toColor();
}

Color? parseHexColor(String hex) {
  var value = hex.trim().toUpperCase();
  if (value.startsWith('#')) value = value.substring(1);
  if (value.startsWith('0X')) value = value.substring(2);
  if (value.length == 6) value = 'FF$value';
  if (value.length != 8) return null;
  final intValue = int.tryParse(value, radix: 16);
  if (intValue == null) return null;
  return Color(intValue);
}

String colorToHexString(Color color) {
  final rgb = color.toARGB32() & 0x00FFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

ThemeData buildTheme(String mode, String presetId, {Color? customPrimary}) {
  AppTheme.apply(mode, presetId, customPrimary: customPrimary);
  final isDark = mode == 'dark';
  final brightness = isDark ? Brightness.dark : Brightness.light;

  final baseTextTheme = isDark
      ? ThemeData.dark().textTheme
      : ThemeData.light().textTheme;

  return ThemeData(
    brightness: brightness,
    scaffoldBackgroundColor: kBg,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: kAccent,
      secondary: kAccent2,
      surface: kSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: kText,
      error: kRed,
      onError: Colors.white,
    ),
    textTheme: GoogleFonts.interTextTheme(baseTextTheme).copyWith(
      displayLarge: GoogleFonts.inter(
        color: kText,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      displayMedium: GoogleFonts.inter(
        color: kText,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      displaySmall: GoogleFonts.inter(
        color: kText,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: kBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.inter(
        color: kText,
        fontSize: 19,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      iconTheme: IconThemeData(color: kText),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kSurface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusControl),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusControl),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusControl),
        borderSide: BorderSide(color: kAccent, width: 1.6),
      ),
      labelStyle: TextStyle(color: kText2),
      hintStyle: TextStyle(color: kText3),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kText,
        side: BorderSide(color: kSurface3),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    cardTheme: CardThemeData(
      color: kSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusCard),
        side: BorderSide(color: kSurface3.withValues(alpha: 0.6)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: kSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titleTextStyle: GoogleFonts.inter(color: kText, fontSize: 18, fontWeight: FontWeight.w600),
      contentTextStyle: GoogleFonts.inter(color: kText2, fontSize: 14, height: 1.45),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: kSurface2,
      contentTextStyle: TextStyle(color: kText),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerColor: kSurface3,
    useMaterial3: true,
  );
}
