// lib/screens/exercise_picker_screen.dart
//
// Aggiunta esercizi a una sessione: ricerca, filtri per categoria e, per ogni
// esercizio, l'ultima volta che l'hai fatto. Resta aperta dopo l'aggiunta
// (spunta immediata), cosi' puoi aggiungerne piu' di uno di fila.
//
// E' l'unico selettore dell'app: serve Oggi (default) e qualsiasi sessione
// dello Storico. Prima lo Storico aveva un suo foglio, piu' povero.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/exercise_editor_sheet.dart';
import '../widgets/widgets.dart';

class ExercisePickerScreen extends StatefulWidget {
  /// Sessione a cui aggiungere; null = l'allenamento di oggi.
  final WorkoutSession? session;

  const ExercisePickerScreen({super.key, this.session});

  @override
  State<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends State<ExercisePickerScreen> {
  String _search = '';
  String _category = '';

  WorkoutSession _target(AppState state) => widget.session ?? state.todaySession;

  void _add(AppState state, String name) {
    final added = state.addExerciseToSession(_target(state), name);
    if (added) showAppSnack(context, '$name · ${S.get('added')}');
  }

  void _createNew(AppState state) {
    showAppSheet(
      context,
      child: ExerciseEditorSheet(
        state: state,
        initialName: _search.trim().isEmpty ? null : _search.trim(),
        onSaved: (name) {
          _add(state, name);
          setState(() => _search = '');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final session = _target(state);
        final categories = <String>{
          for (final e in state.library)
            if (e.category.trim().isNotEmpty) e.category.trim(),
        }.toList()
          ..sort();

        final term = _search.trim().toLowerCase();
        final filtered = state.library.where((ex) {
          final matchSearch = term.isEmpty ||
              ex.name.toLowerCase().contains(term) ||
              ex.category.toLowerCase().contains(term);
          final matchCat = _category.isEmpty || ex.category == _category;
          return matchSearch && matchCat;
        }).toList();

        final grouped = <String, List<LibraryExercise>>{};
        for (final ex in filtered) {
          final cat =
              ex.category.isNotEmpty ? ex.category : S.get('uncategorized');
          grouped.putIfAbsent(cat, () => []).add(ex);
        }

        final added = {
          for (final e in session.exercises) e.name.trim().toLowerCase()
        };

        return Scaffold(
          backgroundColor: kBg,
          appBar: AppBar(
            title: Text(S.get('add_exercise')),
            actions: [
              TextButton(
                onPressed: () => _createNew(state),
                style: TextButton.styleFrom(foregroundColor: kAccentText),
                child: Text(S.get('new')),
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(kGapPage, 12, kGapPage, 12),
                child: AppSearchField(
                  hint: S.get('search_exercise'),
                  value: _search,
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              CategoryFilterBar(
                categories: categories,
                selected: _category,
                onChanged: (c) => setState(() => _category = c),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? EmptyState(
                        title: S.get('no_exercise_found'),
                        actionLabel: term.isEmpty
                            ? null
                            : '${S.get('create')} "${_search.trim()}"',
                        onAction: term.isEmpty ? null : () => _createNew(state),
                      )
                    : ListView(
                        padding:
                            const EdgeInsets.only(bottom: kBottomSafeSpace),
                        children: [
                          for (final entry in grouped.entries) ...[
                            SectionTitle(entry.key),
                            Block(children: [
                              for (final ex in entry.value)
                                _row(state, session, ex,
                                    added.contains(ex.name.trim().toLowerCase())),
                            ]),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(AppState state, WorkoutSession session, LibraryExercise ex,
      bool alreadyAdded) {
    // "Ultima volta" pertinente: se il giorno della sessione ha un precedente
    // si mostra quello, altrimenti l'ultima assoluta col suo giorno.
    final history = state.historyFor(session, ex.name, limit: 1);
    final lastHit = history.sameDay ??
        (history.anyDay.isEmpty ? null : history.anyDay.first);
    final subtitle = lastHit == null
        ? muscleSummary(ex)
        : lastHit.series.map((s) => s.summary).join('   ');

    return ListRow(
      title: ex.name,
      titleColor: alreadyAdded ? kText2 : null,
      subtitle: subtitle,
      subtitleMaxLines: 1,
      minHeight: 68,
      onTap: alreadyAdded ? null : () => _add(state, ex.name),
      trailing: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: alreadyAdded
            ? Icon(Icons.check, size: 22, color: kAccentText)
            : PlusIcon(size: 22),
      ),
    );
  }
}
