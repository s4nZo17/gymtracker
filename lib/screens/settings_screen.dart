// lib/screens/settings_screen.dart
//
// Impostazioni: un elenco di righe raggruppate (Aspetto, Allenamento, Dati),
// senza card e senza icone decorative. Ogni riga dice cosa fa; il valore
// corrente sta a destra.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../main.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/custom_color_dialog.dart';
import '../widgets/widgets.dart';
import 'import_screen.dart';
import 'templates_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final workouts =
            state.workouts.where((w) => w.exercises.isNotEmpty).length;
        final series = state.workouts.fold(0, (acc, w) => acc + w.totalSeries);

        return Scaffold(
          backgroundColor: kBg,
          body: ListView(
            padding: const EdgeInsets.only(bottom: kBottomSafeSpace),
            children: [
              PageHeader(title: S.get('settings')),

              // ─── Aspetto ───────────────────────────────────────────────
              SectionTitle(S.get('appearance')),
              _toggleRow(
                S.get('language'),
                SegmentedToggle(
                  compact: true,
                  labels: const ['IT', 'EN'],
                  selected: state.prefs.language == 'en' ? 1 : 0,
                  onChanged: (i) => state.setLanguage(i == 1 ? 'en' : 'it'),
                ),
              ),
              _toggleRow(
                S.get('theme'),
                SegmentedToggle(
                  compact: true,
                  labels: [S.get('dark'), S.get('light')],
                  selected: state.prefs.themeMode == 'light' ? 1 : 0,
                  onChanged: (i) =>
                      state.setThemeMode(i == 1 ? 'light' : 'dark'),
                ),
              ),
              _toggleRow(
                S.get('date_format'),
                SegmentedToggle(
                  compact: true,
                  labels: const ['GG-MM', 'MM-GG'],
                  selected: state.prefs.dateFormat == 'MM-dd' ? 1 : 0,
                  onChanged: (i) =>
                      state.setDateFormat(i == 1 ? 'MM-dd' : 'dd-MM'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(kGapPage, 14, kGapPage, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(S.get('accent_color'), style: T.body),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ...accentPresets.map((p) => AccentDot(
                              color: p.primary,
                              selected: state.prefs.accentPreset == p.id,
                              tooltip: S.lang == 'it' ? p.nameIt : p.nameEn,
                              onTap: () => state.setAccentPreset(p.id),
                            )),
                        AccentDot(
                          color: state.customAccentColor ?? kSurface3,
                          selected: state.prefs.accentPreset == 'custom',
                          tooltip: S.get('custom_color'),
                          icon: Icons.add,
                          onTap: () => _openCustomColorDialog(context, state),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(indent: kGapPage, endIndent: kGapPage),

              // ─── Allenamento ──────────────────────────────────────────
              SectionTitle(S.get('training')),
              ListRow(
                title: S.get('templates'),
                subtitle: state.templates.isEmpty
                    ? S.get('templates_desc')
                    : '${state.templates.length} · ${state.templates.map((t) => t.name).join(', ')}',
                trailing: RowChevron(),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TemplatesScreen()),
                ),
              ),
              ListRow(
                title: S.get('import_blocknotes'),
                subtitle: S.get('import_desc'),
                trailing: RowChevron(),
                onTap: () async {
                  final shell = context.findAncestorStateOfType<MainShellState>();
                  final imported = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const ImportScreen()),
                  );
                  // Import fatto: si va dove sono finiti i dati.
                  if (imported == true) {
                    shell?.selectTab(MainShellState.historyTab);
                    if (context.mounted) {
                      showAppSnack(context, S.get('import_done'));
                    }
                  }
                },
              ),
              ListRow(
                title: S.get('tour_replay'),
                trailing: RowChevron(),
                divider: false,
                onTap: () => context
                    .findAncestorStateOfType<MainShellState>()
                    ?.startTour(),
              ),
              const Divider(indent: kGapPage, endIndent: kGapPage),

              // ─── Dati ─────────────────────────────────────────────────
              SectionTitle(S.get('data_section')),
              // Non const: deve ricostruirsi quando cambia il tema.
              // ignore: prefer_const_constructors
              _BackupRows(),
              ListRow(
                title: S.get('data_folder'),
                subtitleWidget: Text(
                  state.storageBasePath.isNotEmpty
                      ? state.storageBasePath
                      : S.get('loading'),
                  style: T.meta.copyWith(fontSize: 12, fontFamily: 'monospace'),
                ),
                trailing: Icon(Icons.copy_outlined, size: 18, color: kText3),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: state.storageBasePath));
                  showAppSnack(context, S.get('path_copied'));
                },
              ),
              ListRow(
                title: S.get('delete_all'),
                titleColor: kRed,
                divider: false,
                onTap: () => _confirmReset(context, state),
              ),

              const SizedBox(height: 28),
              Center(
                child: Text(
                  '$workouts ${S.get('workouts_count')} · $series ${S.get('series')} · ${state.library.length} ${S.get('exercises_count')}',
                  style: T.label.copyWith(fontSize: 12),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                // Deve combaciare con pubspec.yaml (2.0.0) e col titolo in main.dart.
                child: Text('GymTracker 2.0',
                    style: T.label.copyWith(fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _toggleRow(String label, Widget control) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(kGapPage, 8, kGapPage, 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: T.body)),
          control,
        ],
      ),
    );
  }

  Future<void> _openCustomColorDialog(
      BuildContext context, AppState state) async {
    final picked = await showCustomColorDialog(
      context: context,
      initialColor: state.customAccentColor ?? kAccent,
      title: S.get('custom_color'),
      cancelText: S.get('cancel'),
      saveText: S.get('save'),
      invalidHexText: S.get('invalid_code'),
    );

    if (picked != null) {
      state.setCustomAccentColor(picked);
    }
  }

  void _confirmReset(BuildContext context, AppState state) async {
    final ok = await confirmDialog(
      context,
      title: S.get('are_you_sure'),
      message: S.get('delete_warning'),
      confirmText: S.get('delete_confirm'),
      destructive: true,
    );
    if (ok) state.resetAllData();
  }
}

