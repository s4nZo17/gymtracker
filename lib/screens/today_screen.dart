// lib/screens/today_screen.dart
//
// Schermata "Oggi" 2.0: stesse funzioni della v1, layout piu pulito.
// - Header con data grande e bottone "Nuovo giorno".
// - Card esercizio piu ariose, serie come righe grandi e tappabili
//   (tocca la riga per modificarla, niente icone minuscole).
// - "+ Serie" ben visibile.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../l10n/strings.dart';
import '../widgets/widgets.dart';
import '../widgets/series_sheet.dart';
import '../widgets/session_day_picker.dart';
import '../widgets/app_tour.dart';
import 'exercise_picker_screen.dart';
import 'progress_screen.dart';
import 'templates_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  /// Il FAB si ritira mentre scorri in giu' (cosi' non copre i pulsanti
  /// "Aggiungi serie" dell'ultima card) e ricompare appena risali.
  bool _fabVisible = true;

  bool _onScroll(UserScrollNotification n) {
    if (n.direction == ScrollDirection.reverse && _fabVisible) {
      setState(() => _fabVisible = false);
    } else if (n.direction == ScrollDirection.forward && !_fabVisible) {
      setState(() => _fabVisible = true);
    }
    return false;
  }

  void _showRatingThenNewDay(BuildContext context, AppState state) {
    final session = state.todaySession;
    final hasExercises = session.exercises.any((ex) => ex.series.isNotEmpty);

    if (hasExercises && session.rating == null) {
      showDialog(
        context: context,
        builder: (_) => _RatingDialog(
          onRate: (rating) {
            state.setSessionRating(session, rating);
            state.startNewDay();
          },
          onSkip: () {
            state.startNewDay();
          },
        ),
      );
    } else {
      confirmDialog(
        context,
        title: '${S.get('new_day')}?',
        message: S.get('new_day_confirm'),
      ).then((ok) {
        if (ok) state.startNewDay();
      });
    }
  }

  void _showTemplatePicker(BuildContext context, AppState state) {
    if (state.templates.isEmpty) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const TemplatesScreen()));
      return;
    }

    showAppSheet(
      context,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: SheetTitle(S.get('templates'))),
                Padding(
                  padding: const EdgeInsets.only(right: 16, top: 8),
                  child: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const TemplatesScreen()));
                    },
                    icon: Icon(Icons.settings_outlined, color: kText3, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...state.templates.map((template) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    onTap: () {
                      state.applyTemplate(template);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(S.get('template_applied'))),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: kAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.flash_on, color: kAccent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                template.name,
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: kText),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                template.exerciseNames.join(' · '),
                                style: TextStyle(fontSize: 12, color: kText2),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: kText3, size: 20),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final session = state.todaySession;
        final locale = state.prefs.language == 'en' ? 'en_US' : 'it_IT';
        final sessionDate = DateTime.tryParse(session.date) ?? DateTime.now();
        final weekday = DateFormat('EEEE', locale).format(sessionDate);
        final dayMonth = DateFormat('d MMMM', locale).format(sessionDate);

        final totalSeries = session.totalSeries;
        final dayName = state.dayNameOf(session);

        return Scaffold(
          backgroundColor: kBg,
          body: Stack(
            children: [
              // Alone sfumato del colore accento in alto: profondita senza rumore.
              Positioned(
                top: -120,
                left: -60,
                right: -60,
                child: IgnorePointer(
                  child: Container(
                    height: 300,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          kAccent.withValues(alpha: 0.10),
                          kAccent.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              NotificationListener<UserScrollNotification>(
                onNotification: _onScroll,
                child: CustomScrollView(
            slivers: [
              // Header: data grande + nuovo giorno
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      20, MediaQuery.of(context).padding.top + 14, 20, 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              weekday[0].toUpperCase() + weekday.substring(1),
                              style: GoogleFonts.inter(
                                fontSize: 26,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.5,
                                color: kText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Wrap e non Row: con il chip del giorno la riga
                            // andava in overflow sui nomi lunghi.
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  session.exercises.isEmpty
                                      ? dayMonth
                                      : '$dayMonth  ·  ${session.exercises.length} ${S.get('exercises_count')} · $totalSeries ${S.get('series')}',
                                  style: TextStyle(
                                      fontSize: 13.5, color: kText2),
                                ),
                                if (session.rating != null)
                                  RatingBadge(session.rating!),
                                // Il giorno preimpostato della sessione: e' lui
                                // che rende confrontabili i numeri, quindi si
                                // vede e si cambia da qui.
                                if (dayName != null || state.templates.isNotEmpty)
                                  DayChip(
                                    dayName: dayName,
                                    onTap: () => showSessionDayPicker(
                                        context, state, session),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      FilledButton.tonal(
                        key: TourKeys.newDayButton,
                        onPressed: () => _showRatingThenNewDay(context, state),
                        style: FilledButton.styleFrom(
                          backgroundColor: kAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          S.get('new_day'),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Riga giorni preimpostati
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                  child: Material(
                    key: TourKeys.templatesRow,
                    color: kSurface,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _showTemplatePicker(context, state),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: kSurface3.withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.flash_on, color: kAccent, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              S.get('templates'),
                              style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: kText),
                            ),
                            const Spacer(),
                            Icon(Icons.chevron_right, color: kText3, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if (session.exercises.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyToday(
                    onAddExercise: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ExercisePickerScreen()),
                    ),
                    onUseTemplate: () => _showTemplatePicker(context, state),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _ExerciseCard(exIdx: i),
                    childCount: session.exercises.length,
                  ),
                ),

              const SliverToBoxAdapter(
                  child: SizedBox(height: kBottomSafeSpace)),
            ],
          ),
              ),
              // Velo in cima: scorrendo, le card passavano sotto l'orologio
              // e alle icone di sistema senza alcuna separazione.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Container(
                    height: MediaQuery.of(context).padding.top + 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          kBg,
                          kBg.withValues(alpha: 0.85),
                          kBg.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ExercisePickerScreen()),
                ),
                backgroundColor: kAccent,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                icon: const Icon(Icons.add, size: 24),
                label: Text(
                  S.get('exercise_short'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── EMPTY STATE "OGGI" ─────────────────────────────────────────────────────
// Chi apre l'app deve capire subito cosa fare: due azioni, ben visibili.

class _EmptyToday extends StatelessWidget {
  final VoidCallback onAddExercise;
  final VoidCallback onUseTemplate;

  const _EmptyToday({
    required this.onAddExercise,
    required this.onUseTemplate,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kAccent.withValues(alpha: 0.22),
                    kAccent2.withValues(alpha: 0.10),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(Icons.fitness_center, size: 38, color: kAccent),
            ),
            const SizedBox(height: 20),
            Text(
              S.lang == 'it' ? 'Pronto ad allenarti?' : 'Ready to train?',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: kText,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              S.lang == 'it'
                  ? 'Aggiungi il primo esercizio di oggi\noppure carica una scheda pronta.'
                  : 'Add today\'s first exercise\nor load a ready-made routine.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: kText2, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAddExercise,
              icon: const Icon(Icons.add, size: 20),
              label: Text(S.lang == 'it' ? 'Aggiungi esercizio' : 'Add exercise'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onUseTemplate,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              icon: Icon(Icons.flash_on, size: 18, color: kAccent),
              label: Text(
                S.get('templates'),
                style: TextStyle(color: kText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── RATING DIALOG ──────────────────────────────────────────────────────────

class _RatingDialog extends StatefulWidget {
  final void Function(int rating) onRate;
  final VoidCallback onSkip;

  const _RatingDialog({required this.onRate, required this.onSkip});

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int _selected = 7;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.get('rate_workout')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(S.get('rate_workout_desc'),
              style: TextStyle(color: kText2, fontSize: 13)),
          const SizedBox(height: 16),
          Text(
            '$_selected',
            style: GoogleFonts.inter(
                fontSize: 52, fontWeight: FontWeight.w600, color: kAccent),
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: kAccent,
              inactiveTrackColor: kSurface3,
              thumbColor: kAccent,
              overlayColor: kAccent.withValues(alpha: 0.2),
            ),
            child: Slider(
              min: 1,
              max: 10,
              divisions: 9,
              value: _selected.toDouble(),
              onChanged: (v) => setState(() => _selected = v.round()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1', style: TextStyle(fontSize: 11, color: kText3)),
              Text('10', style: TextStyle(fontSize: 11, color: kText3)),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onSkip();
          },
          child: Text(S.get('skip'), style: TextStyle(color: kText3)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onRate(_selected);
          },
          child: Text(S.get('confirm'),
              style: TextStyle(color: kAccent, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// ─── EXERCISE CARD ──────────────────────────────────────────────────────────

class _ExerciseCard extends StatefulWidget {
  final int exIdx;
  const _ExerciseCard({required this.exIdx});

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  bool _expanded = true;

  void _openSeriesSheet(
    BuildContext context,
    AppState state,
    ExerciseLog exercise,
    ExerciseHistory history, {
    int? seriesIndex,
  }) {
    final editSeries = seriesIndex == null ? null : exercise.series[seriesIndex];

    SeriesSheet.show(
      context,
      exerciseName: exercise.name,
      seriesNumber:
          seriesIndex == null ? exercise.series.length + 1 : seriesIndex + 1,
      history: history,
      currentDayName: state.dayNameOf(state.todaySession),
      bestSeries: state.getBestSeriesEver(exercise.name),
      editSeries: editSeries,
      dateFormat: state.prefs.dateFormat,
      onSave: (series) {
        if (seriesIndex == null) {
          state.addSeries(widget.exIdx, series);
        } else {
          state.updateSeries(widget.exIdx, seriesIndex, series);
        }
      },
    );
  }

  void _showNoteDialog(BuildContext context, AppState state, int exIdx,
      String? currentNote, String? lastNote) {
    final controller = TextEditingController(text: currentNote ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.get('note')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lastNote != null && currentNote == null) ...[
              Text(S.get('previous_note'),
                  style: TextStyle(
                      fontSize: 12, color: kText3, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(lastNote,
                    style: TextStyle(
                        fontSize: 13,
                        color: kText2,
                        fontStyle: FontStyle.italic)),
              ),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: controller,
              style: TextStyle(color: kText),
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(hintText: S.get('add_note')),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(S.get('cancel'), style: TextStyle(color: kText2))),
          TextButton(
            onPressed: () {
              state.updateExerciseNote(exIdx, controller.text);
              Navigator.pop(context);
            },
            child: Text(S.get('confirm'),
                style: TextStyle(color: kAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteExercise(
      BuildContext context, AppState state, ExerciseLog ex) async {
    final ok = await confirmDialog(
      context,
      title: '${S.get('delete_exercise')} ${ex.name}?',
      confirmText: S.get('delete'),
      destructive: true,
    );
    if (!ok || !context.mounted) return;

    final index = widget.exIdx;
    final backup = ExerciseLog.fromJson(ex.toJson());
    state.removeExerciseFromToday(index);
    showAppSnack(
      context,
      S.get('exercise_deleted'),
      onUndo: () => state.insertExerciseInToday(index, backup),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final ex = state.todaySession.exercises[widget.exIdx];
        final history = state.historyForToday(ex.name);
        final lastNote = history.relevantNote;
        final inheritedRest =
            ex.restSeconds == null ? state.getLastRestForExercise(ex.name) : null;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Container(
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(kRadiusCard),
              border: Border.all(color: kSurface3.withValues(alpha: 0.6)),
            ),
            child: Column(
              children: [
                // Intestazione card
                InkWell(
                  borderRadius: BorderRadius.circular(kRadiusCard),
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      ex.name,
                                      style: TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w600,
                                          color: kText),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (ex.note != null || lastNote != null) ...[
                                    const SizedBox(width: 7),
                                    Icon(
                                      Icons.sticky_note_2_outlined,
                                      size: 14,
                                      color:
                                          ex.note != null ? kAccent : kText3,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                // Col target del giorno il conteggio diventa
                                // "2/4 serie": si vede a che punto sei.
                                ex.series.isEmpty
                                    ? (ex.targetSeries != null
                                        ? '0/${ex.targetSeries} ${S.get('series')}'
                                        : S.get('no_series'))
                                    : '${ex.series.length}${ex.targetSeries != null ? '/${ex.targetSeries}' : ''} ${S.get('series')} · ${ex.series.map((s) => s.summary).join(' / ')}',
                                style: TextStyle(fontSize: 12, color: kText2),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (ex.restSeconds != null || inheritedRest != null)
                          RestBadge(
                            seconds: ex.restSeconds ?? inheritedRest!,
                            inherited: ex.restSeconds == null,
                            onTap: () async {
                              final picked = await RestPickerDialog.show(
                                context,
                                initial: ex.restSeconds ?? inheritedRest,
                              );
                              if (picked != null) {
                                state.updateExerciseRest(
                                    widget.exIdx, picked == 0 ? null : picked);
                              }
                            },
                          )
                        else
                          IconButton(
                            onPressed: () async {
                              final picked =
                                  await RestPickerDialog.show(context);
                              if (picked != null && picked > 0) {
                                state.updateExerciseRest(widget.exIdx, picked);
                              }
                            },
                            icon: Icon(Icons.timer_outlined,
                                color: kText3, size: 19),
                            visualDensity: VisualDensity.compact,
                          ),
                        AnimatedRotation(
                          turns: _expanded ? -0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child:
                              Icon(Icons.keyboard_arrow_down, color: kText3),
                        ),
                      ],
                    ),
                  ),
                ),

                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: _expanded
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nota corrente o precedente
                        if (ex.note != null || lastNote != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: kBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (ex.note != null) ...[
                                  Row(
                                    children: [
                                      Icon(Icons.notes,
                                          size: 13, color: kAccent),
                                      const SizedBox(width: 6),
                                      Text(S.get('note'),
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: kAccent,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(ex.note!,
                                      style: TextStyle(
                                          fontSize: 13, color: kText)),
                                ] else if (lastNote != null) ...[
                                  Row(
                                    children: [
                                      Icon(Icons.history,
                                          size: 13, color: kText3),
                                      const SizedBox(width: 6),
                                      Text(S.get('previous_note'),
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: kText3,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(lastNote,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: kText2,
                                          fontStyle: FontStyle.italic)),
                                ],
                              ],
                            ),
                          ),

                        // Serie: righe grandi tappabili, swipe a sinistra per
                        // eliminare (con annulla) invece della "x" sempre
                        // armata sotto il pollice.
                        ...ex.series.asMap().entries.map((e) {
                          final s = e.value;
                          final i = e.key;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: SeriesRow(
                              index: i,
                              series: s,
                              onTap: () => _openSeriesSheet(
                                  context, state, ex, history,
                                  seriesIndex: i),
                              onDelete: () {
                                state.removeSeries(widget.exIdx, i);
                                showAppSnack(
                                  context,
                                  S.get('series_deleted'),
                                  onUndo: () =>
                                      state.insertSeries(widget.exIdx, i, s),
                                );
                              },
                            ),
                          );
                        }),

                        // Serie previste dal giorno e non ancora fatte: righe
                        // tratteggiate, non dati finti nello storico.
                        ...List.generate(
                          ex.pendingTargetSeries,
                          (offset) => PendingSeriesRow(
                            index: ex.series.length + offset,
                            onTap: () =>
                                _openSeriesSheet(context, state, ex, history),
                          ),
                        ),

                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Material(
                                color: kAccent.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _openSeriesSheet(
                                      context, state, ex, history),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add,
                                            size: 18, color: kAccent),
                                        const SizedBox(width: 4),
                                        Text(
                                          S.get('add_series_short'),
                                          style: TextStyle(
                                              fontSize: 13.5,
                                              color: kAccent,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _iconAction(
                              icon: ex.note != null
                                  ? Icons.notes
                                  : Icons.add_comment_outlined,
                              color: ex.note != null ? kAccent : kText3,
                              tooltip: S.get('note'),
                              onTap: () => _showNoteDialog(
                                  context, state, widget.exIdx, ex.note, lastNote),
                            ),
                            const SizedBox(width: 8),
                            _iconAction(
                              icon: Icons.trending_up,
                              color: kText3,
                              tooltip: S.get('view_progress'),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ExerciseProgressScreen(exName: ex.name),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _iconAction(
                              icon: Icons.delete_outline,
                              color: kText3,
                              tooltip: S.get('delete'),
                              onTap: () =>
                                  _confirmDeleteExercise(context, state, ex),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  secondChild: const SizedBox(height: 6),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _iconAction(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap,
      String? tooltip}) {
    final button = Material(
      color: kSurface2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}
