// lib/screens/today_screen.dart
//
// Oggi: l'allenamento in corso.
// - Header: giorno della settimana a sinistra, data in accento a destra.
// - Sessione vuota: "GIORNI PREIMPOSTATI" in un blocco (un tocco sul giorno e
//   si parte), poi "oppure" e il bottone tratteggiato per l'allenamento
//   libero. Senza giorni, al loro posto l'invito a crearne uno.
// - Sessione piena: sopra l'etichetta col giorno (si cambia da li') e
//   "Finisci"; sotto un blocco per esercizio (lo stesso dello Storico).

import 'package:flutter/material.dart';
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
import '../widgets/workout_flow.dart';
import 'exercise_picker_screen.dart';
import 'templates_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final _scroll = ScrollController();

  /// Sessione mostrata all'ultimo build: quando cambia (Finisci, cambio di
  /// giorno, annulla) la lista riparte dall'alto. Prima restavi in fondo alla
  /// lista vecchia.
  WorkoutSession? _shownSession;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onSessionChanged(WorkoutSession session) {
    if (identical(_shownSession, session)) return;
    final first = _shownSession == null;
    _shownSession = session;
    if (first) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(0);
    });
  }

  Future<void> _editMood(BuildContext context, AppState state) async {
    final session = state.todaySession;
    final mood = await RatingDialog.show(context, initial: session.rating);
    if (mood == null || mood == 0) return;
    state.setSessionRating(session, mood);
  }

  /// Allenamento libero: gli esercizi si scelgono al momento.
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
        _onSessionChanged(session);
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

        return Scaffold(
          backgroundColor: kBg,
          body: CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverToBoxAdapter(
                child: PageHeader(
                  title: weekday[0].toUpperCase() + weekday.substring(1),
                  meta: dayMonth,
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
                // Allenamento rimasto aperto da un altro giorno: lo si dice,
                // senza chiuderlo da soli (si puo' finire dopo mezzanotte).
                if (isStale)
                  SliverToBoxAdapter(
                    child: _StaleBanner(
                      onNewDay: () => finishWorkoutFlow(context, state),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: _WorkoutLabel(
                    state: state,
                    session: session,
                    onEditMood: () => _editMood(context, state),
                    topGap: isStale ? 16 : 28,
                  ),
                ),
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
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: kGapCard),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(kGapPage, 16, kGapPage, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DashedButton(
                          key: TourKeys.addExerciseFab,
                          label: S.get('add_an_exercise'),
                          onTap: () => _openPicker(context),
                        ),
                        const SizedBox(height: 12),
                        // Fine lista: e' qui che arrivi quando hai finito.
                        ElevatedButton.icon(
                          onPressed: () => finishWorkoutFlow(context, state),
                          icon: const Icon(Icons.check, size: 20),
                          label: Text(S.get('finish_workout')),
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: TextButton(
                            key: TourKeys.templatesRow,
                            onPressed: () => showTemplateSheet(context, state),
                            style: TextButton.styleFrom(
                                foregroundColor: kText2),
                            child: Text(S.get('switch_template'),
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SliverToBoxAdapter(
                  child: SizedBox(height: kBottomSafeSpace)),
            ],
          ),
        );
      },
    );
  }
}

// ─── ETICHETTA DELL'ALLENAMENTO ─────────────────────────────────────────────
/// "PUSH DAY ▾ · 😊 ........ ✓ Finisci". Il giorno rende confrontabili i
/// numeri: si vede e si cambia da qui; Finisci e' sempre a portata.
class _WorkoutLabel extends StatelessWidget {
  final AppState state;
  final WorkoutSession session;
  final VoidCallback onEditMood;
  final double topGap;

  const _WorkoutLabel({
    required this.state,
    required this.session,
    required this.onEditMood,
    required this.topGap,
  });

