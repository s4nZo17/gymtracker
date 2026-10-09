// lib/screens/session_screen.dart
//
// Una sessione passata, aperta dallo Storico. Stessi blocchi esercizio di
// Oggi, stesso selettore esercizi, stesso sheet serie: si modifica come
// l'allenamento in corso. Le azioni sulla sessione intera (data, giorno,
// voto, eliminazione) stanno nel menu in alto.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/exercise_block.dart';
import '../widgets/session_day_picker.dart';
import '../widgets/widgets.dart';
import 'exercise_picker_screen.dart';

class SessionScreen extends StatelessWidget {
  final WorkoutSession session;
  const SessionScreen({super.key, required this.session});

  Future<void> _editDate(BuildContext context, AppState state) async {
    final current = DateTime.tryParse(session.date) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    state.updateSessionDate(
        session, picked.toIso8601String().split('T').first);
  }

  Future<void> _editRating(BuildContext context, AppState state) async {
    final rating = await RatingDialog.show(context, initial: session.rating);
    if (rating == null || rating == 0) return;
    state.setSessionRating(session, rating);
  }

  void _delete(BuildContext context, AppState state) {
    final messenger = ScaffoldMessenger.of(context);
    final index = state.removeSession(session);
    Navigator.pop(context);
    if (index < 0) return;
    showAppSnackOn(
      messenger,
      S.get('workout_deleted'),
      onUndo: () => state.insertSession(index, session),
    );
  }

  void _showMenu(BuildContext context, AppState state) {
    showActionSheet(
      context,
      title: S.get('workout'),
      actions: [
        SheetAction(
          icon: Icons.calendar_today_outlined,
          label: S.get('edit_date'),
          onTap: () => _editDate(context, state),
        ),
        if (state.templates.isNotEmpty || !session.isFreeWorkout)
          SheetAction(
            icon: Icons.bolt_outlined,
            label: S.get('session_day'),
            onTap: () => showSessionDayPicker(context, state, session),
          ),
        SheetAction(
          icon: Icons.favorite_border,
          label: S.get('rate_workout_action'),
          onTap: () => _editRating(context, state),
        ),
        SheetAction(
          icon: Icons.delete_outline,
          label: S.get('delete_workout'),
          destructive: true,
          onTap: () => _delete(context, state),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        // La sessione puo' sparire (eliminata altrove): niente da mostrare.
        if (!state.workouts.contains(session)) {
          return Scaffold(backgroundColor: kBg, appBar: AppBar());
        }
        final locale = state.prefs.language == 'en' ? 'en_US' : 'it_IT';
        final date = DateTime.tryParse(session.date) ?? DateTime.now();
        final title = DateFormat('EEEE d MMMM', locale).format(date);
        final dayName = state.dayNameOf(session);

        return ScaffoldMessenger(
          child: Scaffold(
            backgroundColor: kBg,
            appBar: AppBar(
              actions: [
                IconButton(
                  onPressed: () => _showMenu(context, state),
                  icon: const Icon(Icons.more_horiz),
                  tooltip: S.get('more'),
                ),
                const SizedBox(width: 6),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.only(bottom: kBottomSafeSpace),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(kGapPage, 0, kGapPage, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title[0].toUpperCase() + title.substring(1),
                          style: T.display.copyWith(fontSize: 26)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(DateFormat('yyyy', locale).format(date),
                              style: T.meta),
                          if (dayName != null || state.templates.isNotEmpty) ...[
                            Text('·', style: T.meta.copyWith(color: kText3)),
                            DayChip(
                              dayName: dayName,
                              onTap: () =>
                                  showSessionDayPicker(context, state, session),
                            ),
                          ],
                          if (session.rating != null) ...[
                            Text('·', style: T.meta.copyWith(color: kText3)),
                            GestureDetector(
                              onTap: () => _editRating(context, state),
                              child: RatingBadge(session.rating!),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (session.exercises.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: EmptyState(title: S.get('no_exercises_in_session')),
                  ),
                for (var i = 0; i < session.exercises.length; i++) ...[
                  if (i > 0)
                    const Divider(
                        indent: kGapPage, endIndent: kGapPage, height: 12),
                  ExerciseBlock(
                    key: ValueKey('past-${session.exercises[i].name}'),
                    session: session,
                    exIdx: i,
                  ),
                ],
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'session-fab',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExercisePickerScreen(session: session),
                ),
              ),
              backgroundColor: kAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              highlightElevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kRadiusPill)),
              icon: const Icon(Icons.add, size: 22),
              label: Text(S.get('exercise_short'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        );
      },
    );
  }
}
