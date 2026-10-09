// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import '../widgets/custom_color_dialog.dart';
import 'import_screen.dart';
import 'templates_screen.dart';
import '../main.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) => Scaffold(
        backgroundColor: kBg,
        body: ListView(
          padding: const EdgeInsets.only(bottom: kBottomSafeSpace),
          children: [
            PageHeader(title: S.get('settings')),
            const SizedBox(height: 4),
            _pad(_sectionCard(
              icon: Icons.palette_outlined,
              iconColor: kAccent,
              title: S.get('appearance'),
              children: [
                _settingRow(
                  label: S.get('language'),
                  child: _segmentedControl(
                    options: const {'it': 'IT', 'en': 'EN'},
                    selected: state.prefs.language,
                    onChanged: state.setLanguage,
                  ),
                ),
                Divider(color: kSurface3.withValues(alpha: 0.5), height: 1),
                _settingRow(
                  label: S.get('theme'),
                  child: _segmentedControl(
                    options: {'dark': S.get('dark'), 'light': S.get('light')},
                    selected: state.prefs.themeMode,
                    onChanged: state.setThemeMode,
                  ),
                ),
                Divider(color: kSurface3.withValues(alpha: 0.5), height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.get('accent_color'),
                        style: TextStyle(fontSize: 13, color: kText2),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ...accentPresets.map((p) {
                            final selected = state.prefs.accentPreset == p.id;
                            return _accentChip(
                              label: S.lang == 'it' ? p.nameIt : p.nameEn,
                              color: p.primary,
                              selected: selected,
                              onTap: () => state.setAccentPreset(p.id),
                            );
                          }),
                          _accentChip(
                            label: 'Custom',
                            color: state.customAccentColor ?? kAccent,
                            selected: state.prefs.accentPreset == 'custom',
                            icon: Icons.color_lens_outlined,
                            onTap: () => _openCustomColorDialog(context, state),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(color: kSurface3.withValues(alpha: 0.5), height: 1),
                _settingRow(
                  label: S.get('date_format'),
                  child: _segmentedControl(
                    options: const {'dd-MM': 'GG-MM', 'MM-dd': 'MM-GG'},
                    selected: state.prefs.dateFormat,
                    onChanged: state.setDateFormat,
                  ),
                ),
              ],
            )),
            const SizedBox(height: 18),

            _group(S.get('training')),
            // Giorni preimpostati + import: card azione in evidenza
            _pad(_actionCard(
              context,
              icon: Icons.flash_on,
              title: S.get('templates'),
              subtitle: S.get('templates_desc'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TemplatesScreen()),
              ),
            )),
            const SizedBox(height: 10),
            _pad(_actionCard(
              context,
              icon: Icons.upload_outlined,
              title: S.get('import_blocknotes'),
              subtitle: S.get('import_desc'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ImportScreen()),
              ),
            )),
            const SizedBox(height: 10),
            _pad(_actionCard(
              context,
              icon: Icons.tour_outlined,
              title: S.get('tour_replay'),
              subtitle: S.lang == 'it'
                  ? 'Il giro guidato dell\'app, in 4 passi'
                  : 'The guided app walkthrough, in 4 steps',
              onTap: () => context
                  .findAncestorStateOfType<MainShellState>()
                  ?.startTour(),
            )),
            const SizedBox(height: 18),

            _group(S.get('data_section')),
            _pad(const _BackupCard()),
            const SizedBox(height: 14),

            _pad(_sectionCard(
              icon: Icons.bar_chart,
              iconColor: kAccent,
              title: S.get('statistics'),
              children: [
                _statRow(S.get('total_workouts'),
                    '${state.workouts.where((w) => w.exercises.isNotEmpty).length}'),
                _statRow(S.get('exercises_in_lib'), '${state.library.length}'),
                _statRow(S.get('total_series_stat'),
                    '${state.workouts.fold(0, (acc, w) => acc + w.totalSeries)}'),
              ],
            )),
            const SizedBox(height: 14),

            _pad(_sectionCard(
              icon: Icons.folder_outlined,
              iconColor: kAccent,
              title: S.get('data_folder'),
              children: [
                Text(S.get('data_saved_in'),
                    style: TextStyle(fontSize: 13, color: kText2)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kSurface2,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          state.storageBasePath.isNotEmpty
                              ? state.storageBasePath
                              : S.get('loading'),
                          style: TextStyle(
                              fontSize: 12,
                              color: kText2,
                              fontFamily: 'monospace'),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: state.storageBasePath));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(S.get('path_copied'))),
                          );
                        },
                        icon: Icon(Icons.copy, size: 16, color: kText3),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(S.get('data_files_info'),
                    style:
                        TextStyle(fontSize: 12, color: kText3, height: 1.6)),
              ],
            )),
            const SizedBox(height: 14),

            _pad(_sectionCard(
              icon: Icons.warning_amber_outlined,
              iconColor: kRed,
              title: S.get('danger_zone'),
              children: [
                Material(
                  color: kRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _confirmReset(context, state),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      alignment: Alignment.center,
                      child: Text(
                        S.get('delete_all'),
                        style: const TextStyle(
                            color: kRed, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            )),
            const SizedBox(height: 30),
            Center(
              // Deve combaciare con pubspec.yaml (2.0.0) e col titolo in main.dart.
              child: Text('GymTracker 2.0',
                  style: TextStyle(fontSize: 12, color: kText3)),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// Margine laterale di pagina: la ListView ora e' a tutta larghezza per
  /// far arrivare header e titoli di gruppo fino ai bordi.
  Widget _pad(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: kGapPage),
        child: child,
      );

  Widget _group(String title) => Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 2),
        child: SectionTitle(title),
      );

  Widget _actionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      borderColor: kAccent.withValues(alpha: 0.3),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: kAccent, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15, color: kText),
                ),
                Text(subtitle, style: TextStyle(fontSize: 12, color: kText2)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: kText3),
        ],
      ),
    );
  }

  Widget _accentChip({
    required String label,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(13),
              border: selected ? Border.all(color: kText, width: 2.5) : null,
              boxShadow: selected
                  ? [
                      BoxShadow(
                          color: color.withValues(alpha: 0.4), blurRadius: 8)
                    ]
                  : null,
            ),
            child: selected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : (icon != null
                    ? Icon(icon, color: Colors.white, size: 18)
                    : null),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style:
                TextStyle(fontSize: 10, color: selected ? kText : kText3),
          ),
        ],
      ),
    );
  }

  Future<void> _openCustomColorDialog(
      BuildContext context, AppState state) async {
    final picked = await showCustomColorDialog(
      context: context,
      initialColor: state.customAccentColor ?? kAccent,
      title: S.lang == 'it' ? 'Colore personalizzato' : 'Custom color',
      cancelText: S.get('cancel'),
      saveText: S.lang == 'it' ? 'Salva' : 'Save',
      invalidHexText: S.lang == 'it' ? 'Codice non valido' : 'Invalid code',
    );

    if (picked != null) {
      state.setCustomAccentColor(picked);
    }
  }

  Widget _sectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: kSurface3.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15, color: kText)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _settingRow({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 13.5, color: kText2)),
          const Spacer(),
          child,
        ],
      ),
    );
  }

  Widget _segmentedControl({
    required Map<String, String> options,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: kSurface2,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.entries.map((e) {
          final isSelected = e.key == selected;
          return GestureDetector(
            onTap: () => onChanged(e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? kAccent : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                e.value,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isSelected ? Colors.white : kText3,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: kText2)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: kAccent)),
        ],
      ),
    );
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

