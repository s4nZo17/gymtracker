// lib/widgets/exercise_block.dart
//
// Un esercizio dentro una sessione: nome, recupero, nota, righe delle serie e
// "+ Aggiungi serie". E' lo STESSO blocco in Oggi e in una sessione dello
// Storico: prima erano due implementazioni diverse (card con 4 bottoni in
// Oggi, riga con 5 icone nello Storico) per fare le stesse cose.
//
// Le azioni meno frequenti (nota, recupero, progressi, rinomina, elimina)
// stanno in un menu con le voci scritte, non in una fila di icone.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/models.dart';
import '../screens/progress_screen.dart';
import '../services/app_state.dart';
import '../theme.dart';
import 'series_sheet.dart';
import 'widgets.dart';

class ExerciseBlock extends StatelessWidget {
  final WorkoutSession session;
  final int exIdx;

  /// true per la sessione in corso: mostra il recupero "ereditato" dall'ultima
  /// volta e la nota precedente come promemoria.
  final bool live;

  const ExerciseBlock({
    super.key,
    required this.session,
    required this.exIdx,
    this.live = false,
  });

  void _openSeriesSheet(
    BuildContext context,
    AppState state,
    ExerciseLog exercise, {
    int? seriesIndex,
  }) {
    final editSeries =
        seriesIndex == null ? null : exercise.series[seriesIndex];

    SeriesSheet.show(
      context,
      exerciseName: exercise.name,
      seriesNumber:
          seriesIndex == null ? exercise.series.length + 1 : seriesIndex + 1,
      history: state.historyFor(session, exercise.name),
      currentDayName: state.dayNameOf(session),
      bestSeries: state.getBestSeriesEver(exercise.name),
      editSeries: editSeries,
      dateFormat: state.prefs.dateFormat,
      onSave: (series) {
        if (seriesIndex == null) {
          state.addSeriesToSession(session, exIdx, series);
        } else {
          state.updateSeriesInSession(session, exIdx, seriesIndex, series);
        }
      },
    );
  }

  Future<void> _editNote(BuildContext context, AppState state,
      ExerciseLog ex, String? lastNote) async {
    final text =
        await showNoteEditor(context, current: ex.note, previous: lastNote);
    if (text == null) return;
    state.updateExerciseNoteInSession(session, exIdx, text);
  }

  Future<void> _editRest(
      BuildContext context, AppState state, int? current) async {
    final picked = await RestPickerDialog.show(context, initial: current);
    if (picked == null) return;
    state.updateExerciseRestInSession(
        session, exIdx, picked == 0 ? null : picked);
  }

