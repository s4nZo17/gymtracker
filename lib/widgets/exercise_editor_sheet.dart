// lib/widgets/exercise_editor_sheet.dart
//
// Crea o modifica un esercizio della libreria: nome, categoria, muscoli
// primari e secondari (sono questi ad alimentare la mappa del corpo).
// Si apre dal selettore esercizi ("Nuovo") e dalla scheda di un esercizio.

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/models.dart';
import '../models/muscle_groups.dart';
import '../services/app_state.dart';
import '../theme.dart';
import 'widgets.dart';

const kDefaultCategories = [
  'Petto',
  'Schiena',
  'Gambe',
  'Spalle',
  'Bicipiti',
  'Tricipiti',
  'Core',
];

class ExerciseEditorSheet extends StatefulWidget {
  final AppState state;
  final LibraryExercise? existing;

  /// Nome precompilato quando si crea un nuovo esercizio (es. dal picker).
  final String? initialName;

  /// Chiamato dopo il salvataggio con il nome dell'esercizio salvato.
  final void Function(String name)? onSaved;

  const ExerciseEditorSheet({
    super.key,
    required this.state,
    this.existing,
    this.initialName,
    this.onSaved,
  });

  @override
  State<ExerciseEditorSheet> createState() => ExerciseEditorSheetState();
}

class ExerciseEditorSheetState extends State<ExerciseEditorSheet> {
  late TextEditingController _nameCtrl;
  late String _category;
  late Set<String> _primaryMuscles;
  late Set<String> _secondaryMuscles;
  bool _invalid = false;

  /// Le categorie proposte: quelle base piu' quelle gia' usate in libreria.
  List<String> get _categories => {
        ...kDefaultCategories,
        for (final e in widget.state.library)
          if (e.category.trim().isNotEmpty) e.category.trim(),
      }.toList();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: widget.existing?.name ?? widget.initialName ?? '');
    _category = widget.existing?.category ?? '';
    _primaryMuscles = Set.from(widget.existing?.primaryMuscles ?? []);
    _secondaryMuscles = Set.from(widget.existing?.secondaryMuscles ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  /// Un tocco = primario, due = secondario, tre = spento. Una sola fila di
  /// muscoli invece di due elenchi identici uno sotto l'altro.
  void _cycleMuscle(String id) {
    setState(() {
      if (_primaryMuscles.remove(id)) {
        _secondaryMuscles.add(id);
      } else if (_secondaryMuscles.remove(id)) {
        // spento
      } else {
        _primaryMuscles.add(id);
      }
    });
  }

  Future<void> _customCategory() async {
    final ctrl = TextEditingController(
        text: _categories.contains(_category) ? '' : _category);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.get('category')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(color: kText),
          onSubmitted: (v) => Navigator.pop(dialogContext, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(S.get('cancel'), style: TextStyle(color: kText2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, ctrl.text),
            child: Text(S.get('save')),
          ),
        ],
      ),
    );
    if (value != null) setState(() => _category = value.trim());
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _invalid = true);
      return;
    }
    var saved = true;
    if (widget.existing != null) {
      saved = widget.state.updateLibraryExercise(
        widget.existing!.id,
        name,
        _category,
        primaryMuscles: _primaryMuscles.toList(),
        secondaryMuscles: _secondaryMuscles.toList(),
      );
    } else {
      widget.state.addToLibrary(
        name,
        _category,
        primaryMuscles: _primaryMuscles.toList(),
        secondaryMuscles: _secondaryMuscles.toList(),
      );
    }
    if (saved) {
      Navigator.pop(context);
      widget.onSaved?.call(name);
    } else {
      setState(() => _invalid = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categories;
    final isCustom = _category.isNotEmpty && !categories.contains(_category);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(kGapPage, 0, kGapPage, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            widget.existing != null
                ? S.get('edit_exercise')
                : S.get('new_exercise'),
            style: T.title.copyWith(fontSize: 19),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            autofocus: widget.existing == null && widget.initialName == null,
            textCapitalization: TextCapitalization.sentences,
            style: T.body,
            onChanged: (_) {
              if (_invalid) setState(() => _invalid = false);
            },
            decoration: InputDecoration(hintText: S.get('exercise_name')),
          ),
          if (_invalid)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(S.get('exercise_name_invalid'),
                  style: const TextStyle(color: kRed, fontSize: 13)),
            ),
          const SizedBox(height: 20),
          Text(S.get('category'), style: T.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in categories)
                Pill(
                  label: c,
                  selected: _category == c,
                  onTap: () =>
                      setState(() => _category = _category == c ? '' : c),
                ),
              Pill(
                label: isCustom ? _category : '+',
                selected: isCustom,
                onTap: _customCategory,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(S.get('muscles'), style: T.label),
          const SizedBox(height: 2),
          Text(S.get('muscles_hint'), style: T.meta.copyWith(fontSize: 12.5)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: allMuscleGroups.map((m) {
              final primary = _primaryMuscles.contains(m.id);
              final secondary = _secondaryMuscles.contains(m.id);
              return GestureDetector(
                onTap: () => _cycleMuscle(m.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                  decoration: BoxDecoration(
                    color: primary ? kText : kSurface2,
                    borderRadius: BorderRadius.circular(kRadiusControl + 2),
                    border: Border.all(
                      color: secondary ? kText2 : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    m.name(S.lang),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: primary || secondary
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: primary ? kBg : (secondary ? kText : kText2),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _save,
            child: Text(widget.existing != null
                ? S.get('save')
                : S.get('save_exercise')),
          ),
        ],
      ),
    );
  }
}
