// lib/theme.dart
//
// Design system di GymTracker 2.0 — versione "Lista" (redesign A).
//
// Regole:
//  - Fondo quasi nero, contenuti raggruppati in blocchi grigi (kSurface) con
//    righe separate da una linea rientrata. Niente ombre, niente gradienti.
//  - L'accento colora solo cio' che si tocca per AGIRE (nomi dei giorni,
//    "+ Aggiungi serie", "Finisci") e i bottoni pieni. Il resto e' grigio.
//  - Etichette di sezione in maiuscolo, piccole e spaziate.
//  - Un solo raggio: 6, ovunque. Font: Roboto (quello di sistema).

import 'package:flutter/material.dart';

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

/// Accento per testi e icone sul fondo: piu' chiaro dell'accento pieno, che
/// sul nero si legge poco. Il pieno resta per i bottoni.
Color kAccentText = const Color(0xFFA78BFA);
Color kBg = const Color(0xFF0A0A0B);

/// Fondo dei blocchi, di sheet e dialog.
Color kSurface = const Color(0xFF141416);

/// Fondo di campi e riquadri dentro un blocco o uno sheet.
Color kSurface2 = const Color(0xFF1C1C1F);

/// Elementi selezionati (segmento, filtro) ed elementi spenti.
Color kSurface3 = const Color(0xFF26262B);

/// Linea sottile fra le righe di un blocco.
Color kLine = const Color(0xFF232327);

/// Bordo sopra la barra di navigazione.
Color kNavBorder = const Color(0xFF1C1C1F);

/// Bordo tratteggiato ("Aggiungi un esercizio") e contorni dei selezionati.
Color kDashed = const Color(0xFF34343A);
Color kText = const Color(0xFFF5F5F6);

/// Testo chiaro ma non bianco pieno (bottoni secondari).
Color kTextSoft = const Color(0xFFC9C9CE);

/// Sottotitoli, etichette, tab non attive.
Color kText2 = const Color(0xFF8A8A90);

/// Conteggi, frecce, segnaposto: un gradino sotto kText2.
Color kText3 = const Color(0xFF6E6E76);

/// Il grigio piu' spento ("oppure", "Da fare").
Color kTextFaint = const Color(0xFF5C5C63);
const kRed = Color(0xFFEF4444);
const kBlue = Color(0xFF60A5FA);
const kOrange = Color(0xFFFB923C);
const kGreen = Color(0xFF4ADE80);

// Un solo raggio per tutto. I tre nomi restano per leggibilita' nel codice.
const kRadius = 6.0;
const kRadiusCard = kRadius;
const kRadiusControl = kRadius;
const kRadiusSheet = kRadius;

// Spaziature standard: usare queste invece di numeri sparsi.
const kGapPage = 24.0; // margine laterale di pagina
const kGapCard = 12.0; // distanza fra due blocchi
const kGapItem = 8.0; // distanza fra elementi dentro un blocco

/// Rientro del testo dentro un blocco (e quindi delle linee fra le righe).
const kBlockInset = 18.0;

/// Spazio libero in fondo alle liste, per non finire sotto la navbar.
const kBottomSafeSpace = 40.0;

/// Cifre a larghezza fissa: pesi e reps restano incolonnati.
const kTabular = [FontFeature.tabularFigures()];

class AppTheme {
  static void apply(String mode, String presetId, {Color? customPrimary}) {
    final useCustom = presetId == 'custom' && customPrimary != null;
    final preset = getPreset(useCustom ? 'obsidian' : presetId);
    kAccent = useCustom ? customPrimary : preset.primary;
    kAccent2 = useCustom ? _deriveSecondary(kAccent) : preset.secondary;

    if (mode == 'dark') {
      kAccentText = Color.lerp(kAccent, Colors.white, 0.3)!;
      kBg = const Color(0xFF0A0A0B);
      kSurface = const Color(0xFF141416);
      kSurface2 = const Color(0xFF1C1C1F);
      kSurface3 = const Color(0xFF26262B);
      kLine = const Color(0xFF232327);
      kNavBorder = const Color(0xFF1C1C1F);
      kDashed = const Color(0xFF34343A);
      kText = const Color(0xFFF5F5F6);
      kTextSoft = const Color(0xFFC9C9CE);
      kText2 = const Color(0xFF8A8A90);
      kText3 = const Color(0xFF6E6E76);
      kTextFaint = const Color(0xFF5C5C63);
    } else {
      // Tema chiaro: per ora gli stessi valori di prima, piu' quelli nuovi.
      kAccentText = Color.lerp(kAccent, Colors.black, 0.1)!;
      kBg = const Color(0xFFFFFFFF);
      kSurface = const Color(0xFFFFFFFF);
      kSurface2 = const Color(0xFFF2F2F4);
      kSurface3 = const Color(0xFFE0E0E5);
      kLine = const Color(0xFFEDEDF0);
      kNavBorder = const Color(0xFFEDEDF0);
      kDashed = const Color(0xFFCFCFD6);
      kText = const Color(0xFF111113);
      kTextSoft = const Color(0xFF3A3A40);
      kText2 = const Color(0xFF5B5B64);
      kText3 = const Color(0xFF777780);
      kTextFaint = const Color(0xFF9A9AA2);
    }
  }
}

