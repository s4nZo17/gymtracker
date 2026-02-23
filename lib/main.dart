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
        // Update system nav bar color to match theme
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: state.prefs.themeMode == 'dark' ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: kSurface,
          ),
        );

        return MaterialApp(
          title: 'GymTracker',
          theme: buildTheme(
            state.prefs.themeMode,
            state.prefs.accentPreset,
            customPrimary: state.customAccentColor,
          ),
          debugShowCheckedModeBanner: false,
          home: state.isLoading
              ? _SplashScreen()
              : state.needsSetup
                  ? const SetupWizard()
                  : const MainShell(),
        );
      },
    );
  }
}

// â”€â”€â”€ SPLASH â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kBg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'GYMLOG',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: kAccent,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(
                  color: kAccent, strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
      );
}

// â”€â”€â”€ SETUP WIZARD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
              // Logo
              Text(
                'GYMLOG',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  color: kAccent,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _page == 0 ? (_lang == 'it' ? 'Benvenuto!' : 'Welcome!') : '',
                style: TextStyle(fontSize: 18, color: kText2),
              ),
              const SizedBox(height: 40),

              // Content
              if (_page == 0) _buildLanguagePage(),
              if (_page == 1) _buildDateFormatPage(),
              if (_page == 2) _buildThemePage(),

              const Spacer(flex: 2),

              // Navigation
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
                  ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(140, 52),
                    ),
                    child: Text(
                      _page < 2
                          ? (_lang == 'it' ? 'Avanti' : 'Next')
                          : (_lang == 'it' ? 'Inizia!' : 'Start!'),
                    ),
                  ),
                ],
              ),

              // Page indicator
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _page ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _page ? kAccent : kSurface3,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
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
        _optionCard(
          'IT',
          'Italiano',
          _lang == 'it',
          () => setState(() {
            _lang = 'it';
            S.setLang('it');
          }),
        ),
        const SizedBox(height: 10),
        _optionCard(
          'EN',
          'English',
          _lang == 'en',
          () => setState(() {
            _lang = 'en';
            S.setLang('en');
          }),
        ),
      ],
    );
  }

  Widget _buildDateFormatPage() {
    return Column(
      children: [
        Text(
          S.get('setup_date'),
          style: TextStyle(fontSize: 16, color: kText),
        ),
        const SizedBox(height: 20),
        _optionCard(
          'DT',
          'GG-MM (22-02)',
          _dateFormat == 'dd-MM',
          () => setState(() => _dateFormat = 'dd-MM'),
        ),
        const SizedBox(height: 10),
        _optionCard(
          'DT',
          'MM-GG (02-22)',
          _dateFormat == 'MM-dd',
          () => setState(() => _dateFormat = 'MM-dd'),
        ),
      ],
    );
  }

  Widget _buildThemePage() {
    return Column(
      children: [
        Text(
          S.get('setup_theme'),
          style: TextStyle(fontSize: 16, color: kText),
        ),
        const SizedBox(height: 16),
        // Light / Dark toggle
        Row(
          children: [
            Expanded(child: _themeToggle('dark', _lang == 'it' ? 'Scuro' : 'Dark', Icons.dark_mode)),
            const SizedBox(width: 10),
            Expanded(child: _themeToggle('light', _lang == 'it' ? 'Chiaro' : 'Light', Icons.light_mode)),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          S.get('setup_accent'),
          style: TextStyle(fontSize: 14, color: kText2),
        ),
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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: p.primary,
                  borderRadius: BorderRadius.circular(16),
                  border: _accent == p.id
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                  boxShadow: _accent == p.id
                      ? [BoxShadow(color: p.primary.withValues(alpha: 0.4), blurRadius: 12)]
                      : null,
                ),
                child: _accent == p.id
                    ? const Icon(Icons.check, color: Colors.white, size: 28)
                    : null,
              ),
            )),
            GestureDetector(
              onTap: _pickCustomAccent,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: parseHexColor(_customAccentHex) ?? kAccent,
                  borderRadius: BorderRadius.circular(16),
                  border: _accent == 'custom'
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                  boxShadow: _accent == 'custom'
                      ? [BoxShadow(color: (parseHexColor(_customAccentHex) ?? kAccent).withValues(alpha: 0.4), blurRadius: 12)]
                      : null,
                ),
                child: _accent == 'custom'
                    ? const Icon(Icons.check, color: Colors.white, size: 28)
                    : const Icon(Icons.color_lens_outlined, color: Colors.white, size: 22),
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? kAccent.withValues(alpha: 0.15) : kSurface,
          border: Border.all(color: selected ? kAccent : kSurface3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? kAccent : kText3, size: 28),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: selected ? kAccent : kText2, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _optionCard(String emoji, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: selected ? kAccent.withValues(alpha: 0.1) : kSurface,
          border: Border.all(color: selected ? kAccent : kSurface3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(
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
      // Apply and save all settings
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

// â”€â”€â”€ MAIN SHELL â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _pages = const [
    TodayScreen(),
    LibraryScreen(),
    HistoryScreen(),
    ProgressScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, _, __) => Scaffold(
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: kSurface,
            border: Border(top: BorderSide(color: kSurface3)),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: kAccent,
            unselectedItemColor: kText3,
            selectedFontSize: 10,
            unselectedFontSize: 10,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.fitness_center_outlined),
                activeIcon: const Icon(Icons.fitness_center),
                label: S.get('today'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.menu_book_outlined),
                activeIcon: const Icon(Icons.menu_book),
                label: S.get('exercises'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.history_outlined),
                activeIcon: const Icon(Icons.history),
                label: S.get('history'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.trending_up_outlined),
                activeIcon: const Icon(Icons.trending_up),
                label: S.get('progress'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.settings_outlined),
                activeIcon: const Icon(Icons.settings),
                label: S.get('settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

