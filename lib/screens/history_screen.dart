// lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../l10n/strings.dart';
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
    final dt = DateTime.parse(d);
    return DateFormat(fmt, locale).format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final dateLabel = _formatDate(s.date);
    final totalSeries = s.totalSeries;

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
                      '${s.exercises.length} ${S.get('exercises_count')} · $totalSeries ${S.get('total_series')}',
                      style: TextStyle(fontSize: 12, color: kText2),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6, runSpacing: 4,
                      children: s.exercises.map((ex) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: kSurface2,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(ex.name, style: TextStyle(fontSize: 12, color: kText2)),
                      )).toList(),
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
                  children: s.exercises.map((ex) => _ExerciseDetail(ex: ex)).toList(),
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

class _ExerciseDetail extends StatelessWidget {
  final ExerciseLog ex;
  const _ExerciseDetail({required this.ex});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kSurface2,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ex.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kText)),
            const SizedBox(height: 6),
            ...ex.series.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  SeriesNumBadge(e.key + 1),
                  const SizedBox(width: 8),
                  Text('${e.value.weight} kg × ${e.value.reps}', style: TextStyle(fontSize: 13, color: kText)),
                  SeriesBadge(e.value.type),
                  if (e.value.type == SeriesType.drop && e.value.drops.isNotEmpty)
                    DropsDisplay(e.value.drops),
                ],
              ),
            )),
          ],
        ),
      );
}

