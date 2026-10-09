// lib/screens/templates_screen.dart
//
// Giorni preimpostati 2.0: stesse funzioni (crea/modifica/elimina/applica,
// import da testo AI), card piu chiare.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return Scaffold(
          backgroundColor: kBg,
          appBar: AppBar(
            title: Text(S.get('templates')),
            actions: [
              IconButton(
                tooltip: S.get('import_template_text'),
                icon: const Icon(Icons.content_paste_go),
                onPressed: () => _showTextImport(context, state),
              ),
            ],
          ),
          body: state.templates.isEmpty
              ? EmptyState(
                  icon: Icons.flash_on, title: S.get('no_templates'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      kGapPage, 8, kGapPage, kBottomSafeSpace),
                  itemCount: state.templates.length,
                  itemBuilder: (_, i) =>
                      _TemplateCard(template: state.templates[i]),
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showTemplateEditor(context, state, null),
            backgroundColor: kAccent,
            foregroundColor: Colors.white,
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _showTemplateEditor(
      BuildContext context, AppState state, WorkoutTemplate? existing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _TemplateEditorScreen(existing: existing),
      ),
    );
  }

  void _showTextImport(BuildContext context, AppState state) {
    showAppSheet(
      context,
      child: const _TemplateImportSheet(),
    );
  }
}

class _TemplateImportSheet extends StatefulWidget {
  const _TemplateImportSheet();

  @override
  State<_TemplateImportSheet> createState() => _TemplateImportSheetState();
}

class _TemplateImportSheetState extends State<_TemplateImportSheet> {
  final TextEditingController _ctrl = TextEditingController();
  WorkoutTemplate? _preview;
  bool _attempted = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _refreshPreview(AppState state) {
    setState(() {
      _attempted = _ctrl.text.trim().isNotEmpty;
      _preview = state.parseTemplateText(_ctrl.text);
    });
  }