// ─── BACKUP CARD ────────────────────────────────────────────────────────────
class _BackupCard extends StatefulWidget {
  const _BackupCard();

  @override
  State<_BackupCard> createState() => _BackupCardState();
}

class _BackupCardState extends State<_BackupCard> {
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
    final state = context.read<AppState>();
    final path = await state.createManualBackup();
    await _refresh();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text(path != null ? S.get('backup_done') : S.get('backup_none'))),
    );
  }

  Future<void> _export() async {
    if (_busy) return;
    setState(() => _busy = true);
    final state = context.read<AppState>();
    final ok = await state.exportBackup();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.get('backup_none'))),
      );
    }
  }

  String _lastLabel() {
    if (_lastBackup == null) return S.get('backup_none');
    final locale = S.lang == 'en' ? 'en_US' : 'it_IT';
    final when = DateFormat('d MMM, HH:mm', locale).format(_lastBackup!);
    return '${S.get('backup_last')}: $when  ·  $_count ${S.get('backup_count')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: kSurface3.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.backup_outlined, color: kAccent, size: 20),
              const SizedBox(width: 8),
              Text(S.get('backup'),
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15, color: kText)),
            ],
          ),
          const SizedBox(height: 10),
          Text(S.get('backup_desc'),
              style: TextStyle(fontSize: 12, color: kText2, height: 1.5)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: kSurface2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.history, size: 14, color: kText3),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _lastLabel(),
                    style: TextStyle(fontSize: 12, color: kText2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: kAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _busy ? null : _backupNow,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_outlined, size: 16, color: kAccent),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              S.get('backup_now'),
                              style: TextStyle(
                                  color: kAccent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Material(
                  color: kSurface2,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _busy ? null : _export,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.ios_share, size: 16, color: kText2),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              S.get('backup_export'),
                              style: TextStyle(
                                  color: kText2,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(S.get('backup_export_hint'),
              style: TextStyle(fontSize: 11, color: kText3, height: 1.5)),
        ],
      ),
    );
  }
}
