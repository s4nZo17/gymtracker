// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';
import 'services/app_state.dart';
import 'models/models.dart';
import 'l10n/strings.dart';
import 'screens/today_screen.dart';
import 'screens/history_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/library_screen.dart';
import 'widgets/custom_color_dialog.dart';
import 'widgets/app_tour.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('it_IT', null);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: const GymTrackerApp(),
    ),
  );
}

class GymTrackerApp extends StatelessWidget {
  const GymTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                state.prefs.themeMode == 'dark' ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: kSurface,
          ),
        );

        return MaterialApp(
          title: 'GymTracker 2.0',
          theme: buildTheme(
            state.prefs.themeMode,
            state.prefs.accentPreset,
            customPrimary: state.customAccentColor,
          ),
          debugShowCheckedModeBanner: false,
          home: state.isLoading
              ? const _SplashScreen()
              : state.needsSetup
                  ? const SetupWizard()
                  : const MainShell(),
        );
      },
    );
  }
}

// ─── SPLASH ─────────────────────────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kBg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fitness_center, color: kAccent, size: 40),
              const SizedBox(height: 14),
              Text(
                'GYMLOG',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: kAccent,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: kAccent, strokeWidth: 2),
              ),
            ],
          ),
        ),
      );
}

// ─── SETUP WIZARD ───────────────────────────────────────────────────────────
class SetupWizard extends StatefulWidget {
  const SetupWizard({super.key});

  @override
  State<SetupWizard> createState() => _SetupWizardState();
}

class _SetupWizardState extends State<SetupWizard> {
  int _page = 0;
  String _lang = 'it';
  String _dateFormat = 'dd-MM';
  String _themeMode = 'dark';
  String _accent = 'obsidian';
  String _customAccentHex = '';

