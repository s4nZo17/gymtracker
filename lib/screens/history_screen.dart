// lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/series_sheet.dart';
import '../widgets/widgets.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final sessions = state.workouts
            .where((w) => w.exercises.isNotEmpty)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        return Scaffold(
          backgroundColor: kBg,
          appBar: AppBar(title: Text(S.get('history'))),
          body: sessions.isEmpty
              ? EmptyState(emoji: '', title: S.get('no_workouts'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: sessions.length,
                  itemBuilder: (_, i) => _SessionCard(session: sessions[i]),
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
    final fmt = state.prefs.dateFormat == 'dd-MM' ? 'EEEE d MMMM yyyy' : 'EEEE MMMM d, yyyy';
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
            colorScheme: Theme.of(context).colorScheme.copyWith(primary: kAccent),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kSurface3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                  final updated = context.read<AppState>().updateExerciseNameInSession(
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
                              ? 'Nome non valido o gia presente in questo giorno.'
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
    final previousLog = state.getPreviousExerciseLog(widget.session, exercise.name);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SeriesSheet(
        exerciseName: exercise.name,
        seriesNumber: seriesIndex == null ? exercise.series.length + 1 : seriesIndex + 1,
        lastSeries: previousLog?.series,
        editSeries: editSeries,
        onSave: (series) {
          if (seriesIndex == null) {
            state.addSeriesToSession(widget.session, exerciseIndex, series);
          } else {
            state.updateSeriesInSession(widget.session, exerciseIndex, seriesIndex, series);
          }
        },
      ),
    );
  }

  void _confirmDeleteExercise(int exerciseIndex) {
    final exercise = widget.session.exercises[exerciseIndex];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        content: Text(
          '${S.get('delete_exercise')} ${exercise.name}?',
          style: TextStyle(color: kText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.get('cancel')),
          ),
          TextButton(
            onPressed: () {
              context.read<AppState>().removeExerciseFromSession(widget.session, exerciseIndex);
              Navigator.pop(context);
            },
            child: Text(S.get('delete'), style: const TextStyle(color: kRed)),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseDetail(ExerciseLog exercise, int exerciseIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSurface2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exercise.name,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kText),
                ),
              ),
              IconButton(
                onPressed: () => _showEditExerciseDialog(exerciseIndex),
                icon: Icon(Icons.edit_outlined, size: 18, color: kText3),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: () => _showSeriesEditor(exerciseIndex: exerciseIndex),
                icon: Icon(Icons.add, size: 18, color: kAccent),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: () => _confirmDeleteExercise(exerciseIndex),
                icon: Icon(Icons.delete_outline, size: 18, color: kRed),
                visualDensity: VisualDensity.compact,
              ),
            ],
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
                child: Row(
                  children: [
                    SeriesNumBadge(seriesIndex + 1),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _showSeriesEditor(
                          exerciseIndex: exerciseIndex,
                          seriesIndex: seriesIndex,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '${formatWeight(series.weight)} kg x ${series.reps}',
                                style: TextStyle(fontSize: 13, color: kText),
                              ),
                              SeriesBadge(series.type),
                              if (series.type == SeriesType.drop && series.drops.isNotEmpty)
                                DropsDisplay(series.drops),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.read<AppState>().removeSeriesFromSession(
                            widget.session,
                            exerciseIndex,
                            seriesIndex,
                          ),
                      icon: Icon(Icons.close, size: 16, color: kText3),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kSurface3),
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(14),
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
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
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
                          turns: _expanded ? 0 : -0.5,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(Icons.keyboard_arrow_down, color: kText3),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${session.exercises.length} ${S.get('exercises_count')} · $totalSeries ${S.get('total_series')}',
                      style: TextStyle(fontSize: 12, color: kText2),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: session.exercises
                          .map(
                            (ex) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: kSurface2,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                ex.name,
                                style: TextStyle(fontSize: 12, color: kText2),
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
              crossFadeState: _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
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
                              icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                              label: Text(
                                S.lang == 'it' ? 'Modifica data' : 'Edit date',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => _SessionExercisePicker(session: widget.session),
                              ),
                              icon: const Icon(Icons.add, size: 18),
                              label: Text(S.lang == 'it' ? 'Aggiungi esercizio' : 'Add exercise'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...session.exercises.asMap().entries.map(
                          (entry) => _buildExerciseDetail(entry.value, entry.key),
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
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: kSurface3,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      S.lang == 'it' ? 'Aggiungi esercizio al giorno' : 'Add exercise to workout',
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
                              emoji: '',
                              title: S.get('no_exercise_found'),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (_, index) {
                                final exercise = filtered[index];
                                final alreadyAdded = widget.session.exercises.any(
                                  (item) => item.name.trim().toLowerCase() == exercise.name.trim().toLowerCase(),
                                );

                                return InkWell(
                                  borderRadius: BorderRadius.circular(12),
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
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: alreadyAdded ? kSurface2 : kBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: alreadyAdded ? kSurface3 : kSurface3,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                exercise.name,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: alreadyAdded ? kText3 : kText,
                                                ),
                                              ),
                                              if (exercise.category.isNotEmpty)
                                                Text(
                                                  exercise.category,
                                                  style: TextStyle(fontSize: 12, color: kText3),
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (alreadyAdded)
                                          Text(
                                            S.get('already_added'),
                                            style: TextStyle(fontSize: 11, color: kText3),
                                          )
                                        else
                                          Icon(Icons.add_circle_outline, color: kAccent, size: 20),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
