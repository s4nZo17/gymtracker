// lib/screens/library_screen.dart
//
// Libreria esercizi 2.0: niente piu azioni nascoste dietro lo swipe.
// Tocca una card per aprire il menu con Modifica / Elimina, ben visibili.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../services/app_state.dart';
import '../models/models.dart';
import '../models/muscle_groups.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import 'progress_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _search = '';
  String _category = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final term = _search.toLowerCase();
        final categories = <String>{
          for (final e in state.library)
            if (e.category.trim().isNotEmpty) e.category.trim(),
        }.toList()
          ..sort();

        final filtered = state.library.where((e) {
          final matchesSearch = term.isEmpty ||
              e.name.toLowerCase().contains(term) ||
              e.category.toLowerCase().contains(term);
          final matchesCat = _category.isEmpty || e.category == _category;
          return matchesSearch && matchesCat;
        }).toList();

        final grouped = <String, List<LibraryExercise>>{};
        for (final ex in filtered) {
          final cat = ex.category.isNotEmpty
              ? ex.category
              : (S.lang == 'it' ? 'Senza categoria' : 'Uncategorized');
          grouped.putIfAbsent(cat, () => []).add(ex);
        }

        return Scaffold(
          backgroundColor: kBg,
          body: Column(
            children: [
              PageHeader(
                title: S.get('exercises'),
                subtitle:
                    '${state.library.length} ${S.get('exercises').toLowerCase()}',
                bottom: AppSearchField(
                  hint: S.get('search'),
                  value: _search,
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              // Stessi filtri per categoria del picker: due liste di esercizi
              // che si comportano allo stesso modo.
              if (categories.isNotEmpty)
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(kGapPage, 4, kGapPage, 4),
                    children: [
                      CategoryChip(
                        label: S.get('all'),
                        selected: _category.isEmpty,
                        onTap: () => setState(() => _category = ''),
                      ),
                      const SizedBox(width: 8),
                      ...categories.expand((c) => [
                            CategoryChip(
                              label: c,
                              selected: _category == c,
                              onTap: () => setState(() =>
                                  _category = _category == c ? '' : c),
                            ),
                            const SizedBox(width: 8),
                          ]),
                    ],
                  ),
                ),
              Expanded(
                child: filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.menu_book_outlined,
                        title: _search.isEmpty && _category.isEmpty
                            ? S.get('no_exercise_found_lib')
                            : S.get('no_results'),
                        subtitle: _search.isEmpty && _category.isEmpty
                            ? S.get('library_empty_sub')
                            : S.get('try_other_search'),
                        actionLabel: _search.isEmpty && _category.isEmpty
                            ? S.get('new')
                            : null,
                        onAction: _search.isEmpty && _category.isEmpty
                            ? () => _showExerciseDialog(context, state, null)
                            : null,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(
                            top: 4, bottom: kBottomSafeSpace),
                        itemCount: grouped.keys.length,
                        itemBuilder: (_, groupIdx) {
                          final cat = grouped.keys.elementAt(groupIdx);
                          final exs = grouped[cat]!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionTitle('$cat  ·  ${exs.length}'),
                              ...exs.map((ex) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: kGapPage, vertical: 3),
                                    child: _exerciseTile(context, state, ex),
                                  )),
                              const SizedBox(height: 6),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () =>
                _showExerciseDialog(context, context.read<AppState>(), null),
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

  /// Riga della libreria: nome, muscoli e — se l'esercizio e' gia' stato
  /// allenato — il carico dell'ultima volta, cosi' la lista dice qualcosa
  /// invece di essere solo un elenco di nomi.
  Widget _exerciseTile(
      BuildContext context, AppState state, LibraryExercise ex) {
    final progress = state.getProgressData(ex.name);
    final lastWeight =
        progress.isNotEmpty ? progress.last['maxWeight'] as double : null;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      onTap: () => _showActions(context, state, ex),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ex.name,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: kText)),
                if (ex.primaryMuscles.isNotEmpty ||
                    ex.secondaryMuscles.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 3,
                      children: [
                        ...ex.primaryMuscles.map((id) {
                          final m = getMuscleGroup(id);
                          if (m == null) return const SizedBox.shrink();
                          return MuscleTag(label: m.name(S.lang), primary: true);
                        }),
                        ...ex.secondaryMuscles.map((id) {
                          final m = getMuscleGroup(id);
                          if (m == null) return const SizedBox.shrink();
                          return MuscleTag(
                              label: m.name(S.lang), primary: false);
                        }),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (lastWeight != null)
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: kSurface2,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '${formatWeight(lastWeight)} kg',
                style: TextStyle(
                    fontSize: 12, color: kText2, fontWeight: FontWeight.w600),
              ),
            ),
          Icon(Icons.more_horiz, color: kText3, size: 20),
        ],
      ),
    );
  }

  void _showActions(BuildContext context, AppState state, LibraryExercise ex) {
    showAppSheet(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetTitle(ex.name,
              subtitle: ex.category.isNotEmpty ? ex.category : null),
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(Icons.trending_up, color: kAccent),
            title: Text(S.get('view_progress'), style: TextStyle(color: kText)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExerciseProgressScreen(exName: ex.name),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.edit_outlined, color: kAccent),
            title: Text(S.get('edit'), style: TextStyle(color: kText)),
            onTap: () {
              Navigator.pop(context);
              _showExerciseDialog(context, state, ex);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: kRed),
            title: Text(S.get('delete'), style: const TextStyle(color: kRed)),
            onTap: () async {
              Navigator.pop(context);
              final ok = await confirmDialog(
                context,
                title: '${S.get('delete_exercise')} ${ex.name}?',
                confirmText: S.get('delete'),
                destructive: true,
              );
              if (ok) state.removeFromLibrary(ex.id);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showExerciseDialog(
      BuildContext context, AppState state, LibraryExercise? existing) {
    showAppSheet(
      context,
      child: ExerciseEditorSheet(state: state, existing: existing),
    );
  }
}

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
  late TextEditingController _catCtrl;
  late Set<String> _primaryMuscles;
  late Set<String> _secondaryMuscles;
  final categories = [
    'Petto',
    'Schiena',
    'Gambe',
    'Spalle',
    'Bicipiti',
    'Tricipiti',
    'Core'
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: widget.existing?.name ?? widget.initialName ?? '');
    _catCtrl = TextEditingController(text: widget.existing?.category ?? '');
    _primaryMuscles = Set.from(widget.existing?.primaryMuscles ?? []);
    _secondaryMuscles = Set.from(widget.existing?.secondaryMuscles ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _catCtrl.dispose();
    super.dispose();
  }

  void _toggleMuscle(String id, bool isPrimary) {
    setState(() {
      if (isPrimary) {
        if (_primaryMuscles.contains(id)) {
          _primaryMuscles.remove(id);
        } else {
          _primaryMuscles.add(id);
          _secondaryMuscles.remove(id);
        }
      } else {
        if (_secondaryMuscles.contains(id)) {
          _secondaryMuscles.remove(id);
        } else {
          _secondaryMuscles.add(id);
          _primaryMuscles.remove(id);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          Text(
            widget.existing != null
                ? S.get('edit_exercise')
                : S.get('new_exercise'),
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            autofocus: widget.existing == null,
            decoration: InputDecoration(labelText: S.get('exercise_name')),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _catCtrl,
            decoration: InputDecoration(labelText: S.get('category_optional')),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: categories
                .map((c) => GestureDetector(
                      onTap: () {
                        _catCtrl.text = c;
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: _catCtrl.text == c
                              ? kAccent.withValues(alpha: 0.15)
                              : kSurface2,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _catCtrl.text == c
                                  ? kAccent
                                  : Colors.transparent),
                        ),
                        child: Text(c,
                            style: TextStyle(
                                fontSize: 12,
                                color: _catCtrl.text == c ? kAccent : kText2)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          Text(S.get('primary_muscles'),
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: kText)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: allMuscleGroups.map((m) {
              final selected = _primaryMuscles.contains(m.id);
              return GestureDetector(
                onTap: () => _toggleMuscle(m.id, true),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected
                        ? kAccent.withValues(alpha: 0.2)
                        : kSurface2,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: selected ? kAccent : Colors.transparent),
                  ),
                  child: Text(
                    m.name(S.lang),
                    style: TextStyle(
                        fontSize: 12, color: selected ? kAccent : kText2),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text(S.get('secondary_muscles'),
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: kText)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: allMuscleGroups.map((m) {
              final selected = _secondaryMuscles.contains(m.id);
              final isPrimary = _primaryMuscles.contains(m.id);
              return GestureDetector(
                onTap: isPrimary ? null : () => _toggleMuscle(m.id, false),
                child: Opacity(
                  opacity: isPrimary ? 0.3 : 1.0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected
                          ? kAccent2.withValues(alpha: 0.2)
                          : kSurface2,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: selected ? kAccent2 : Colors.transparent),
                    ),
                    child: Text(
                      m.name(S.lang),
                      style: TextStyle(
                          fontSize: 12, color: selected ? kAccent2 : kText2),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          ElevatedButton(
            onPressed: () {
              final name = _nameCtrl.text.trim();
              if (name.isEmpty) return;
              var saved = true;
              if (widget.existing != null) {
                saved = widget.state.updateLibraryExercise(
                  widget.existing!.id,
                  name,
                  _catCtrl.text.trim(),
                  primaryMuscles: _primaryMuscles.toList(),
                  secondaryMuscles: _secondaryMuscles.toList(),
                );
              } else {
                widget.state.addToLibrary(
                  name,
                  _catCtrl.text.trim(),
                  primaryMuscles: _primaryMuscles.toList(),
                  secondaryMuscles: _secondaryMuscles.toList(),
                );
              }
              if (saved) {
                Navigator.pop(context);
                widget.onSaved?.call(name);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      S.lang == 'it'
                          ? 'Nome non valido o già presente in libreria.'
                          : 'Invalid name or already in library.',
                    ),
                    backgroundColor: kRed,
                  ),
                );
              }
            },
            child: Text(
                widget.existing != null ? S.get('update') : S.get('save_exercise')),
          ),
        ],
      ),
    );
  }
}
