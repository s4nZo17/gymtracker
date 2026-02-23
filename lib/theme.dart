// lib/theme.dart

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
// These are the "current" colors, updated by AppTheme.apply()
Color kAccent = const Color(0xFF8B5CF6);
Color kAccent2 = const Color(0xFF6366F1);
Color kBg = const Color(0xFF09090B);
Color kSurface = const Color(0xFF111113);
Color kSurface2 = const Color(0xFF18181B);
Color kSurface3 = const Color(0xFF27272A);
Color kText = const Color(0xFFF4F4F5);
Color kText2 = const Color(0xFFA1A1AA);
Color kText3 = const Color(0xFF52525B);
const kRed = Color(0xFFEF4444);
const kBlue = Color(0xFF60A5FA);
const kOrange = Color(0xFFFB923C);
const kGreen = Color(0xFF4ADE80);

class AppTheme {
  static void apply(String mode, String presetId, {Color? customPrimary}) {
    final useCustom = presetId == 'custom' && customPrimary != null;
    final preset = getPreset(useCustom ? 'obsidian' : presetId);
    kAccent = useCustom ? customPrimary : preset.primary;
    kAccent2 = useCustom ? _deriveSecondary(kAccent) : preset.secondary;

    if (mode == 'dark') {
      kBg = const Color(0xFF09090B);
      kSurface = const Color(0xFF111113);
      kSurface2 = const Color(0xFF18181B);
      kSurface3 = const Color(0xFF27272A);
      kText = const Color(0xFFF4F4F5);
      kText2 = const Color(0xFFA1A1AA);
      kText3 = const Color(0xFF52525B);
    } else {
      kBg = const Color(0xFFF8F8FA);
      kSurface = const Color(0xFFFFFFFF);
      kSurface2 = const Color(0xFFF0F0F3);
      kSurface3 = const Color(0xFFD4D4D8);
      kText = const Color(0xFF18181B);
      kText2 = const Color(0xFF52525B);
      kText3 = const Color(0xFFA1A1AA);
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
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
      ),
      displayMedium: GoogleFonts.inter(
        color: kText,
        fontSize: 24,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
      displaySmall: GoogleFonts.inter(
        color: kText,
        fontSize: 20,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: kBg,
      elevation: 0,
      titleTextStyle: GoogleFonts.inter(
        color: kText,
        fontSize: 18,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      iconTheme: IconThemeData(color: kText),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: kSurface,
      selectedItemColor: kAccent,
      unselectedItemColor: kText3,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kSurface2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: kSurface3),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: kSurface3),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: kAccent, width: 1.5),
      ),
      labelStyle: TextStyle(color: kText2),
      hintStyle: TextStyle(color: kText3),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kAccent,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
      ),
    ),
    cardTheme: CardThemeData(
      color: kSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: kSurface3),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: kSurface,
      titleTextStyle: TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.w500),
      contentTextStyle: TextStyle(color: kText2, fontSize: 14),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: kSurface2,
      contentTextStyle: TextStyle(color: kText),
    ),
    dividerColor: kSurface3,
    useMaterial3: true,
  );
}
