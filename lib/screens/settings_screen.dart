// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/custom_color_dialog.dart';
import 'import_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) => Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(title: Text(S.get('settings'))),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionCard(
              icon: Icons.palette_outlined,
              iconColor: kAccent,
              title: S.get('appearance'),
              children: [
                _settingRow(
                  label: S.get('language'),
                  child: _segmentedControl(
                    options: const {'it': 'IT Italiano', 'en': 'EN English'},
                    selected: state.prefs.language,
                    onChanged: state.setLanguage,
                  ),
                ),
                Divider(color: kSurface3, height: 1),
                _settingRow(
                  label: S.get('theme'),
                  child: _segmentedControl(
                    options: {'dark': S.get('dark'), 'light': S.get('light')},
                    selected: state.prefs.themeMode,
                    onChanged: state.setThemeMode,
                  ),
                ),
                Divider(color: kSurface3, height: 1),
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
                Divider(color: kSurface3, height: 1),
                _settingRow(
                  label: S.get('date_format'),
                  child: _segmentedControl(
                    options: const {'dd-MM': 'GG-MM', 'MM-dd': 'MM-GG'},
                    selected: state.prefs.dateFormat,
                    onChanged: state.setDateFormat,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              icon: Icons.folder_outlined,
              iconColor: kAccent,
              title: S.get('data_folder'),
              children: [
                Text(S.get('data_saved_in'), style: TextStyle(fontSize: 13, color: kText2)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kSurface2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          state.storageBasePath.isNotEmpty ? state.storageBasePath : S.get('loading'),
                          style: TextStyle(fontSize: 12, color: kText2, fontFamily: 'monospace'),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: state.storageBasePath));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(S.get('path_copied'))),
                          );
                        },
                        child: Icon(Icons.copy, size: 16, color: kText3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(S.get('data_files_info'), style: TextStyle(fontSize: 12, color: kText3, height: 1.6)),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              icon: Icons.bar_chart,
              iconColor: kAccent,
              title: S.get('statistics'),
              children: [
                _statRow(S.get('total_workouts'), '${state.workouts.where((w) => w.exercises.isNotEmpty).length}'),
                _statRow(S.get('exercises_in_lib'), '${state.library.length}'),
                _statRow(S.get('total_series_stat'), '${state.workouts.fold(0, (acc, w) => acc + w.totalSeries)}'),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ImportScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.upload_outlined, color: kAccent, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            S.get('import_blocknotes'),
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: kText),
                          ),
                          Text(S.get('import_desc'), style: TextStyle(fontSize: 12, color: kText2)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: kText3),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              icon: Icons.warning_amber_outlined,
              iconColor: kRed,
              title: S.get('danger_zone'),
              children: [
                GestureDetector(
                  onTap: () => _confirmReset(context, state),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: kRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kRed.withValues(alpha: 0.3)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      S.get('delete_all'),
                      style: TextStyle(color: kRed, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Center(
              child: Text('GymTracker v2.0', style: TextStyle(fontSize: 12, color: kText3)),
            ),
          ],
        ),
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: selected ? Border.all(color: kText, width: 2.5) : null,
              boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)] : null,
            ),
            child: selected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : (icon != null ? Icon(icon, color: Colors.white, size: 18) : null),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: selected ? kText : kText3),
          ),
        ],
      ),
    );
  }

  Future<void> _openCustomColorDialog(BuildContext context, AppState state) async {
    final picked = await showCustomColorDialog(
      context: context,
      initialColor: state.customAccentColor ?? kAccent,
      title: 'Colore personalizzato',
      cancelText: S.get('cancel'),
      saveText: 'Salva',
      invalidHexText: 'Codice non valido',
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kSurface3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: kText)),
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
          Text(label, style: TextStyle(fontSize: 13, color: kText2)),
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
      decoration: BoxDecoration(
        color: kSurface2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.entries.map((e) {
          final isSelected = e.key == selected;
          return GestureDetector(
            onTap: () => onChanged(e.key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? kAccent : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                e.value,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : kText3,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kAccent)),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, AppState state) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kSurface,
        title: Text(S.get('are_you_sure'), style: TextStyle(color: kText)),
        content: Text(S.get('delete_warning'), style: TextStyle(color: kText2)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(S.get('cancel'))),
          TextButton(
            onPressed: () {
              state.resetAllData();
              Navigator.of(dialogContext).pop();
            },
            child: Text(S.get('delete_confirm'), style: TextStyle(color: kRed)),
          ),
        ],
      ),
    );
  }
}

