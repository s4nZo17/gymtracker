// lib/widgets/workout_flow.dart
//
// I due flussi che chiudono l'allenamento in corso, in un posto solo:
//  - finishWorkoutFlow: il tasto "Finisci" (in alto e in fondo a Oggi) e
//    "Inizia oggi" sull'avviso della sessione rimasta aperta.
//  - loadTemplateFlow: caricare un giorno preimpostato. Con un allenamento in
//    corso non si aggiunge piu' in coda: si chiede cosa farne (salvarlo, non
//    salvarlo, continuarlo) e poi si parte da una giornata nuova.
//
// Ogni chiusura si puo' annullare dalla snackbar.

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import 'widgets.dart';

bool _hasSeries(WorkoutSession s) => s.exercises.any((e) => e.series.isNotEmpty);

void _snackWithUndo(BuildContext context, AppState state, String message,
    FinishedWorkout? done) {
  if (!context.mounted) return;
  showAppSnack(
    context,
    message,
    onUndo: done == null ? null : () => state.undoFinish(done),
  );
}

/// "Finisci allenamento": voto se ci sono serie, conferma se non ce ne sono
/// (in quel caso non si salva niente), poi giornata nuova.
Future<void> finishWorkoutFlow(BuildContext context, AppState state) async {
  final session = state.todaySession;
  if (session.exercises.isEmpty) return;

  if (_hasSeries(session)) {
    final mood = await RatingDialog.show(
      context,
      initial: session.rating,
      confirmText: S.get('save_and_close'),
    );
    if (mood == null) return; // chiuso col tocco fuori: non succede niente
    final done = state.finishWorkout(mood: mood > 0 ? mood : null);
    if (context.mounted) {
      _snackWithUndo(context, state, S.get('workout_saved'), done);
    }
  } else {
    final ok = await confirmDialog(
      context,
      title: S.get('finish_empty_title'),
      message: S.get('finish_empty_desc'),
      confirmText: S.get('finish'),
    );
    if (!ok) return;
    final done = state.finishWorkout(save: false);
    if (context.mounted) {
      _snackWithUndo(context, state, S.get('workout_discarded'), done);
    }
  }
}

/// Carica un giorno preimpostato nell'allenamento di oggi.
///
/// - sessione vuota: lo carica e basta;
/// - esercizi senza serie: chiede se sostituirli (non c'e' niente da salvare);
/// - con serie: Salva e inizia / Non salvare / Continua.
Future<void> loadTemplateFlow(
  BuildContext context,
  AppState state,
  WorkoutTemplate template,
) async {
  final session = state.todaySession;

  if (session.exercises.isEmpty) {
    state.applyTemplate(template);
    return;
  }

  if (!_hasSeries(session)) {
    final ok = await confirmDialog(
      context,
      title: S.get('replace_exercises_title').replaceAll('{day}', template.name),
      message: S.get('replace_exercises_desc'),
      confirmText: S.get('replace'),
    );
    if (!ok) return;
    final done = state.finishWorkout(save: false, next: template);
    if (context.mounted) {
      _snackWithUndo(context, state,
          S.get('day_loaded').replaceAll('{day}', template.name), done);
    }
    return;
  }

  final choice = await showChoiceDialog<_Switch>(
    context,
    title: S.get('workout_in_progress'),
    message: S.get('workout_in_progress_desc').replaceAll('{day}', template.name),
    choices: [
      ChoiceAction(_Switch.save, S.get('save_and_start'), primary: true),
      ChoiceAction(_Switch.discard, S.get('dont_save'), destructive: true),
      ChoiceAction(_Switch.keep, S.get('keep_going')),
    ],
  );
  if (choice == null || choice == _Switch.keep || !context.mounted) return;

  FinishedWorkout? done;
  if (choice == _Switch.save) {
    final mood = await RatingDialog.show(
      context,
      initial: session.rating,
      confirmText: S.get('save_and_start_short'),
    );
    if (mood == null) return;
    done = state.finishWorkout(mood: mood > 0 ? mood : null, next: template);
  } else {
    done = state.finishWorkout(save: false, next: template);
  }
  if (context.mounted) {
    _snackWithUndo(
      context,
      state,
      (choice == _Switch.save ? S.get('saved_and_loaded') : S.get('day_loaded'))
          .replaceAll('{day}', template.name),
      done,
    );
  }
}

enum _Switch { save, discard, keep }

// ─── DIALOG A SCELTA MULTIPLA ───────────────────────────────────────────────

class ChoiceAction<V> {
  final V value;
  final String label;
  final bool primary;
  final bool destructive;
  const ChoiceAction(this.value, this.label,
      {this.primary = false, this.destructive = false});
}

/// Dialog con piu' di due scelte, una per riga a tutta larghezza: tre bottoni
/// testuali affiancati non ci stanno e non si capisce quale sia il principale.
Future<V?> showChoiceDialog<V>(
  BuildContext context, {
  required String title,
  String? message,
  required List<ChoiceAction<V>> choices,
}) {
  return showDialog<V>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final c in choices)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: c.primary
                    ? ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, c.value),
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 48)),
                        child: Text(c.label),
                      )
                    : TextButton(
                        onPressed: () => Navigator.pop(dialogContext, c.value),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          foregroundColor: c.destructive ? kRed : kText2,
                        ),
                        child: Text(c.label),
                      ),
              ),
          ],
        ),
      ],
    ),
  );
}
