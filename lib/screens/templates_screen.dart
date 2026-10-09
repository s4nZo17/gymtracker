// lib/screens/templates_screen.dart
//
// Giorni preimpostati: qui si GESTISCONO (crea, modifica, elimina, importa
// da testo). Si applicano solo da Oggi: prima ogni card aveva anche un
// "Applica" che caricava gli esercizi ma ti lasciava in Impostazioni, senza
// vedere cosa era successo.

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

  void _openEditor(BuildContext context, WorkoutTemplate? existing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _TemplateEditorScreen(existing: existing),
      ),
    );
  }

  String _summary(WorkoutTemplate t) {
    final n = t.exercises.length;
    final names = t.exerciseNames.take(3).join(', ');
    final extra = n > 3 ? ' +${n - 3}' : '';
    return '$n ${S.get('exercises_count')} · $names$extra';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return Scaffold(
          backgroundColor: kBg,
          appBar: AppBar(
            actions: [
              TextButton(
                onPressed: () =>
                    showAppSheet(context, child: const _TemplateImportSheet()),
                child: Text(S.get('import_template_text'),
                    style: TextStyle(color: kText2)),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: kBottomSafeSpace),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(kGapPage, 0, kGapPage, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(S.get('templates'), style: T.display),
                    const SizedBox(height: 4),
                    Text(S.get('templates_desc'), style: T.meta),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (state.templates.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: EmptyState(
                    title: S.get('no_templates'),
                    subtitle: S.get('no_templates_sub'),
                    actionLabel: S.get('new_template'),
                    onAction: () => _openEditor(context, null),
                  ),
                )
              else ...[
                const Divider(indent: kGapPage, endIndent: kGapPage),
                ...state.templates.map(
                  (t) => ListRow(
                    title: t.name,
                    subtitle: _summary(t),
                    subtitleMaxLines: 1,
                    trailing: RowChevron(),
                    onTap: () => _openEditor(context, t),
                  ),
                ),
              ],
            ],
          ),
          floatingActionButton: state.templates.isEmpty
              ? null
              : FloatingActionButton.extended(
                  heroTag: 'templates-fab',
                  onPressed: () => _openEditor(context, null),
                  backgroundColor: kAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  highlightElevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kRadiusPill)),
                  icon: const Icon(Icons.add, size: 22),
                  label: Text(S.get('new'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                ),
        );
      },
    );
  }
}

// ─── IMPORT DA TESTO (AI) ───────────────────────────────────────────────────

class _TemplateImportSheet extends StatefulWidget {
  const _TemplateImportSheet();

  @override
  State<_TemplateImportSheet> createState() => _TemplateImportSheetState();
}

class _TemplateImportSheetState extends State<_TemplateImportSheet> {
  final TextEditingController _ctrl = TextEditingController();
  WorkoutTemplate? _preview;
  bool _attempted = false;
  bool _copied = false;

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

  Future<void> _copyPrompt() async {
    await Clipboard.setData(const ClipboardData(text: _aiPrompt));
    if (!mounted) return;
    HapticFeedback.lightImpact();
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
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
      padding: const EdgeInsets.fromLTRB(kGapPage, 0, kGapPage, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(S.get('import_template_title'),
              style: T.title.copyWith(fontSize: 19)),
          const SizedBox(height: 4),
          Text(S.get('import_template_hint'), style: T.meta.copyWith(height: 1.4)),
          const SizedBox(height: 14),

          // Passo 1: copia il prompt
          Material(
            color: kSurface2,
            borderRadius: BorderRadius.circular(kRadiusControl + 2),
            child: InkWell(
              borderRadius: BorderRadius.circular(kRadiusControl + 2),
              onTap: _copyPrompt,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(S.get('import_template_format_label'),
                              style: T.body.copyWith(fontSize: 14.5)),
                          const SizedBox(height: 2),
                          Text(S.get('import_template_copy_hint'),
                              style: T.meta.copyWith(fontSize: 12.5)),
                        ],
                      ),
                    ),
                    Icon(_copied ? Icons.check : Icons.copy_outlined,
                        size: 19, color: _copied ? kAccent : kText2),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Passo 2: incolla la risposta
          TextField(
            controller: _ctrl,
            maxLines: 8,
            minLines: 5,
            style:
                TextStyle(color: kText, fontFamily: 'monospace', fontSize: 13),
            decoration: InputDecoration(
              hintText:
                  '# Push Day\n- Panca piana | 4x | 2:00\n- Croci ai cavi | 3x | 1:30\n...',
              hintStyle:
                  TextStyle(color: kText3, fontFamily: 'monospace', fontSize: 12),
            ),
            onChanged: (_) => _refreshPreview(state),
          ),
          const SizedBox(height: 12),
          if (_attempted && _preview == null)
            Text(S.get('import_template_invalid'),
                style: const TextStyle(color: kRed, fontSize: 13)),
          if (_preview != null) ...[
            Text(_preview!.name, style: T.body),
            const SizedBox(height: 4),
            ..._preview!.exercises.map((ex) => Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    [
                      ex.name,
                      if (ex.targetSeries != null) '${ex.targetSeries}×',
                      if (ex.restSeconds != null) formatRest(ex.restSeconds!),
                    ].join('  ·  '),
                    style: T.meta,
                  ),
                )),
          ],
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _preview == null
                ? null
                : () {
                    final ok = state.importTemplateFromText(_ctrl.text);
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(context);
                    showAppSnackOn(
                      messenger,
                      ok
                          ? S.get('import_template_done')
                          : S.get('import_template_invalid'),
                      error: !ok,
                    );
                  },
            child: Text(S.get('import')),
          ),
        ],
      ),
    );
  }
}