  static const String _aiPrompt =
      '''Crea una scheda di allenamento in palestra e restituiscila ESATTAMENTE in questo formato testuale (niente altro testo, niente spiegazioni, solo il blocco qui sotto):

# Nome scheda
- Nome esercizio | serie | recupero
- Nome esercizio | serie | recupero
- Nome esercizio | serie | recupero

Regole:
- La prima riga inizia con "#" e contiene il nome della scheda (es. "# Push Day", "# Petto e Tricipiti").
- Ogni esercizio va su una riga propria, preceduto da "- ".
- Dopo il nome dell'esercizio metti " | " e poi il numero di serie, poi " | " e il tempo di recupero.
- Le serie si scrivono con la "x": "4x", "3x". Un numero senza "x" viene letto come recupero.
- Il recupero accetta questi formati: "2:00", "1:30", "90s", "2m", "2m30s", "120".
- Serie e recupero sono entrambi opzionali: puoi ometterne uno o tutti e due.
- Niente ripetizioni né pesi: solo nome esercizio, serie e recupero.

Esempio completo (questo è il formato finale che mi devi dare):

# Push Day - Petto, Spalle, Tricipiti
- Panca piana bilanciere | 4x | 2:30
- Panca inclinata manubri | 3x | 2:00
- Croci ai cavi | 3x | 1:30
- Military press | 4x | 2:00
- Alzate laterali | 3x | 1:00
- Pushdown cavo | 3x | 1:00
- French press | 3x | 1:00''';

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            S.get('import_template_title'),
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600, color: kText),
          ),
          const SizedBox(height: 4),
          Text(S.get('import_template_hint'),
              style: TextStyle(fontSize: 12, color: kText2, height: 1.4)),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.smart_toy_outlined, size: 14, color: kAccent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(S.get('import_template_format_label'),
                    style: TextStyle(
                        fontSize: 11,
                        color: kAccent,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600)),
              ),
              const _CopyButton(text: _aiPrompt),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kAccent.withValues(alpha: 0.3)),
            ),
            child: SelectableText(
              _aiPrompt,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: kText2,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(S.get('import_template_paste_label'),
              style: TextStyle(
                  fontSize: 11,
                  color: kText3,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _ctrl,
            maxLines: 8,
            minLines: 5,
            style: TextStyle(color: kText, fontFamily: 'monospace', fontSize: 13),
            decoration: InputDecoration(
              hintText:
                  '# Push Day\n- Panca piana | 4x | 2:00\n- Croci ai cavi | 3x | 1:30\n...',
              hintStyle: TextStyle(
                  color: kText3, fontFamily: 'monospace', fontSize: 12),
            ),
            onChanged: (_) => _refreshPreview(state),
          ),
          const SizedBox(height: 12),
          if (_attempted && _preview == null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: kRed, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(S.get('import_template_invalid'),
                        style: const TextStyle(color: kRed, fontSize: 13)),
                  ),
                ],
              ),
            ),
          if (_preview != null) ...[
            Text(S.get('import_template_preview'),
                style:
                    TextStyle(fontSize: 11, color: kText3, letterSpacing: 1)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kSurface3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _preview!.name,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: kText),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _preview!.exercises.map((ex) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: kSurface2,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(ex.name,
                                style:
                                    TextStyle(fontSize: 12, color: kText2)),
                            // Stessi dati della card del giorno: quello che
                            // vedi in anteprima è quello che viene importato.
                            if (ex.targetSeries != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                '${ex.targetSeries}x',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: kAccent,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                            if (ex.restSeconds != null) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.timer_outlined,
                                  size: 12, color: kAccent),
                              const SizedBox(width: 2),
                              Text(
                                formatRest(ex.restSeconds!),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: kAccent,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    Text(S.get('cancel'), style: TextStyle(color: kText2)),
              ),
              const Spacer(),
              SizedBox(
                width: 140,
                child: ElevatedButton(
                  onPressed: _preview == null
                      ? null
                      : () {
                          final ok = state.importTemplateFromText(_ctrl.text);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? S.get('import_template_done')
                                    : S.get('import_template_invalid'),
                              ),
                            ),
                          );
                        },
                  child: Text(S.get('import')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  final String text;
  const _CopyButton({required this.text});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    setState(() => _copied = true);
    HapticFeedback.lightImpact();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _copy,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: kAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: kAccent.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_copied ? Icons.check : Icons.copy, size: 14, color: kAccent),
            const SizedBox(width: 4),
            Text(
              _copied ? S.get('copied') : S.get('copy'),
              style: TextStyle(
                  fontSize: 11, color: kAccent, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final WorkoutTemplate template;

  const _TemplateCard({required this.template});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Expanded(
                child: Text(
                  template.name,
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, color: kText),
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 19, color: kText3),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _TemplateEditorScreen(existing: template),
                  ),
                ),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 19, color: kRed),
                onPressed: () => _confirmDelete(context, state),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: template.exercises
                .map((ex) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: kSurface2,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(ex.name,
                              style: TextStyle(fontSize: 12, color: kText2)),
                          if (ex.targetSeries != null) ...[
                            const SizedBox(width: 5),
                            Text(
                              '${ex.targetSeries}x',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: kAccent,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                          if (ex.restSeconds != null) ...[
                            const SizedBox(width: 5),
                            Icon(Icons.timer_outlined,
                                size: 11, color: kAccent),
                            const SizedBox(width: 2),
                            Text(
                              formatRest(ex.restSeconds!),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: kAccent,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 46)),
              onPressed: () {
                state.applyTemplate(template);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(S.get('template_applied'))),
                );
              },
              child: Text(S.get('apply_template')),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppState state) async {
    final ok = await confirmDialog(
      context,
      title: S.get('delete_template'),
      confirmText: S.get('delete'),
      destructive: true,
    );
    if (ok) state.removeTemplate(template.id);
  }
}

// ─── TEMPLATE EDITOR ────────────────────────────────────────────────────────

class _TemplateEditorScreen extends StatefulWidget {
  final WorkoutTemplate? existing;

  const _TemplateEditorScreen({this.existing});

