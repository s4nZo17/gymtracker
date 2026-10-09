// lib/widgets/session_day_picker.dart
//
// I due fogli sui giorni preimpostati, con la stessa forma:
//  - showTemplateSheet: CARICA un giorno preimpostato (via loadTemplateFlow:
//    con un allenamento in corso chiede se salvarlo e riparte da zero).
//    Con la lista di Oggi vuota e' l'unico punto da cui si applica un giorno.
//  - showSessionDayPicker: ETICHETTA soltanto una sessione. Serve quando hai
//    applicato il giorno sbagliato (applicarne un secondo non cambia il
//    contesto, per non spostare i confronti sotto i piedi) o vuoi etichettare
//    a mano una sessione partita libera.

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/models.dart';
import '../screens/templates_screen.dart';
import '../services/app_state.dart';
import '../theme.dart';
import 'widgets.dart';
import 'workout_flow.dart';

Future<void> showTemplateSheet(BuildContext context, AppState state) {
  if (state.templates.isEmpty) {
    return Navigator.push(
        context, MaterialPageRoute(builder: (_) => const TemplatesScreen()));
  }

  return showAppSheet(
    context,
    child: SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetTitle(
            S.get('templates'),
            trailing: Builder(
              builder: (sheetContext) => TextButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TemplatesScreen()),
                  );
                },
                child: Text(S.get('manage'),
                    style: TextStyle(color: kText2, fontSize: 14)),
              ),
            ),
          ),
          ...state.templates.map(
            (template) => Builder(
              builder: (sheetContext) => ListRow(
                title: template.name,
                subtitle: template.exerciseNames.join(' · '),
                subtitleMaxLines: 1,
                trailing: RowChevron(),
                onTap: () {
                  Navigator.pop(sheetContext);
                  // Con un allenamento in corso chiede cosa farne: non si
                  // aggiungono piu' esercizi in coda a quelli di oggi.
                  loadTemplateFlow(context, state, template);
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> showSessionDayPicker(
  BuildContext context,
  AppState state,
  WorkoutSession session,
) {
  Widget option(String label, bool selected, WorkoutTemplate? template) {
    return Builder(
      builder: (sheetContext) => ListRow(
        title: label,
        titleColor: template == null ? kText2 : null,
        trailing: selected
            ? Icon(Icons.check, size: 20, color: kText)
            : const SizedBox(width: 20),
        onTap: () {
          state.setSessionTemplate(session, template);
          Navigator.pop(sheetContext);
        },
      ),
    );
  }

  return showAppSheet(
    context,
    child: SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetTitle(S.get('session_day'), subtitle: S.get('session_day_desc')),
          const SizedBox(height: 4),
          ...state.templates.map(
              (t) => option(t.name, t.id == session.templateId, t)),
          option(S.get('free_workout'), session.isFreeWorkout, null),
        ],
      ),
    ),
  );
}