  @override
  Widget build(BuildContext context) {
    final dayName = state.dayNameOf(session);
    final canPickDay = dayName != null || state.templates.isNotEmpty;
    return SectionTitle(
      dayName ?? S.get('free_workout_long'),
      padding: EdgeInsets.fromLTRB(kGapPage, topGap, kGapPage, 8),
      onTap: canPickDay
          ? () => showSessionDayPicker(context, state, session)
          : null,
      after: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canPickDay) Icon(Icons.expand_more, size: 18, color: kText2),
          if (session.rating != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onEditMood,
              child: RatingBadge(session.rating!, showLabel: false),
            ),
          ],
        ],
      ),
      trailing: Transform.translate(
        // Il tocco e' largo 44, la scritta resta allineata al margine.
        offset: const Offset(10, 0),
        child: TextButton.icon(
          key: TourKeys.newDayButton,
          onPressed: () => finishWorkoutFlow(context, state),
          style: TextButton.styleFrom(
            foregroundColor: kAccentText,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            minimumSize: const Size(44, 44),
          ),
          icon: const Icon(Icons.check, size: 18),
          label: Text(S.get('finish'),
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ),
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
      padding: const EdgeInsets.fromLTRB(kGapPage, 24, kGapPage, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(kBlockInset, 8, 6, 8),
        decoration: BoxDecoration(
          color: blockColor,
          borderRadius: BorderRadius.circular(kRadius),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(S.get('stale_session'),
                  style: T.meta.copyWith(height: 1.35)),
            ),
            TextButton(
              onPressed: onNewDay,
              style: TextButton.styleFrom(foregroundColor: kAccentText),
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
// un blocco (un tocco e si caricano) oppure l'allenamento libero.
class _EmptyToday extends StatelessWidget {
  final AppState state;
  final VoidCallback onAddExercise;

  const _EmptyToday({required this.state, required this.onAddExercise});

  void _newTemplate(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TemplateEditorScreen()),
      );

  void _editTemplate(BuildContext context, WorkoutTemplate t) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TemplateEditorScreen(existing: t)),
      );

  @override
  Widget build(BuildContext context) {
    final templates = state.templates;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          S.get('templates'),
          padding: const EdgeInsets.fromLTRB(kGapPage, 40, kGapPage, 8),
          // Il "+" compare solo se c'e' gia' un giorno: senza, l'invito a
          // crearne uno e' gia' il blocco qui sotto.
          trailing: templates.isEmpty
              ? null
              : Transform.translate(
                  // Tocco da 44, ma il "+" resta allineato al margine.
                  offset: const Offset(11, 0),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: InkResponse(
                      onTap: () => _newTemplate(context),
                      radius: 22,
                      child: Center(child: PlusIcon(size: 22)),
                    ),
                  ),
                ),
        ),
        if (templates.isEmpty)
          _NoTemplates(
            key: TourKeys.templatesRow,
            onCreate: () => _newTemplate(context),
          )
        else
          Block(
            key: TourKeys.templatesRow,
            children: [
              for (final t in templates)
                ListRow(
                  title: t.name,
                  titleColor: kAccentText,
                  subtitle: _templateSummary(t),
                  subtitleMaxLines: 1,
                  minHeight: 76,
                  trailing: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: PlayIcon(size: 22),
                  ),
                  onTap: () => loadTemplateFlow(context, state, t),
                  // Tieni premuto per modificarlo.
                  onLongPress: () => _editTemplate(context, t),
                ),
            ],
          ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kGapPage),
          child: OrSeparator(),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kGapPage),
          child: DashedButton(
            key: TourKeys.addExerciseFab,
            label: S.get('add_an_exercise'),
            onTap: onAddExercise,
          ),
        ),
      ],
    );
  }

  /// I primi tre esercizi, poi "+N" per gli altri.
  String _templateSummary(WorkoutTemplate t) {
    final names = t.exerciseNames;
    final shown = names.take(3).join(', ');
    final extra = names.length > 3 ? ' +${names.length - 3}' : '';
    return '$shown$extra';
  }
}

/// Nessun giorno preimpostato: la domanda e il bottone per crearne uno.
class _NoTemplates extends StatelessWidget {
  final VoidCallback onCreate;
  const _NoTemplates({super.key, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kGapPage),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
        decoration: BoxDecoration(
          color: blockColor,
          borderRadius: BorderRadius.circular(kRadius),
        ),
        child: Column(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: Text(
                S.get('no_templates_today'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: kText,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(S.get('create_one'),
                style: TextStyle(fontSize: 15, color: kText2)),
            const SizedBox(height: 24),
            // Grigio, non in accento: e' un invito, non l'azione principale.
            Material(
              color: kSurface3,
              borderRadius: BorderRadius.circular(kRadius),
              child: InkWell(
                onTap: onCreate,
                borderRadius: BorderRadius.circular(kRadius),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Center(
                    child: PlusIcon(size: 32, color: kTextSoft),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