  @override
  State<_TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<_TemplateEditorScreen> {
  late TextEditingController _nameCtrl;
  final List<TemplateExercise> _selectedExercises = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    if (widget.existing != null) {
      _selectedExercises.addAll(widget.existing!.exercises.map((e) => e.copyWith()));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  int _indexOfName(String name) => _selectedExercises
      .indexWhere((e) => e.name.toLowerCase() == name.toLowerCase());

  void _toggleExercise(String name) {
    setState(() {
      final i = _indexOfName(name);
      if (i >= 0) {
        _selectedExercises.removeAt(i);
      } else {
        _selectedExercises.add(TemplateExercise(name: name));
      }
    });
  }

  Future<void> _editRestFor(int index) async {
    final current = _selectedExercises[index];
    final picked =
        await RestPickerDialog.show(context, initial: current.restSeconds);
    if (picked == null) return;
    setState(() {
      _selectedExercises[index] = picked == 0
          ? current.copyWith(clearRest: true)
          : current.copyWith(restSeconds: picked);
    });
  }

  Future<void> _editTargetFor(int index) async {
    final current = _selectedExercises[index];
    final picked =
        await TargetSeriesDialog.show(context, initial: current.targetSeries);
    if (picked == null) return;
    setState(() {
      _selectedExercises[index] = picked == 0
          ? current.copyWith(clearTarget: true)
          : current.copyWith(targetSeries: picked);
    });
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _selectedExercises.isEmpty) return;

    final copy = _selectedExercises.map((e) => e.copyWith()).toList();
    final state = context.read<AppState>();
    if (widget.existing != null) {
      state.updateTemplate(widget.existing!.id, name, copy);
    } else {
      state.addTemplate(name, copy);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final filtered = state.library.where((ex) {
          if (_search.isEmpty) return true;
          return ex.name.toLowerCase().contains(_search.toLowerCase()) ||
              ex.category.toLowerCase().contains(_search.toLowerCase());
        }).toList();

        final grouped = <String, List<dynamic>>{};
        for (final ex in filtered) {
          final cat = ex.category.isNotEmpty ? ex.category : 'Altro';
          grouped.putIfAbsent(cat, () => []).add(ex);
        }

        return Scaffold(
          backgroundColor: kBg,
          appBar: AppBar(
            title: Text(widget.existing != null
                ? S.get('edit_template')
                : S.get('new_template')),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: TextField(
                  controller: _nameCtrl,
                  decoration:
                      InputDecoration(labelText: S.get('template_name')),
                ),
              ),
              if (_selectedExercises.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _selectedExercises.asMap().entries.map((entry) {
                      final i = entry.key;
                      final ex = entry.value;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: kAccent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: kAccent.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(ex.name,
                                style:
                                    TextStyle(fontSize: 12, color: kAccent)),
                            const SizedBox(width: 6),
                            // Serie previste: l'app precreera' altrettante
                            // righe da compilare quando applichi il giorno.
                            GestureDetector(
                              onTap: () => _editTargetFor(i),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.format_list_numbered,
                                      size: 12,
                                      color: ex.targetSeries != null
                                          ? kAccent
                                          : kText3),
                                  const SizedBox(width: 2),
                                  Text(
                                    ex.targetSeries != null
                                        ? '${ex.targetSeries}x'
                                        : '—',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: ex.targetSeries != null
                                          ? kAccent
                                          : kText3,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _editRestFor(i),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.timer_outlined,
                                      size: 12,
                                      color: ex.restSeconds != null
                                          ? kAccent
                                          : kText3),
                                  const SizedBox(width: 2),
                                  Text(
                                    ex.restSeconds != null
                                        ? formatRest(ex.restSeconds!)
                                        : '—',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: ex.restSeconds != null
                                          ? kAccent
                                          : kText3,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _toggleExercise(ex.name),
                              child:
                                  Icon(Icons.close, size: 14, color: kAccent),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: S.get('search_exercise'),
                    prefixIcon: Icon(Icons.search, color: kText3),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    S.get('select_exercises'),
                    style: TextStyle(
                        fontSize: 11, color: kText3, letterSpacing: 1),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: grouped.keys.length,
                  itemBuilder: (_, groupIdx) {
                    final cat = grouped.keys.elementAt(groupIdx);
                    final exercises = grouped[cat]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionTitle(cat),
                        ...exercises.map((ex) {
                          final selected = _indexOfName(ex.name) >= 0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 3),
                            child: AppCard(
                              padding: const EdgeInsets.all(13),
                              borderColor: selected ? kAccent : null,
                              onTap: () => _toggleExercise(ex.name),
                              child: Row(
                                children: [
                                  Text(
                                    ex.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: selected ? kAccent : kText,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    selected
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    color: selected ? kAccent : kText3,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: _selectedExercises.isEmpty ? null : _save,
                  child: Text(
                    widget.existing != null
                        ? S.get('update_template')
                        : S.get('save_template'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