// ─── EDITOR ─────────────────────────────────────────────────────────────────

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
  bool _nameMissing = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    if (widget.existing != null) {
      _selectedExercises
          .addAll(widget.existing!.exercises.map((e) => e.copyWith()));
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
    HapticFeedback.selectionClick();
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
    if (name.isEmpty) {
      setState(() => _nameMissing = true);
      return;
    }
    if (_selectedExercises.isEmpty) return;

    final copy = _selectedExercises.map((e) => e.copyWith()).toList();
    final state = context.read<AppState>();
    if (widget.existing != null) {
      state.updateTemplate(widget.existing!.id, name, copy);
    } else {
      state.addTemplate(name, copy);
    }
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(
      context,
      title: S.get('delete_template'),
      confirmText: S.get('delete'),
      destructive: true,
    );
    if (!ok || !mounted) return;
    context.read<AppState>().removeTemplate(widget.existing!.id);
    Navigator.pop(context);
  }

  /// Valore tappabile a destra di un esercizio scelto ("3×", "1:30").
  Widget _valueTap(String text, bool set, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: set ? kText : kText3,
            fontWeight: FontWeight.w500,
            fontFeatures: kTabular,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final term = _search.toLowerCase();
        final filtered = state.library.where((ex) {
          if (term.isEmpty) return true;
          return ex.name.toLowerCase().contains(term) ||
              ex.category.toLowerCase().contains(term);
        }).toList();

        final grouped = <String, List<LibraryExercise>>{};
        for (final ex in filtered) {
          final cat =
              ex.category.isNotEmpty ? ex.category : S.get('uncategorized');
          grouped.putIfAbsent(cat, () => []).add(ex);
        }

        return Scaffold(
          backgroundColor: kBg,
          appBar: AppBar(
            title: Text(widget.existing != null
                ? S.get('edit_template')
                : S.get('new_template')),
            actions: [
              if (widget.existing != null)
                IconButton(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: S.get('delete'),
                ),
              const SizedBox(width: 6),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(kGapPage, 8, kGapPage, 0),
                child: TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  style: T.body,
                  onChanged: (_) {
                    if (_nameMissing) setState(() => _nameMissing = false);
                  },
                  decoration:
                      InputDecoration(hintText: S.get('template_name')),
                ),
              ),
              if (_nameMissing)
                Padding(
                  padding: const EdgeInsets.fromLTRB(kGapPage, 6, kGapPage, 0),
                  child: Text(S.get('template_name_missing'),
                      style: const TextStyle(color: kRed, fontSize: 13)),
                ),

              // Esercizi scelti, nell'ordine in cui li farai.
              SectionTitle(
                _selectedExercises.isEmpty
                    ? S.get('select_exercises')
                    : '${_selectedExercises.length} ${S.get('exercises_count')} · ${S.get('series_rest_hint')}',
              ),
              ..._selectedExercises.asMap().entries.map((entry) {
                final i = entry.key;
                final ex = entry.value;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(kGapPage, 0, 8, 0),
                  child: Row(
                    children: [
                      Expanded(child: Text(ex.name, style: T.body)),
                      _valueTap(
                        ex.targetSeries != null ? '${ex.targetSeries}×' : '–×',
                        ex.targetSeries != null,
                        () => _editTargetFor(i),
                      ),
                      _valueTap(
                        ex.restSeconds != null
                            ? formatRest(ex.restSeconds!)
                            : '–:––',
                        ex.restSeconds != null,
                        () => _editRestFor(i),
                      ),
                      IconButton(
                        onPressed: () => _toggleExercise(ex.name),
                        icon: Icon(Icons.close, size: 18, color: kText3),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                );
              }),

              Padding(
                padding: const EdgeInsets.fromLTRB(kGapPage, 18, kGapPage, 4),
                child: AppSearchField(
                  hint: S.get('search_exercise'),
                  value: _search,
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              for (final entry in grouped.entries) ...[
                SectionTitle(entry.key),
                for (final ex in entry.value)
                  ListRow(
                    title: ex.name,
                    onTap: () => _toggleExercise(ex.name),
                    padding: const EdgeInsets.symmetric(
                        horizontal: kGapPage, vertical: 12),
                    trailing: Icon(
                      _indexOfName(ex.name) >= 0 ? Icons.check : Icons.add,
                      size: 22,
                      color:
                          _indexOfName(ex.name) >= 0 ? kAccent : kText3,
                    ),
                  ),
              ],
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(kGapPage, 8, kGapPage, 12),
              child: ElevatedButton(
                onPressed: _selectedExercises.isEmpty ? null : _save,
                child: Text(S.get('save')),
              ),
            ),
          ),
        );
      },
    );
  }
}