/// Tessera colore: un quadrato arrotondato pieno, con un bordo quando e'
/// scelto. Niente cerchi: stessa forma di campi e bottoni.
class AccentDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final String? tooltip;
  final IconData? icon;

  const AccentDot({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
    this.tooltip,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final dot = GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 38,
        height: 38,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kRadiusControl + 1),
          border: Border.all(
            color: selected ? kText : Colors.transparent,
            width: 2,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(kRadiusControl - 3),
          ),
          child: icon != null && !selected
              ? Icon(icon, size: 16, color: Colors.white)
              : null,
        ),
      ),
    );
    return tooltip == null ? dot : Tooltip(message: tooltip!, child: dot);
  }
}

// ─── BACKUP ─────────────────────────────────────────────────────────────────
class _BackupRows extends StatefulWidget {
  const _BackupRows();

  @override
  State<_BackupRows> createState() => _BackupRowsState();
}

class _BackupRowsState extends State<_BackupRows> {
  DateTime? _lastBackup;
  int _count = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final state = context.read<AppState>();
    final last = await state.lastBackupTime();
    final count = await state.backupCount();
    if (!mounted) return;
    setState(() {
      _lastBackup = last;
      _count = count;
    });
  }

  Future<void> _backupNow() async {
    if (_busy) return;
    setState(() => _busy = true);
    final path = await context.read<AppState>().createManualBackup();
    await _refresh();
    if (!mounted) return;
    setState(() => _busy = false);
    showAppSnack(
        context, path != null ? S.get('backup_done') : S.get('backup_none'));
  }

  Future<void> _export() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await context.read<AppState>().exportBackup();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) showAppSnack(context, S.get('backup_none'));
  }

  String _lastLabel() {
    if (_lastBackup == null) return S.get('backup_none');
    final locale = S.lang == 'en' ? 'en_US' : 'it_IT';
    final when = DateFormat('d MMM, HH:mm', locale).format(_lastBackup!);
    return '${S.get('backup_last')}: $when · $_count ${S.get('backup_count')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListRow(
          title: S.get('backup'),
          subtitle: '${_lastLabel()}\n${S.get('backup_desc')}',
          trailing: TextButton(
            onPressed: _busy ? null : _backupNow,
            style: TextButton.styleFrom(foregroundColor: kAccent),
            child: Text(S.get('backup_now_short')),
          ),
        ),
        ListRow(
          title: S.get('backup_export'),
          subtitle: S.get('backup_export_hint'),
          trailing: Icon(Icons.ios_share, size: 18, color: kText3),
          onTap: _busy ? null : _export,
        ),
      ],
    );
  }
}