  Future<void> _rename(
      BuildContext context, AppState state, ExerciseLog ex) async {
    final controller = TextEditingController(text: ex.name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.get('rename')),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: kText),
          decoration: InputDecoration(hintText: S.get('exercise_name')),
          onSubmitted: (v) => Navigator.pop(dialogContext, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(S.get('cancel'), style: TextStyle(color: kText2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(S.get('save')),
          ),
        ],
      ),
    );
    if (name == null || !context.mounted) return;
    final ok = state.updateExerciseNameInSession(session, exIdx, name);
    if (!ok) {
      showAppSnack(context, S.get('rename_invalid'), error: true);
    }
  }

  void _delete(BuildContext context, AppState state, ExerciseLog ex) {
    // Niente conferma: si elimina e si puo' annullare. Prima c'erano tutte e
    // due le cose, una di troppo.
    final backup = ExerciseLog.fromJson(ex.toJson());
    state.removeExerciseFromSession(session, exIdx);
    showAppSnack(
      context,
      S.get('exercise_deleted'),
      onUndo: () => state.insertExerciseInSession(session, exIdx, backup),
    );
  }

  void _showMenu(BuildContext context, AppState state, ExerciseLog ex,
      String? lastNote, int? rest) {
    showActionSheet(
      context,
      title: ex.name,
      actions: [
        SheetAction(
          icon: Icons.notes,
          label: ex.note == null ? S.get('add_note_action') : S.get('edit_note'),
          onTap: () => _editNote(context, state, ex, lastNote),
        ),
        SheetAction(
          icon: Icons.timer_outlined,
          label: S.get('set_rest'),
          onTap: () => _editRest(context, state, rest),
        ),
        SheetAction(
          icon: Icons.show_chart,
          label: S.get('view_progress'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExerciseProgressScreen(exName: ex.name),
            ),
          ),
        ),
        SheetAction(
          icon: Icons.edit_outlined,
          label: S.get('rename'),
          onTap: () => _rename(context, state, ex),
        ),
        SheetAction(
          icon: Icons.delete_outline,
          label: S.get('delete'),
          destructive: true,
          onTap: () => _delete(context, state, ex),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (exIdx >= session.exercises.length) return const SizedBox.shrink();
    final ex = session.exercises[exIdx];

    final history = live ? state.historyFor(session, ex.name) : null;
    final lastNote = history?.relevantNote;
    final inheritedRest = live && ex.restSeconds == null
        ? state.getLastRestForExercise(ex.name)
        : null;
    final rest = ex.restSeconds ?? inheritedRest;

    final count = ex.targetSeries != null
        ? '${ex.series.length}/${ex.targetSeries}'
        : '${ex.series.length}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(kGapPage, 12, kGapPage - 6, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Intestazione: nome + conteggio, recupero, menu
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _showMenu(context, state, ex, lastNote, rest),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: ex.name),
                        TextSpan(
                          text: '  $count',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: kText3,
                            fontFeatures: kTabular,
                          ),
                        ),
                      ],
                    ),
                    style: T.title,
                  ),
                ),
                RestBadge(
                  seconds: rest,
                  inherited: ex.restSeconds == null,
                  onTap: () => _editRest(context, state, rest),
                ),
                IconButton(
                  onPressed: () => _showMenu(context, state, ex, lastNote, rest),
                  icon: Icon(Icons.more_horiz, color: kText3, size: 20),
                  visualDensity: VisualDensity.compact,
                  tooltip: S.get('more'),
                ),
              ],
            ),
          ),

          // Nota di oggi, o quella dell'ultima volta come promemoria.
          if (ex.note != null || lastNote != null)
            Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 4),
              child: GestureDetector(
                onTap: () => _editNote(context, state, ex, lastNote),
                child: Text(
                  ex.note ?? lastNote!,
                  style: T.meta.copyWith(
                    color: ex.note != null ? kText2 : kText3,
                    fontStyle:
                        ex.note != null ? FontStyle.normal : FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Column(
              children: [
                ...ex.series.asMap().entries.map((e) {
                  final s = e.value;
                  final i = e.key;
                  return SeriesRow(
                    index: i,
                    series: s,
                    onTap: () =>
                        _openSeriesSheet(context, state, ex, seriesIndex: i),
                    onDelete: () {
                      state.removeSeriesFromSession(session, exIdx, i);
                      showAppSnack(
                        context,
                        S.get('series_deleted'),
                        onUndo: () =>
                            state.insertSeriesInSession(session, exIdx, i, s),
                      );
                    },
                  );
                }),
                // Serie previste dal giorno e non ancora fatte: promemoria,
                // non dati finti nello storico.
                ...List.generate(
                  ex.pendingTargetSeries,
                  (offset) => PendingSeriesRow(
                    index: ex.series.length + offset,
                    onTap: () => _openSeriesSheet(context, state, ex),
                  ),
                ),
              ],
            ),
          ),

          // Azione principale del blocco.
          TextButton.icon(
            onPressed: () => _openSeriesSheet(context, state, ex),
            style: TextButton.styleFrom(
              foregroundColor: kAccent,
              padding: const EdgeInsets.only(right: 12),
              minimumSize: const Size(0, 44),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.add, size: 19),
            label: Text(S.get('add_series_short'),
                style: const TextStyle(fontSize: 14.5)),
          ),
        ],
      ),
    );
  }
}
