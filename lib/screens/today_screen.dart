// lib/screens/today_screen.dart
//
// Oggi: l'allenamento in corso.
// - Header: giorno della settimana, data e giorno preimpostato in una riga.
// - Sessione vuota: i giorni preimpostati sono gia' li', un tocco e si parte.
// - Sessione piena: un blocco per esercizio (lo stesso dello Storico).
// - "Nuovo giorno" compare solo quando c'e' davvero qualcosa da chiudere.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/app_tour.dart';
import '../widgets/exercise_block.dart';
import '../widgets/session_day_picker.dart';
import '../widgets/widgets.dart';
import 'exercise_picker_screen.dart';
import 'templates_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  /// Il FAB si ritira mentre scorri in giu' (cosi' non copre l'ultimo
  /// "Aggiungi serie") e ricompare appena risali.
  bool _fabVisible = true;

  bool _onScroll(UserScrollNotification n) {
    if (n.direction == ScrollDirection.reverse && _fabVisible) {
      setState(() => _fabVisible = false);
    } else if (n.direction == ScrollDirection.forward && !_fabVisible) {
      setState(() => _fabVisible = true);
    }
    return false;
  }

  Future<void> _newDay(BuildContext context, AppState state) async {
    final session = state.todaySession;
    final hasSeries = session.exercises.any((ex) => ex.series.isNotEmpty);

    if (hasSeries && session.rating == null) {
      // Il voto si chiede alla chiusura, una volta sola. Chiudere il dialog
      // (tap fuori) annulla tutto; "Salta" chiude senza voto.
      final rating = await RatingDialog.show(context,
          confirmText: S.get('save_and_close'));
      if (rating == null) return;
      if (rating > 0) state.setSessionRating(session, rating);
    } else {
      final ok = await confirmDialog(
        context,
        title: '${S.get('new_day')}?',
        message: S.get('new_day_confirm'),
      );
      if (!ok) return;
    }
    state.startNewDay();
    if (context.mounted && hasSeries) {
      showAppSnack(context, S.get('workout_saved'));
    }
  }

  void _openPicker(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExercisePickerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final session = state.todaySession;
        final locale = state.prefs.language == 'en' ? 'en_US' : 'it_IT';
        final now = DateTime.now();
        final isEmpty = session.exercises.isEmpty;
        // Una sessione vuota diventa quella di oggi appena ci aggiungi
        // qualcosa: intestarla col giorno vecchio confondeva.
        final sessionDate =
            isEmpty ? now : (DateTime.tryParse(session.date) ?? now);
        final isStale = !isEmpty && !DateUtils.isSameDay(sessionDate, now);
        final weekday = DateFormat('EEEE', locale).format(sessionDate);
        final dayMonth = DateFormat('d MMMM', locale).format(sessionDate);
        final dayName = state.dayNameOf(session);
        final showDay = dayName != null || state.templates.isNotEmpty;

        return Scaffold(
          backgroundColor: kBg,
          body: NotificationListener<UserScrollNotification>(
            onNotification: _onScroll,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: PageHeader(
                    title: weekday[0].toUpperCase() + weekday.substring(1),
                    subtitleWidget: Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(dayMonth, style: T.meta),
                        if (showDay && !isEmpty) ...[
                          Text('·', style: T.meta.copyWith(color: kText3)),
                          // Il giorno preimpostato rende confrontabili i
                          // numeri: si vede e si cambia da qui.
                          DayChip(
                            dayName: dayName,
                            onTap: () =>
                                showSessionDayPicker(context, state, session),
                          ),
                        ],
                        if (session.rating != null) ...[
                          Text('·', style: T.meta.copyWith(color: kText3)),
                          RatingBadge(session.rating!),
                        ],
                      ],
                    ),
                    trailing: isEmpty
                        ? null
                        : HeaderAction(
                            key: TourKeys.newDayButton,
                            label: S.get('new_day'),
                            onTap: () => _newDay(context, state),
                          ),
                  ),
                ),

                // Allenamento rimasto aperto da un altro giorno: lo si dice,
                // senza chiuderlo da soli (si puo' finire dopo mezzanotte).
                if (isStale)
                  SliverToBoxAdapter(
                    child: _StaleBanner(
                      onNewDay: () => _newDay(context, state),
                    ),
                  ),

                if (isEmpty)
                  SliverToBoxAdapter(
                    child: _EmptyToday(
                      state: state,
                      onAddExercise: () => _openPicker(context),
                    ),
                  )
                else ...[
                  SliverList.separated(
                    itemCount: session.exercises.length,
                    itemBuilder: (_, i) => ExerciseBlock(
                      // La chiave per nome tiene lo stato giusto quando un
                      // esercizio viene eliminato o reinserito.
                      key: ValueKey('today-${session.exercises[i].name}'),
                      session: session,
                      exIdx: i,
                      live: true,
                    ),
                    separatorBuilder: (_, __) => const Divider(
                        indent: kGapPage, endIndent: kGapPage, height: 12),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          kGapPage - 8, 18, kGapPage, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          key: TourKeys.templatesRow,
                          onPressed: () => showTemplateSheet(context, state),
                          style: TextButton.styleFrom(
                              foregroundColor: kText3),
                          icon: const Icon(Icons.bolt_outlined, size: 18),
                          label: Text(S.get('load_template'),
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ),
                  ),
                ],

                const SliverToBoxAdapter(
                    child: SizedBox(height: kBottomSafeSpace)),
              ],
            ),
          ),
          floatingActionButton: AnimatedSlide(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            offset: _fabVisible ? Offset.zero : const Offset(0, 1.6),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: _fabVisible ? 1 : 0,
              child: FloatingActionButton.extended(
                key: TourKeys.addExerciseFab,
                heroTag: 'today-fab',
                onPressed: () => _openPicker(context),
                backgroundColor: kAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                highlightElevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kRadiusPill)),
                icon: const Icon(Icons.add, size: 22),
                label: Text(
                  S.get('exercise_short'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── SESSIONE APERTA DA UN ALTRO GIORNO ─────────────────────────────────────
class _StaleBanner extends StatelessWidget {
  final VoidCallback onNewDay;
  const _StaleBanner({required this.onNewDay});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(kGapPage, 6, kGapPage, 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        decoration: BoxDecoration(
          color: kSurface2,
          borderRadius: BorderRadius.circular(kRadiusControl + 2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(S.get('stale_session'),
                  style: T.meta.copyWith(height: 1.35)),
            ),
            TextButton(
              onPressed: onNewDay,
              style: TextButton.styleFrom(foregroundColor: kAccent),
              child: Text(S.get('start_today')),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── OGGI VUOTO ─────────────────────────────────────────────────────────────
// Le due strade per iniziare sono visibili subito: i giorni preimpostati in
// elenco (un tocco e si caricano) oppure il "+ Esercizio".
class _EmptyToday extends StatelessWidget {
  final AppState state;
  final VoidCallback onAddExercise;

  const _EmptyToday({required this.state, required this.onAddExercise});

  @override
  Widget build(BuildContext context) {
    final templates = state.templates;

    if (templates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            EmptyState(
              title: S.get('ready_to_train'),
              subtitle: S.get('ready_to_train_sub'),
              actionLabel: S.get('add_exercise_action'),
              onAction: onAddExercise,
            ),
            TextButton(
              key: TourKeys.templatesRow,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TemplatesScreen()),
              ),
              style: TextButton.styleFrom(foregroundColor: kText3),
              child: Text(S.get('create_template_hint'),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );
    }

    return Column(
      key: TourKeys.templatesRow,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          S.get('start_from_template'),
          trailing: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TemplatesScreen()),
            ),
            child: Text(S.get('manage'),
                style: T.label.copyWith(color: kText2)),
          ),
        ),
        const Divider(indent: kGapPage, endIndent: kGapPage),
        ...templates.map(
          (t) => ListRow(
            title: t.name,
            subtitle: _templateSummary(t),
            subtitleMaxLines: 1,
            trailing: RowChevron(),
            onTap: () {
              state.applyTemplate(t);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(kGapPage, 18, kGapPage, 0),
          child: Text(S.get('or_add_exercise'), style: T.label),
        ),
      ],
    );
  }

  String _templateSummary(WorkoutTemplate t) {
    final names = t.exerciseNames;
    final shown = names.take(3).join(', ');
    final extra = names.length > 3 ? ' +${names.length - 3}' : '';
    return '$shown$extra';
  }
}
