// lib/screens/history_screen.dart
//
// Storico 2.1: header con ricerca e riepilogo, sessioni raggruppate per mese,
// serie eliminabili con lo swipe (e annullabili), scorciatoia ai progressi.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/series_sheet.dart';
import '../widgets/session_day_picker.dart';
import '../widgets/widgets.dart';
import 'progress_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final all = state.workouts
            .where((w) => w.exercises.isNotEmpty)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        final term = _search.trim().toLowerCase();
        final sessions = term.isEmpty
            ? all
            : all
                .where((s) =>
                    s.exercises.any((e) => e.name.toLowerCase().contains(term)))
                .toList();

        final locale = state.prefs.language == 'en' ? 'en_US' : 'it_IT';
        final now = DateTime.now();
        final thisMonth = all.where((s) {
          final d = DateTime.tryParse(s.date);
          return d != null && d.year == now.year && d.month == now.month;
        }).length;

        // Le sessioni vengono raggruppate per mese: scorrere 25 card tutte
        // uguali senza un riferimento temporale era faticoso.
        final items = <Widget>[];
        String currentMonth = '';
        for (final s in sessions) {
          final d = DateTime.tryParse(s.date);
          final monthKey = d == null
              ? ''
              : DateFormat('MMMM yyyy', locale).format(DateTime(d.year, d.month));
          if (monthKey != currentMonth) {
            currentMonth = monthKey;
            items.add(SectionTitle(monthKey));
          }
          items.add(_SessionCard(session: s));
        }

        return Scaffold(
          backgroundColor: kBg,
          body: Column(
            children: [
              PageHeader(
                title: S.get('history'),
                subtitle: all.isEmpty
                    ? null
                    : '${all.length} ${S.get('workouts_count')} · ${S.get('this_month')}: $thisMonth',
                bottom: all.isEmpty
                    ? null
                    : AppSearchField(
                        hint: S.get('search_in_history'),
                        value: _search,
                        onChanged: (v) => setState(() => _search = v),
                      ),
              ),
              Expanded(
                child: all.isEmpty
                    ? EmptyState(
                        icon: Icons.history,
                        title: S.get('no_workouts'),
                        subtitle: S.get('start_first_workout'),
                      )
                    : sessions.isEmpty
                        ? EmptyState(
                            icon: Icons.search_off,
                            title: S.get('no_results'),
                            subtitle: S.get('try_other_search'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(
                                top: 6, bottom: kBottomSafeSpace),
                            itemCount: items.length,
                            itemBuilder: (_, i) => items[i],
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SessionCard extends StatefulWidget {
  final WorkoutSession session;

  const _SessionCard({required this.session});

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  bool _expanded = false;

  String _formatDate(String d) {
    final state = context.read<AppState>();
    final locale = state.prefs.language == 'en' ? 'en_US' : 'it_IT';
    final fmt = state.prefs.dateFormat == 'dd-MM'
        ? 'EEEE d MMMM yyyy'
        : 'EEEE MMMM d, yyyy';
    final dt = DateTime.tryParse(d) ?? DateTime.now();
    return DateFormat(fmt, locale).format(dt);
  }

  Future<void> _editDate() async {
    final state = context.read<AppState>();
    final currentDate = DateTime.tryParse(widget.session.date) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        if (child == null) return const SizedBox();
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                Theme.of(context).colorScheme.copyWith(primary: kAccent),
          ),
          child: child,
        );
      },
    );

    if (picked == null || !mounted) return;

    state.updateSessionDate(
      widget.session,
      picked.toIso8601String().split('T').first,
    );
  }

  void _showEditExerciseDialog(int exerciseIndex) {
    final exercise = widget.session.exercises[exerciseIndex];
    final controller = TextEditingController(text: exercise.name);

    showAppSheet(
      context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),
            Text(
              S.lang == 'it' ? 'Modifica esercizio del giorno' : 'Edit logged exercise',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(labelText: S.get('exercise_name')),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                final updated =
                    context.read<AppState>().updateExerciseNameInSession(
                          widget.session,
                          exerciseIndex,
                          controller.text,
                        );
                Navigator.pop(context);
                if (!updated && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        S.lang == 'it'
                            ? 'Nome non valido o già presente in questo giorno.'
                            : 'Invalid name or already present in this workout.',
                      ),
                      backgroundColor: kRed,
                    ),
                  );
                }
              },
              child: Text(S.get('update')),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoteEditor(int exerciseIndex) {
    final state = context.read<AppState>();
    final exercise = widget.session.exercises[exerciseIndex];
    final controller = TextEditingController(text: exercise.note ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.get('note')),
        content: TextField(
          controller: controller,
          style: TextStyle(color: kText),
          maxLines: 3,
          autofocus: true,
          decoration: InputDecoration(hintText: S.get('add_note')),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(S.get('cancel'), style: TextStyle(color: kText2))),
          TextButton(
            onPressed: () {
              state.updateExerciseNoteInSession(
                  widget.session, exerciseIndex, controller.text);
              Navigator.pop(context);
            },
            child: Text(S.get('confirm'),
                style: TextStyle(color: kAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showSeriesEditor({
    required int exerciseIndex,
    int? seriesIndex,
  }) {
    final state = context.read<AppState>();
    final exercise = widget.session.exercises[exerciseIndex];
    final editSeries = seriesIndex == null ? null : exercise.series[seriesIndex];

    SeriesSheet.show(
      context,
      exerciseName: exercise.name,
      seriesNumber:
          seriesIndex == null ? exercise.series.length + 1 : seriesIndex + 1,
      history: state.historyFor(widget.session, exercise.name),
      currentDayName: state.dayNameOf(widget.session),
      bestSeries: state.getBestSeriesEver(exercise.name),
      editSeries: editSeries,
      dateFormat: state.prefs.dateFormat,
      onSave: (series) {
        if (seriesIndex == null) {
          state.addSeriesToSession(widget.session, exerciseIndex, series);
        } else {
          state.updateSeriesInSession(
              widget.session, exerciseIndex, seriesIndex, series);
        }
      },
    );
  }

  Future<void> _confirmDeleteExercise(int exerciseIndex) async {
    final exercise = widget.session.exercises[exerciseIndex];
    final ok = await confirmDialog(
      context,
      title: '${S.get('delete_exercise')} ${exercise.name}?',
      confirmText: S.get('delete'),
      destructive: true,
    );
    if (ok && mounted) {
      context
          .read<AppState>()
          .removeExerciseFromSession(widget.session, exerciseIndex);
    }
  }

  Widget _buildExerciseDetail(ExerciseLog exercise, int exerciseIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSurface2.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exercise.name,
                  style: TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w600, color: kText),
                ),
              ),
              // Scorciatoia ai grafici: prima da qui non si poteva andare
              // da nessuna parte, era un vicolo cieco.
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ExerciseProgressScreen(exName: exercise.name),
                  ),
                ),
                tooltip: S.get('view_progress'),
                icon: Icon(Icons.trending_up, size: 18, color: kText3),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: () => _showNoteEditor(exerciseIndex),
                tooltip: S.get('note'),
                icon: Icon(
                  exercise.note != null
                      ? Icons.notes
                      : Icons.add_comment_outlined,
                  size: 18,
                  color: exercise.note != null ? kAccent : kText3,
                ),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: () => _showEditExerciseDialog(exerciseIndex),
                tooltip: S.get('edit'),
                icon: Icon(Icons.edit_outlined, size: 18, color: kText3),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: () =>
                    _showSeriesEditor(exerciseIndex: exerciseIndex),
                tooltip: S.get('add_series_short'),
                icon: Icon(Icons.add, size: 19, color: kAccent),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: () => _confirmDeleteExercise(exerciseIndex),
                tooltip: S.get('delete'),
                icon: const Icon(Icons.delete_outline, size: 18, color: kRed),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (exercise.note != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                exercise.note!,
                style: TextStyle(
                    fontSize: 12, color: kText2, fontStyle: FontStyle.italic),
              ),
            ),
          if (exercise.series.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                S.get('no_series'),
                style: TextStyle(fontSize: 12, color: kText3),
              ),
            )
          else
            ...exercise.series.asMap().entries.map((entry) {
              final seriesIndex = entry.key;
              final series = entry.value;
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: SeriesRow(
                  index: seriesIndex,
                  series: series,
                  dense: true,
                  onTap: () => _showSeriesEditor(
                    exerciseIndex: exerciseIndex,
                    seriesIndex: seriesIndex,
                  ),
                  onDelete: () {
                    final state = context.read<AppState>();
                    state.removeSeriesFromSession(
                        widget.session, exerciseIndex, seriesIndex);
                    showAppSnack(
                      context,
                      S.get('series_deleted'),
                      onUndo: () => state.insertSeriesInSession(
                          widget.session, exerciseIndex, seriesIndex, series),
                    );
                  },
                ),
              );
            }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final dateLabel = _formatDate(session.date);
    final totalSeries = session.totalSeries;
    final dayName = context.watch<AppState>().dayNameOf(session);

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
            InkWell(
              borderRadius: BorderRadius.circular(kRadiusCard),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          dateLabel.split(' ').first.toUpperCase(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: kAccent,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            dateLabel.split(' ').skip(1).join(' '),
                            style: TextStyle(fontSize: 14, color: kText2),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        AnimatedRotation(
                          turns: _expanded ? -0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child:
                              Icon(Icons.keyboard_arrow_down, color: kText3),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${session.exercises.length} ${S.get('exercises_count')} · $totalSeries ${S.get('total_series')}',
                          style: TextStyle(fontSize: 12, color: kText2),
                        ),
                        if (session.rating != null)
                          RatingBadge(session.rating!, fontSize: 10),
                        // Da che giorno preimpostato arriva la sessione: si
                        // puo' correggere qui, ma lo storico vecchio resta
                        // senza contesto finche' non lo etichetti tu.
                        if (dayName != null ||
                            context.read<AppState>().templates.isNotEmpty)
                          DayChip(
                            dayName: dayName,
                            fontSize: 10.5,
                            onTap: () => showSessionDayPicker(
                                context, context.read<AppState>(), session),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: session.exercises
                          .map(
                            (ex) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: kSurface2,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    ex.name,
                                    style:
                                        TextStyle(fontSize: 12, color: kText2),
                                  ),
                                  if (ex.note != null) ...[
                                    const SizedBox(width: 4),
                                    Icon(Icons.sticky_note_2_outlined,
                                        size: 10, color: kAccent),
                                  ],
                                ],
                              ),
                            ),
                          )
                          .toList(),
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _editDate,
                              icon: const Icon(Icons.edit_calendar_outlined,
                                  size: 18),
                              label: Text(
                                S.lang == 'it' ? 'Modifica data' : 'Edit date',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => showAppSheet(
                                context,
                                child: _SessionExercisePicker(
                                    session: widget.session),
                              ),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 48),
                              ),
                              icon: const Icon(Icons.add, size: 18),
                              label: Text(S.lang == 'it'
                                  ? 'Aggiungi esercizio'
                                  : 'Add exercise'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...session.exercises.asMap().entries.map(
                          (entry) =>
                              _buildExerciseDetail(entry.value, entry.key),
                        ),
                  ],
                ),
              ),
              secondChild: const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionExercisePicker extends StatefulWidget {
  final WorkoutSession session;

  const _SessionExercisePicker({required this.session});

  @override
  State<_SessionExercisePicker> createState() => _SessionExercisePickerState();
}

