// lib/screens/body_map_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/muscle_groups.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/body_map.dart';

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

  void _prevWeek() => setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));
  void _nextWeek() {
    final next = _weekStart.add(const Duration(days: 7));
    if (!next.isAfter(DateTime.now())) {
      setState(() => _weekStart = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final data = state.getWeeklyMuscleStimulation(_weekStart);
        final locale = state.prefs.language == 'en' ? 'en_US' : 'it_IT';
        final weekEnd = _weekStart.add(const Duration(days: 6));
        final dateLabel = '${DateFormat('d MMM', locale).format(_weekStart)} - ${DateFormat('d MMM', locale).format(weekEnd)}';

        final canGoNext = !_weekStart.add(const Duration(days: 7)).isAfter(DateTime.now());

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              kGapPage, 8, kGapPage, kBottomSafeSpace),
          child: Column(
            children: [
              // Week selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kSurface3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left, color: kText2),
                      onPressed: _prevWeek,
                    ),
                    Column(
                      children: [
                        Text(
                          S.get('week_of'),
                          style: TextStyle(fontSize: 10, color: kText3, letterSpacing: 1),
                        ),
                        Text(
                          dateLabel,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kText),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right, color: canGoNext ? kText2 : kSurface3),
                      onPressed: canGoNext ? _nextWeek : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Le due sagome stanno dentro una card come tutto il resto
              // dell'app: prima erano appoggiate sul fondo nudo.
              Container(
                height: 380,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(kRadiusCard),
                  border: Border.all(color: kSurface3.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: BodyMapView(
                        isFront: true,
                        stimulationData: data,
                        label: S.get('front').toUpperCase(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BodyMapView(
                        isFront: false,
                        stimulationData: data,
                        label: S.get('back_view').toUpperCase(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Legend
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kSurface3),
                ),
                child: Column(
                  children: [
                    _legendRow(StimulationLevel.none, S.get('not_trained')),
                    const SizedBox(height: 6),
                    _legendRow(StimulationLevel.low, S.get('low_stim')),
                    const SizedBox(height: 6),
                    _legendRow(StimulationLevel.medium, S.get('medium_stim')),
                    const SizedBox(height: 6),
                    _legendRow(StimulationLevel.high, S.get('high_stim')),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Detailed muscle list
              ...allMuscleGroups.map((m) {
                final sets = data[m.id] ?? 0;
                final level = stimulationFromSets(sets);
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kSurface3),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: stimulationColor(level),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          m.name(state.prefs.language),
                          style: TextStyle(fontSize: 14, color: kText),
                        ),
                      ),
                      Text(
                        '${sets.toStringAsFixed(sets == sets.roundToDouble() ? 0 : 1)} ${S.get('effective_sets')}',
                        style: TextStyle(fontSize: 12, color: kText2),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _legendRow(StimulationLevel level, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: stimulationColor(level),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 13, color: kText2)),
      ],
    );
  }
}