  void _applySetupThemePreview() {
    final custom = _accent == 'custom' ? parseHexColor(_customAccentHex) : null;
    AppTheme.apply(_themeMode, _accent, customPrimary: custom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Icon(Icons.fitness_center, color: kAccent, size: 34),
              const SizedBox(height: 10),
              Text(
                'GYMLOG',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: kAccent,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _page == 0 ? (_lang == 'it' ? 'Benvenuto!' : 'Welcome!') : '',
                style: TextStyle(fontSize: 17, color: kText2),
              ),
              const SizedBox(height: 36),
              if (_page == 0) _buildLanguagePage(),
              if (_page == 1) _buildDateFormatPage(),
              if (_page == 2) _buildThemePage(),
              const Spacer(flex: 2),
              Row(
                children: [
                  if (_page > 0)
                    TextButton(
                      onPressed: () => setState(() => _page--),
                      child: Text(
                        _lang == 'it' ? 'Indietro' : 'Back',
                        style: TextStyle(color: kText2),
                      ),
                    ),
                  const Spacer(),
                  SizedBox(
                    width: 150,
                    child: ElevatedButton(
                      onPressed: _next,
                      child: Text(
                        _page < 2
                            ? (_lang == 'it' ? 'Avanti' : 'Next')
                            : (_lang == 'it' ? 'Inizia!' : 'Start!'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page ? kAccent : kSurface3,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguagePage() {
    return Column(
      children: [
        Text(
          _lang == 'it' ? 'In che lingua preferisci?' : 'Preferred language?',
          style: TextStyle(fontSize: 16, color: kText),
        ),
        const SizedBox(height: 20),
        _optionCard('🇮🇹', 'Italiano', _lang == 'it', () => setState(() {
              _lang = 'it';
              S.setLang('it');
            })),
        const SizedBox(height: 10),
        _optionCard('🇬🇧', 'English', _lang == 'en', () => setState(() {
              _lang = 'en';
              S.setLang('en');
            })),
      ],
    );
  }

  Widget _buildDateFormatPage() {
    return Column(
      children: [
        Text(S.get('setup_date'), style: TextStyle(fontSize: 16, color: kText)),
        const SizedBox(height: 20),
        _optionCard('📅', 'GG-MM (22-02)', _dateFormat == 'dd-MM',
            () => setState(() => _dateFormat = 'dd-MM')),
        const SizedBox(height: 10),
        _optionCard('📅', 'MM-GG (02-22)', _dateFormat == 'MM-dd',
            () => setState(() => _dateFormat = 'MM-dd')),
      ],
    );
  }

  Widget _buildThemePage() {
    return Column(
      children: [
        Text(S.get('setup_theme'), style: TextStyle(fontSize: 16, color: kText)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _themeToggle(
                    'dark', _lang == 'it' ? 'Scuro' : 'Dark', Icons.dark_mode)),
            const SizedBox(width: 10),
            Expanded(
                child: _themeToggle(
                    'light', _lang == 'it' ? 'Chiaro' : 'Light', Icons.light_mode)),
          ],
        ),
        const SizedBox(height: 20),
        Text(S.get('setup_accent'), style: TextStyle(fontSize: 14, color: kText2)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ...accentPresets.map((p) => GestureDetector(
                  onTap: () => setState(() {
                    _accent = p.id;
                    _applySetupThemePreview();
                  }),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: p.primary,
                      borderRadius: BorderRadius.circular(16),
                      border: _accent == p.id
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: _accent == p.id
                          ? [
                              BoxShadow(
                                  color: p.primary.withValues(alpha: 0.4),
                                  blurRadius: 12)
                            ]
                          : null,
                    ),
                    child: _accent == p.id
                        ? const Icon(Icons.check, color: Colors.white, size: 26)
                        : null,
                  ),
                )),
            GestureDetector(
              onTap: _pickCustomAccent,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: parseHexColor(_customAccentHex) ?? kAccent,
                  borderRadius: BorderRadius.circular(16),
                  border: _accent == 'custom'
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                ),
                child: _accent == 'custom'
                    ? const Icon(Icons.check, color: Colors.white, size: 26)
                    : const Icon(Icons.color_lens_outlined,
                        color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickCustomAccent() async {
    final picked = await showCustomColorDialog(
      context: context,
      initialColor: parseHexColor(_customAccentHex) ?? kAccent,
      title: S.lang == 'it' ? 'Colore personalizzato' : 'Custom color',
      cancelText: S.get('cancel'),
      saveText: S.lang == 'it' ? 'Salva' : 'Save',
      invalidHexText: S.lang == 'it' ? 'Codice non valido' : 'Invalid code',
    );

    if (picked == null || !mounted) return;

    setState(() {
      _accent = 'custom';
      _customAccentHex = colorToHexString(picked);
      _applySetupThemePreview();
    });
  }

  Widget _themeToggle(String mode, String label, IconData icon) {
    final selected = _themeMode == mode;
    return GestureDetector(
      onTap: () => setState(() {
        _themeMode = mode;
        _applySetupThemePreview();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? kAccent.withValues(alpha: 0.14) : kSurface,
          border: Border.all(color: selected ? kAccent : kSurface3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? kAccent : kText3, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    color: selected ? kAccent : kText2,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _optionCard(String emoji, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: selected ? kAccent.withValues(alpha: 0.10) : kSurface,
          border: Border.all(color: selected ? kAccent : kSurface3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(
                  fontSize: 16,
                  color: selected ? kAccent : kText,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                )),
            const Spacer(),
            if (selected) Icon(Icons.check_circle, color: kAccent, size: 22),
          ],
        ),
      ),
    );
  }

  void _next() {
    if (_page < 2) {
      setState(() => _page++);
    } else {
      final state = context.read<AppState>();
      state.updatePreferences(AppPreferences(
        language: _lang,
        themeMode: _themeMode,
        accentPreset: _accent,
        customAccentHex: _customAccentHex,
        dateFormat: _dateFormat,
        setupCompleted: true,
      ));
    }
  }
}

// ─── MAIN SHELL ─────────────────────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  /// Attenzione: qui NON si usa `const`. Le istanze const vengono
  /// canonicalizzate e Flutter salta il rebuild del sottoalbero: cambiando
  /// tema a caldo alcune schermate restavano con i colori vecchi (succedeva a
  /// Progressi → Mappa corpo). Ricreandole a ogni build il tema si applica
  /// ovunque immediatamente.
  // ignore_for_file: prefer_const_constructors
  //
  // Ogni scheda ha il suo ScaffoldMessenger: senza, la snackbar veniva
  // agganciata allo Scaffold esterno (quello della barra di navigazione) e
  // finiva SOPRA il pulsante flottante, che quindi non si spostava. Risultato:
  // "Annulla" e "+ Esercizio" nello stesso punto, e se la snackbar spariva un
  // attimo prima del tocco si apriva il selettore esercizi invece di annullare.
  // Attaccandola allo Scaffold della singola scheda, Flutter alza il FAB da solo.
  List<Widget> get _pages => [
        ScaffoldMessenger(child: TodayScreen()),
        ScaffoldMessenger(child: LibraryScreen()),
        ScaffoldMessenger(child: HistoryScreen()),
        ScaffoldMessenger(child: ProgressScreen()),
        ScaffoldMessenger(child: SettingsScreen()),
      ];

  void _select(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  @override
  void initState() {
    super.initState();
    // Tour interattivo al primo avvio (dopo il setup).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      if (!state.prefs.tourCompleted && !AppTour.isActive) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          AppTour.start(
            context,
            onDone: () => context.read<AppState>().setTourCompleted(),
          );
        });
      }
    });
  }

  /// Riavvia il tour (usato da Impostazioni → "Rivedi il tour").
  void startTour() {
    setState(() => _currentIndex = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppTour.start(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, _, __) => Scaffold(
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: Container(
          key: TourKeys.bottomNav,
          decoration: BoxDecoration(
            color: kSurface,
            border: Border(top: BorderSide(color: kSurface3.withValues(alpha: 0.6))),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 62,
              child: Row(
                children: [
                  _navItem(0, Icons.fitness_center_outlined, Icons.fitness_center,
                      S.get('today')),
                  _navItem(1, Icons.menu_book_outlined, Icons.menu_book,
                      S.get('exercises')),
                  _navItem(
                      2, Icons.history_outlined, Icons.history, S.get('history')),
                  _navItem(3, Icons.trending_up_outlined, Icons.trending_up,
                      S.get('progress')),
                  _navItem(4, Icons.settings_outlined, Icons.settings,
                      S.get('settings')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final selected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _select(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
              decoration: BoxDecoration(
                color: selected
                    ? kAccent.withValues(alpha: 0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                selected ? activeIcon : icon,
                color: selected ? kAccent : kText3,
                size: 23,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: selected ? kAccent : kText3,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
