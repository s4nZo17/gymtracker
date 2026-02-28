// lib/screens/today_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../l10n/strings.dart';
import '../widgets/widgets.dart';
import '../widgets/series_sheet.dart';
import 'exercise_picker_screen.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final session = state.todaySession;
        final locale = state.prefs.language == 'en' ? 'en_US' : 'it_IT';
        final sessionDate = DateTime.tryParse(session.date) ?? DateTime.now();
        final dateStr = DateFormat('EEEE d MMMM', locale).format(sessionDate);

        return Scaffold(
          backgroundColor: kBg,
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 8, 20, 12),
                  child: Row(
                    children: [
                      Text(dateStr, style: TextStyle(fontSize: 13, color: kText2)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: kSurface,
                              title: Text('${S.get('new_day')}?', style: TextStyle(color: kText)),
                              content: Text(S.get('new_day_confirm'), style: TextStyle(color: kText2)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: Text(S.get('cancel'))),
                                TextButton(
                                  onPressed: () {
                                    state.startNewDay();
                                    Navigator.pop(context);
                                  },
                                  child: Text(S.get('confirm'), style: TextStyle(color: kAccent)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color: kAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            S.get('new_day'),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (session.exercises.isEmpty)
                SliverFillRemaining(
                  child: EmptyState(emoji: '', title: S.get('no_exercises')),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _ExerciseCard(exIdx: i),
                    childCount: session.exercises.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExercisePickerScreen()),
            ),
            backgroundColor: kAccent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.add, size: 28),
          ),
        );
      },
    );
  }
}

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
    ExerciseLog? lastLog, {
    int? seriesIndex,
  }) {
    final editSeries = seriesIndex == null ? null : exercise.series[seriesIndex];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SeriesSheet(
        exerciseName: exercise.name,
        seriesNumber: seriesIndex == null ? exercise.series.length + 1 : seriesIndex + 1,
        lastSeries: lastLog?.series,
        editSeries: editSeries,
        onSave: (series) {
          if (seriesIndex == null) {
            state.addSeries(widget.exIdx, series);
          } else {
            state.updateSeries(widget.exIdx, seriesIndex, series);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final ex = state.todaySession.exercises[widget.exIdx];
        final lastLog = state.getLastExerciseLog(ex.name);

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
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ex.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kText)),
                              const SizedBox(height: 2),
                              Text(
                                ex.series.isEmpty
                                    ? S.get('no_series')
                                    : '${ex.series.length} ${S.get('series')} - ${ex.series.map((s) => '${s.weight}x${s.reps}').join(' / ')}',
                                style: TextStyle(fontSize: 12, color: kText2),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: kText3, size: 20),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: kSurface,
                                content: Text('${S.get('delete_exercise')} ${ex.name}?', style: TextStyle(color: kText)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: Text(S.get('cancel'))),
                                  TextButton(
                                    onPressed: () {
                                      state.removeExerciseFromToday(widget.exIdx);
                                      Navigator.pop(context);
                                    },
                                    child: Text(S.get('delete'), style: const TextStyle(color: kRed)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        AnimatedRotation(
                          turns: _expanded ? 0 : -0.5,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(Icons.keyboard_arrow_down, color: kText3),
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
                        if (ex.series.isNotEmpty) ...[
                          Table(
                            columnWidths: const {
                              0: FixedColumnWidth(36),
                              1: FlexColumnWidth(2),
                              2: FlexColumnWidth(3),
                              3: FixedColumnWidth(64),
                            },
                            children: [
                              TableRow(
                                children: ['', S.get('weight_kg').split(' ').first, S.get('reps'), ''].map((h) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(h, style: TextStyle(fontSize: 10, color: kText3, letterSpacing: 1)),
                                )).toList(),
                              ),
                              ...ex.series.asMap().entries.map((e) {
                                final s = e.value;
                                final i = e.key;
                                return TableRow(
                                  decoration: BoxDecoration(
                                    border: Border(top: BorderSide(color: kSurface3, width: 0.5)),
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: SeriesNumBadge(i + 1),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Text('${s.weight} kg', style: TextStyle(fontSize: 14, color: kText)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Text('${s.reps} rep', style: TextStyle(fontSize: 14, color: kText)),
                                          SeriesBadge(s.type),
                                          if (s.type == SeriesType.drop && s.drops.isNotEmpty)
                                            DropsDisplay(s.drops),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: GestureDetector(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            GestureDetector(
                                              onTap: () => _openSeriesSheet(
                                                context,
                                                state,
                                                ex,
                                                lastLog,
                                                seriesIndex: i,
                                              ),
                                              child: Icon(Icons.edit_outlined, size: 16, color: kText3),
                                            ),
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap: () => state.removeSeries(widget.exIdx, i),
                                              child: Icon(Icons.close, size: 16, color: kText3),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],

                        GestureDetector(
                          onTap: () => _openSeriesSheet(context, state, ex, lastLog),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: kSurface2,
                              border: Border.all(color: kSurface3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              S.get('add_series'),
                              style: TextStyle(fontSize: 13, color: kText2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  secondChild: const SizedBox(height: 8),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