class _SessionExercisePickerState extends State<_SessionExercisePicker> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final filtered = state.library.where((exercise) {
          final term = _search.toLowerCase();
          return exercise.name.toLowerCase().contains(term) ||
              exercise.category.toLowerCase().contains(term);
        }).toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 14),
              Text(
                S.lang == 'it'
                    ? 'Aggiungi esercizio al giorno'
                    : 'Add exercise to workout',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (value) => setState(() => _search = value),
                decoration: InputDecoration(
                  hintText: S.get('search_exercise'),
                  prefixIcon: Icon(Icons.search, color: kText3),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.search_off,
                        title: S.get('no_exercise_found'),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final exercise = filtered[index];
                          final alreadyAdded = widget.session.exercises.any(
                            (item) =>
                                item.name.trim().toLowerCase() ==
                                exercise.name.trim().toLowerCase(),
                          );

                          return AppCard(
                            padding: const EdgeInsets.all(14),
                            onTap: alreadyAdded
                                ? null
                                : () {
                                    final added = state.addExerciseToSession(
                                      widget.session,
                                      exercise.name,
                                    );
                                    if (added && mounted) {
                                      Navigator.pop(context);
                                    }
                                  },
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        exercise.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              alreadyAdded ? kText3 : kText,
                                        ),
                                      ),
                                      if (exercise.category.isNotEmpty)
                                        Text(
                                          exercise.category,
                                          style: TextStyle(
                                              fontSize: 12, color: kText3),
                                        ),
                                    ],
                                  ),
                                ),
                                if (alreadyAdded)
                                  Text(
                                    S.get('already_added'),
                                    style: TextStyle(
                                        fontSize: 11, color: kText3),
                                  )
                                else
                                  Icon(Icons.add_circle_outline,
                                      color: kAccent, size: 20),
                              ],
                            ),
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
