// lib/theme.dart
//
// Design system di GymTracker 2.0 — versione minimal.
//
// Regole:
//  - Monocromo. L'accento serve per UNA cosa per schermata (l'azione
//    principale) e per i dati da evidenziare; tutto il resto e' testo.
//  - Niente card bordate in lista: righe piatte separate da una linea sottile.
//  - La gerarchia la fanno dimensione e peso del testo, non i riquadri.

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
Color kBg = const Color(0xFF0C0C0D);

/// Fondo di sheet, dialog e barra di navigazione.
Color kSurface = const Color(0xFF151517);

/// Fondo di campi di testo, stepper e segmenti.
Color kSurface2 = const Color(0xFF1C1C1F);

/// Elementi spenti: corpo non allenato, cursori, bordi forti.
Color kSurface3 = const Color(0xFF2A2A2E);

/// Linea sottile fra le righe di una lista.
Color kLine = const Color(0xFF202023);
Color kText = const Color(0xFFF4F4F5);
Color kText2 = const Color(0xFFA1A1AA);
Color kText3 = const Color(0xFF7A7A83);
const kRed = Color(0xFFEF4444);
const kBlue = Color(0xFF60A5FA);
const kOrange = Color(0xFFFB923C);
const kGreen = Color(0xFF4ADE80);

// Raggi: piu' piccoli e uguali ovunque.
const kRadiusCard = 14.0;
const kRadiusControl = 10.0;
const kRadiusSheet = 22.0;
const kRadiusPill = 999.0;

// Spaziature standard: usare queste invece di numeri sparsi.
const kGapPage = 20.0; // margine laterale di pagina
const kGapCard = 12.0; // distanza fra due blocchi
const kGapItem = 8.0; // distanza fra elementi dentro un blocco
/// Spazio libero in fondo alle liste, per non finire sotto FAB e navbar.
const kBottomSafeSpace = 104.0;

/// Cifre a larghezza fissa: pesi e reps restano incolonnati.
const kTabular = [FontFeature.tabularFigures()];

class AppTheme {
  static void apply(String mode, String presetId, {Color? customPrimary}) {
    final useCustom = presetId == 'custom' && customPrimary != null;
    final preset = getPreset(useCustom ? 'obsidian' : presetId);
    kAccent = useCustom ? customPrimary : preset.primary;
    kAccent2 = useCustom ? _deriveSecondary(kAccent) : preset.secondary;

    if (mode == 'dark') {
      kBg = const Color(0xFF0C0C0D);
      kSurface = const Color(0xFF151517);
      kSurface2 = const Color(0xFF1C1C1F);
      kSurface3 = const Color(0xFF2A2A2E);
      kLine = const Color(0xFF202023);
      kText = const Color(0xFFF4F4F5);
      kText2 = const Color(0xFFA1A1AA);
      // Sopra 4.5:1 sul fondo: date e conteggi devono restare leggibili.
      kText3 = const Color(0xFF7A7A83);
    } else {
      kBg = const Color(0xFFFFFFFF);
      kSurface = const Color(0xFFFFFFFF);
      kSurface2 = const Color(0xFFF2F2F4);
      kSurface3 = const Color(0xFFE0E0E5);
      kLine = const Color(0xFFEDEDF0);
      kText = const Color(0xFF111113);
      kText2 = const Color(0xFF5B5B64);
      kText3 = const Color(0xFF777780);
    }
  }
}

// ─── TIPOGRAFIA ─────────────────────────────────────────────────────────────
// Pochi stili, sempre gli stessi. Getter e non costanti: i colori cambiano
// col tema.
class T {
  /// Titolo di pagina ("Oggi", "Storico").
  static TextStyle get display => GoogleFonts.inter(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.9,
        height: 1.15,
        color: kText,
      );

  /// Titolo di sheet e di blocco ("Panca piana").
  static TextStyle get title => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: kText,
      );

  /// Testo di una riga di lista.
  static TextStyle get body => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.1,
        color: kText,
      );

  /// Informazione secondaria sotto un titolo.
  static TextStyle get meta => GoogleFonts.inter(
        fontSize: 13,
        color: kText2,
        letterSpacing: -0.05,
      );

  /// Etichetta di sezione e testo di contorno.
  static TextStyle get label => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: kText3,
      );

  /// Numero grande (pesi, statistiche).
  static TextStyle get number => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.8,
        color: kText,
        fontFeatures: kTabular,
      );
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
    splashFactory: InkRipple.splashFactory,
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
    textTheme: GoogleFonts.interTextTheme(baseTextTheme).apply(
      bodyColor: kText,
      displayColor: kText,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: kBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 4,
      titleTextStyle: GoogleFonts.inter(
        color: kText,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: kText, size: 22),
      actionsIconTheme: IconThemeData(color: kText2, size: 22),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kSurface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        borderSide: BorderSide(color: kText3, width: 1),
      ),
      labelStyle: TextStyle(color: kText3),
      floatingLabelStyle: TextStyle(color: kText2),
      hintStyle: TextStyle(color: kText3),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kAccent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: kSurface2,
        disabledForegroundColor: kText3,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusControl + 2)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kText,
        side: BorderSide(color: kSurface3),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusControl + 2)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kText,
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    cardTheme: CardThemeData(
      color: kSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusCard),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: kSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSheet)),
      titleTextStyle: GoogleFonts.inter(
          color: kText, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.3),
      contentTextStyle: GoogleFonts.inter(color: kText2, fontSize: 14, height: 1.45),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    // Snackbar invertita: si stacca dal fondo senza bisogno di colore.
    snackBarTheme: SnackBarThemeData(
      backgroundColor: kText,
      contentTextStyle: GoogleFonts.inter(color: kBg, fontSize: 14),
      actionTextColor: kAccent,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusControl + 2)),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: kText,
      inactiveTrackColor: kSurface3,
      thumbColor: kText,
      overlayColor: kText.withValues(alpha: 0.08),
      trackHeight: 3,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: kText2),
    dividerTheme: DividerThemeData(color: kLine, thickness: 1, space: 1),
    dividerColor: kLine,
    listTileTheme: ListTileThemeData(
      iconColor: kText2,
      textColor: kText,
      contentPadding: const EdgeInsets.symmetric(horizontal: kGapPage),
    ),
    useMaterial3: true,
  );
}

/// true col tema scuro attivo (letto dai colori correnti).
bool get isDarkTheme => kBg.computeLuminance() < 0.5;
