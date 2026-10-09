// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme.dart';
import 'services/app_state.dart';
import 'models/models.dart';
import 'l10n/strings.dart';
import 'screens/today_screen.dart';
import 'screens/history_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/custom_color_dialog.dart';
import 'widgets/app_tour.dart';
import 'widgets/widgets.dart';

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
            systemNavigationBarColor: kBg,
            systemNavigationBarIconBrightness:
                state.prefs.themeMode == 'dark' ? Brightness.light : Brightness.dark,
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
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(color: kText3, strokeWidth: 1.6),
          ),
        ),
      );
}

// ─── SETUP WIZARD ───────────────────────────────────────────────────────────
// Tre domande, una per pagina: una domanda grande, le risposte in elenco.
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

  bool get _it => _lang == 'it';

  void _applySetupThemePreview() {
    final custom = _accent == 'custom' ? parseHexColor(_customAccentHex) : null;
    AppTheme.apply(_themeMode, _accent, customPrimary: custom);
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      _it ? 'Benvenuto.\nIn che lingua?' : 'Welcome.\nWhich language?',
      S.get('setup_date'),
      S.get('setup_theme'),
    ];

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(kGapPage, 28, kGapPage, 0),
              child: Text('GymTracker  ·  ${_page + 1}/3', style: T.label),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(kGapPage, 18, kGapPage, 28),
              child: Text(titles[_page], style: T.display),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: KeyedSubtree(
                  key: ValueKey(_page),
                  child: [
                    _buildLanguagePage,
                    _buildDateFormatPage,
                    _buildThemePage,
                  ][_page](),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(kGapPage, 8, kGapPage, 16),
              child: Row(
                children: [
                  if (_page > 0) ...[
                    TextButton(
                      onPressed: () => setState(() => _page--),
                      child: Text(_it ? 'Indietro' : 'Back',
                          style: TextStyle(color: kText2)),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _next,
                      child: Text(
                        _page < 2
                            ? (_it ? 'Avanti' : 'Next')
                            : (_it ? 'Inizia' : 'Start'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _option(String label, bool selected, VoidCallback onTap,
      {String? detail}) {
    return ListRow(
      title: label,
      subtitle: detail,
      trailing: selected
          ? Icon(Icons.check, color: kText, size: 22)
          : const SizedBox(width: 22),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
    );
  }

  Widget _buildLanguagePage() {
    return ListView(
      children: [
        const Divider(indent: kGapPage, endIndent: kGapPage),
        _option('Italiano', _lang == 'it', () => setState(() {
              _lang = 'it';
              S.setLang('it');
            })),
        _option('English', _lang == 'en', () => setState(() {
              _lang = 'en';
              S.setLang('en');
            })),
      ],
    );
  }

  Widget _buildDateFormatPage() {
    return ListView(
      children: [
        const Divider(indent: kGapPage, endIndent: kGapPage),
        _option(_it ? 'Giorno, mese' : 'Day, month', _dateFormat == 'dd-MM',
            () => setState(() => _dateFormat = 'dd-MM'),
            detail: '22-02'),
        _option(_it ? 'Mese, giorno' : 'Month, day', _dateFormat == 'MM-dd',
            () => setState(() => _dateFormat = 'MM-dd'),
            detail: '02-22'),
      ],
    );
  }

  Widget _buildThemePage() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: kGapPage),
      children: [
        SegmentedToggle(
          labels: [_it ? 'Scuro' : 'Dark', _it ? 'Chiaro' : 'Light'],
          selected: _themeMode == 'light' ? 1 : 0,
          onChanged: (i) => setState(() {
            _themeMode = i == 1 ? 'light' : 'dark';
            _applySetupThemePreview();
          }),
        ),
        const SizedBox(height: 28),
        Text(S.get('setup_accent'), style: T.label),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ...accentPresets.map((p) => AccentDot(
                  color: p.primary,
                  selected: _accent == p.id,
                  onTap: () => setState(() {
                    _accent = p.id;
                    _applySetupThemePreview();
                  }),
                )),
            AccentDot(
              color: parseHexColor(_customAccentHex) ?? kSurface3,
              selected: _accent == 'custom',
              icon: Icons.add,
              onTap: _pickCustomAccent,
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
      title: S.get('custom_color'),
      cancelText: S.get('cancel'),
      saveText: S.get('save'),
      invalidHexText: S.get('invalid_code'),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _accent = 'custom';
      _customAccentHex = colorToHexString(picked);
      _applySetupThemePreview();
    });
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
  static const todayTab = 0;
  static const historyTab = 1;
  static const progressTab = 2;
  static const settingsTab = 3;

  int _currentIndex = todayTab;

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
  //
  // Quattro schede, non piu' cinque: "Esercizi" e "Progressi" mostravano la
  // stessa lista. Ora la libreria vive dentro Progressi.
  List<Widget> get _pages => [
        ScaffoldMessenger(child: TodayScreen()),
        ScaffoldMessenger(child: HistoryScreen()),
        ScaffoldMessenger(child: ProgressScreen()),
        ScaffoldMessenger(child: SettingsScreen()),
      ];

  void selectTab(int index) {
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
    setState(() => _currentIndex = todayTab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppTour.start(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, _, __) => Scaffold(
        backgroundColor: kBg,
        body: Stack(
          children: [
            IndexedStack(index: _currentIndex, children: _pages),
            // Fascia sotto la status bar: scorrendo, le liste passavano sotto
            // orologio e icone di sistema senza alcuna separazione.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).padding.top,
              child: IgnorePointer(child: ColoredBox(color: kBg)),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          key: TourKeys.bottomNav,
          decoration: BoxDecoration(
            color: kBg,
            border: Border(top: BorderSide(color: kLine)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 58,
              child: Row(
                children: [
                  _navItem(todayTab, Icons.fitness_center, S.get('today')),
                  _navItem(historyTab, Icons.calendar_today_outlined,
                      S.get('history')),
                  _navItem(progressTab, Icons.show_chart, S.get('progress')),
                  _navItem(settingsTab, Icons.tune, S.get('settings')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Voce della barra: monocroma. Quella attiva e' a pieno contrasto, le
  /// altre spente; niente pillole colorate.
  Widget _navItem(int index, IconData icon, String label) {
    final selected = _currentIndex == index;
    final color = selected ? kText : kText3;
    return Expanded(
      child: InkResponse(
        onTap: () => selectTab(index),
        highlightShape: BoxShape.rectangle,
        containedInkWell: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
