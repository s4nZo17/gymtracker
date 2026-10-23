// lib/screens/body_map_screen.dart
//
// Mappa del corpo: quanto hai allenato ogni gruppo muscolare in una settimana
// (serie effettive: i muscoli secondari contano meta').

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/muscle_groups.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/body_map.dart';
import '../widgets/widgets.dart';

class BodyMapScreen extends StatefulWidget {
  const BodyMapScreen({super.key});

  @override
  State<BodyMapScreen> createState() => _BodyMapScreenState();
}

class _BodyMapScreenState extends State<BodyMapScreen> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = _currentMonday();
  }

  DateTime _currentMonday() {
    final now = DateTime.now();
    final d = DateTime(now.year, now.month, now.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  void _prevWeek() =>
      setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));

  void _nextWeek() {
    final next = _weekStart.add(const Duration(days: 7));
    if (!next.isAfter(DateTime.now())) {
      setState(() => _weekStart = next);
    }
  }

  String _fmtSets(double sets) =>
      sets.toStringAsFixed(sets == sets.roundToDouble() ? 0 : 1);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final data = state.getWeeklyMuscleStimulation(_weekStart);
        final locale = state.prefs.language == 'en' ? 'en_US' : 'it_IT';
        final weekEnd = _weekStart.add(const Duration(days: 6));
        final isCurrent = _weekStart == _currentMonday();
        final dateLabel = isCurrent
            ? S.get('this_week')
            : '${DateFormat('d MMM', locale).format(_weekStart)} – ${DateFormat('d MMM', locale).format(weekEnd)}';
        final canGoNext =
            !_weekStart.add(const Duration(days: 7)).isAfter(DateTime.now());

        // Prima i muscoli allenati, dal piu' lavorato: la lista risponde
        // subito a "cosa ho fatto questa settimana?".
        final muscles = allMuscleGroups.toList()
          ..sort((a, b) => (data[b.id] ?? 0).compareTo(data[a.id] ?? 0));

        return ListView(
          padding: const EdgeInsets.only(top: 4, bottom: kBottomSafeSpace),
          children: [
            // Navigatore della settimana
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: kText),
                    onPressed: _prevWeek,
                  ),
                  Expanded(
                    child: Text(
                      dateLabel,
                      textAlign: TextAlign.center,
                      style: T.title,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right,
                        color: canGoNext ? kText : kSurface3),
                    onPressed: canGoNext ? _nextWeek : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            SizedBox(
              height: 360,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: kGapPage),
                child: Row(
                  children: [
                    Expanded(
                      child: BodyMapView(
                        isFront: true,
                        stimulationData: data,
                        label: S.get('front'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: BodyMapView(
                        isFront: false,
                        stimulationData: data,
                        label: S.get('back_view'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Legenda in una riga
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kGapPage),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: [
                  _legend(StimulationLevel.low, S.get('low_stim')),
                  _legend(StimulationLevel.medium, S.get('medium_stim')),
                  _legend(StimulationLevel.high, S.get('high_stim')),
                ],
              ),
            ),

            SectionTitle(S.get('effective_sets_title')),
            Block(children: [
              ...muscles.map((m) {
                final sets = data[m.id] ?? 0;
                final level = stimulationFromSets(sets);
                final trained = sets > 0;
                return ListRow(
                  title: m.name(state.prefs.language),
                  titleColor: trained ? kText : kText2,
                  leading: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: stimulationColor(level),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  titleStyle: T.body,
                  trailing: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      trained ? _fmtSets(sets) : '—',
                      style: TextStyle(
                        fontSize: 15,
                        color: trained ? kText : kText3,
                        fontWeight: FontWeight.w600,
                        fontFeatures: kTabular,
                      ),
                    ),
                  ),
                  minHeight: 52,
                  padding: const EdgeInsets.fromLTRB(kBlockInset, 12, 12, 12),
                );
              }),
            ]),
          ],
        );
      },
    );
  }

  Widget _legend(StimulationLevel level, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: stimulationColor(level),
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: T.label),
      ],
    );
  }
}
