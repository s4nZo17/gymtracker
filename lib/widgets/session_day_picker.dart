// lib/widgets/session_day_picker.dart
//
// A quale giorno preimpostato appartiene una sessione. NON carica esercizi:
// etichetta soltanto. Serve in due casi: hai applicato il giorno sbagliato
// (applicarne un secondo non cambia il contesto, per non spostare i confronti
// sotto i piedi), oppure vuoi etichettare a mano una sessione partita libera.

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import 'widgets.dart';

Future<void> showSessionDayPicker(
  BuildContext context,
  AppState state,
  WorkoutSession session,
) {
  Widget option({
    required String label,
    required bool selected,
    WorkoutTemplate? template,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        borderColor: selected ? kAccent : null,
        onTap: () {
          state.setSessionTemplate(session, template);
          Navigator.pop(context);
        },
        child: Row(
          children: [
            Icon(template == null ? Icons.flash_off : Icons.flash_on,
                size: 18, color: selected ? kAccent : kText3),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: selected ? kAccent : kText,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (selected) Icon(Icons.check_circle, size: 20, color: kAccent),
          ],
        ),
      ),
    );
  }

  return showAppSheet(
    context,
    child: SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetTitle(S.get('session_day')),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              S.get('session_day_desc'),
              style: TextStyle(fontSize: 12.5, color: kText2, height: 1.4),
            ),
          ),
          ...state.templates.map((t) => option(
                label: t.name,
                selected: t.id == session.templateId,
                template: t,
              )),
          option(
            label: S.get('free_workout'),
            selected: session.isFreeWorkout,
            template: null,
          ),
        ],
      ),
    ),
  );
}
