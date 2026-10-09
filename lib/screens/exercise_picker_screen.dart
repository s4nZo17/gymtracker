// lib/screens/exercise_picker_screen.dart
//
// Aggiunta esercizio al giorno: ricerca + categorie + lista con "ultima volta".
// 2.0: la schermata resta aperta dopo l'aggiunta (spunta immediata), cosi
// puoi aggiungere piu esercizi di fila senza rientrare ogni volta.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/muscle_groups.dart';
import '../l10n/strings.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import 'library_screen.dart';

class ExercisePickerScreen extends StatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  State<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends State<ExercisePickerScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _selectedCat = 'Tutti';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final categories = [
          'Tutti',
          ...{...state.library.map((e) => e.category).where((c) => c.isNotEmpty)}
        ];

        final filtered = state.library.where((ex) {
          final matchSearch =
              ex.name.toLowerCase().contains(_search.toLowerCase());
          final matchCat = _selectedCat == 'Tutti' || ex.category == _selectedCat;
          return matchSearch && matchCat;
        }).toList();

        final grouped = <String, List<dynamic>>{};
        for (final ex in filtered) {
          final cat = ex.category.isNotEmpty ? ex.category : 'Altro';
          grouped.putIfAbsent(cat, () => []).add(ex);
        }

        return Scaffold(
          backgroundColor: kBg,
          appBar: AppBar(
            title: Text(S.get('add_exercise')),
            actions: [
              // 2.0: "Nuovo" apre subito l'editor (niente giro dalla Libreria)
              // e al salvataggio l'esercizio entra direttamente nell'allenamento.
              TextButton.icon(
                onPressed: () => showAppSheet(
                  context,
                  child: ExerciseEditorSheet(
                    state: state,
                    initialName: _search.trim(),
                    onSaved: (name) {
                      state.addExerciseToToday(name);
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$name — ${S.get('added')}'),
                          duration: const Duration(milliseconds: 1500),
                        ),
                      );
                    },
                  ),
                ),
                icon: Icon(Icons.add, color: kAccent, size: 18),
                label: Text(S.get('new'),
                    style: TextStyle(
                        color: kAccent, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(kGapPage, 4, kGapPage, 0),
                child: AppSearchField(
                  hint: S.get('search_exercise'),
                  value: _search,
                  onChanged: (v) => setState(() {
                    _search = v;
                    _searchCtrl.text = v;
                  }),
                ),
              ),
              SizedBox(
                height: 54,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => CategoryChip(
                    label: categories[i],
                    selected: _selectedCat == categories[i],
                    onTap: () => setState(() => _selectedCat = categories[i]),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 40, color: kText3),
                            const SizedBox(height: 12),
                            Text(S.get('no_exercise_found'),
                                style:
                                    TextStyle(fontSize: 15, color: kText2)),
                            const SizedBox(height: 18),
                            if (_search.trim().isNotEmpty)
                              FilledButton.icon(
                                onPressed: () => showAppSheet(
                                  context,
                                  child: ExerciseEditorSheet(
                                    state: state,
                                    initialName: _search.trim(),
                                    onSaved: (name) {
                                      state.addExerciseToToday(name);
                                      _searchCtrl.clear();
                                      setState(() => _search = '');
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '$name — ${S.get('added')}'),
                                          duration: const Duration(
                                              milliseconds: 1500),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: kAccent,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.add, size: 18),
                                label: Text(
                                    '${S.get('create')} "${_search.trim()}"'),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount:
                            _selectedCat == 'Tutti' ? grouped.keys.length : 1,
                        itemBuilder: (context, groupIdx) {
                          final catName = _selectedCat == 'Tutti'
                              ? grouped.keys.elementAt(groupIdx)
                              : _selectedCat;
                          final exercises = grouped[catName] ?? filtered;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_selectedCat == 'Tutti') SectionTitle(catName),
                              ...exercises.map((ex) {
                                // "Ultima volta" pertinente: se il giorno di
                                // oggi ha un precedente si mostra quello,
                                // altrimenti l'ultima assoluta col suo giorno.
                                final history =
                                    state.historyForToday(ex.name, limit: 1);
                                final lastHit = history.sameDay ??
                                    (history.anyDay.isEmpty
                                        ? null
                                        : history.anyDay.first);
                                final alreadyAdded = state
                                    .todaySession.exercises
                                    .any((e) =>
                                        e.name.trim().toLowerCase() ==
                                        ex.name.trim().toLowerCase());

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 3),
                                  child: AppCard(
                                    padding: const EdgeInsets.all(14),
                                    borderColor: alreadyAdded
                                        ? kAccent.withValues(alpha: 0.35)
                                        : null,
                                    onTap: alreadyAdded
                                        ? null
                                        : () {
                                            state.addExerciseToToday(ex.name);
                                            ScaffoldMessenger.of(context)
                                                .hideCurrentSnackBar();
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    '${ex.name} — ${S.get('added')}'),
                                                duration: const Duration(
                                                    milliseconds: 1200),
                                              ),
                                            );
                                          },
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                ex.name,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: alreadyAdded
                                                      ? kAccent
                                                      : kText,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                lastHit == null
                                                    ? S.get('no_previous')
                                                    : '${lastHit.dayName ?? S.get('last_time')}: ${lastHit.series.map((s) => s.summary).join(' / ')}',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: kText2),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (ex.primaryMuscles.isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 5),
                                                  child: Wrap(
                                                    spacing: 4,
                                                    runSpacing: 3,
                                                    children: [
                                                      ...ex.primaryMuscles
                                                          .map((id) {
                                                        final m =
                                                            getMuscleGroup(id);
                                                        if (m == null) {
                                                          return const SizedBox
                                                              .shrink();
                                                        }
                                                        return MuscleTag(
                                                            label:
                                                                m.name(S.lang),
                                                            primary: true);
                                                      }),
                                                      ...ex.secondaryMuscles
                                                          .map((id) {
                                                        final m =
                                                            getMuscleGroup(id);
                                                        if (m == null) {
                                                          return const SizedBox
                                                              .shrink();
                                                        }
                                                        return MuscleTag(
                                                            label:
                                                                m.name(S.lang),
                                                            primary: false);
                                                      }),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          alreadyAdded
                                              ? Icons.check_circle
                                              : Icons.add_circle_outline,
                                          color: alreadyAdded
                                              ? kAccent
                                              : kText3,
                                          size: 22,
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
            ],
          ),
        );
      },
    );
  }
}