// ─── TIPOGRAFIA ─────────────────────────────────────────────────────────────
// Pochi stili, sempre gli stessi. Getter e non costanti: i colori cambiano
// col tema. Nessuna famiglia esplicita: e' il Roboto del tema.
class T {
  /// Titolo di pagina ("Venerdi'", "Storico").
  static TextStyle get display => TextStyle(
        fontSize: 42,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.26,
        height: 1.0,
        color: kText,
      );

  /// Testo a destra del titolo di pagina ("23 ottobre", "104 allenamenti").
  static TextStyle get displayMeta => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: kAccentText,
      );

  /// Etichetta di sezione ("GIORNI PREIMPOSTATI"): il testo va in maiuscolo.
  static TextStyle get section => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: kText2,
      );

  /// Titolo di una riga o di un blocco ("Panca piana", "Push Day").
  static TextStyle get title => TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: kText,
      );

  /// Testo di una riga semplice (impostazioni, opzioni).
  static TextStyle get body => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: kText,
      );

  /// Informazione secondaria sotto un titolo.
  static TextStyle get meta => TextStyle(
        fontSize: 14,
        color: kText2,
      );

  /// Testo di contorno piccolo.
  static TextStyle get label => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: kText2,
      );

  /// Numero grande (pesi, statistiche).
  static TextStyle get number => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
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
  final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kRadius));

  return ThemeData(
    brightness: brightness,
    fontFamily: 'Roboto',
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
    textTheme: baseTextTheme.apply(
      fontFamily: 'Roboto',
      bodyColor: kText,
      displayColor: kText,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: kBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 4,
      titleTextStyle: TextStyle(
        color: kText,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: kText, size: 24),
      actionsIconTheme: IconThemeData(color: kText2, size: 24),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kSurface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadius),
        borderSide: BorderSide(color: kDashed, width: 1),
      ),
      labelStyle: TextStyle(color: kText3),
      floatingLabelStyle: TextStyle(color: kText2),
      hintStyle: TextStyle(color: kText2),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kAccent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: kSurface2,
        disabledForegroundColor: kText3,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: shape,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kText,
        side: BorderSide(color: kDashed),
        minimumSize: const Size(0, 48),
        shape: shape,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kText,
        shape: shape,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    cardTheme: CardThemeData(
      color: kSurface,
      elevation: 0,
      shape: shape,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: kSurface,
      surfaceTintColor: Colors.transparent,
      shape: shape,
      titleTextStyle: TextStyle(
          color: kText, fontSize: 19, fontWeight: FontWeight.w700),
      contentTextStyle: TextStyle(color: kText2, fontSize: 15, height: 1.45),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: kSurface,
      surfaceTintColor: Colors.transparent,
      shape: shape,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    // Snackbar invertita: si stacca dal fondo senza bisogno di colore.
    snackBarTheme: SnackBarThemeData(
      backgroundColor: kText,
      contentTextStyle: TextStyle(color: kBg, fontSize: 14),
      actionTextColor: kAccent,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: shape,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: kText,
      inactiveTrackColor: kSurface3,
      thumbColor: kText,
      overlayColor: kText.withValues(alpha: 0.08),
      trackHeight: 3,
      thumbShape: const BarThumbShape(),
      overlayShape: SliderComponentShape.noOverlay,
      tickMarkShape: SliderTickMarkShape.noTickMark,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: kText2),
    dividerTheme: DividerThemeData(color: kLine, thickness: 1, space: 1),
    dividerColor: kLine,
    listTileTheme: ListTileThemeData(
      iconColor: kText2,
      textColor: kText,
      contentPadding: const EdgeInsets.symmetric(horizontal: kGapPage),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: kText,
        borderRadius: BorderRadius.circular(kRadius),
      ),
      textStyle: TextStyle(color: kBg, fontSize: 13),
    ),
    useMaterial3: true,
  );
}

/// true col tema scuro attivo (letto dai colori correnti).
bool get isDarkTheme => kBg.computeLuminance() < 0.5;

/// Cursore degli slider: una barretta verticale arrotondata invece del
/// pallino, come il resto dell'app (niente cerchi).
class BarThumbShape extends SliderComponentShape {
  const BarThumbShape({this.width = 8, this.height = 26});

  final double width;
  final double height;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      Size(width, height);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final rect = Rect.fromCenter(center: center, width: width, height: height);
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()..color = sliderTheme.thumbColor ?? kText,
    );
  }
}
