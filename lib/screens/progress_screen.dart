// lib/screens/progress_screen.dart
//
// Progressi: la libreria esercizi e i loro progressi in un posto solo.
//
// Prima "Esercizi" e "Progressi" erano due schede con la stessa lista (nome +
// peso massimo) che portavano allo stesso grafico. Ora c'e' una lista sola:
// tocchi un esercizio e apri la sua scheda, con grafici, sessioni recenti e le
// azioni per modificarlo o eliminarlo. Accanto, la mappa del corpo.

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/exercise_editor_sheet.dart';
import '../widgets/widgets.dart';
import 'body_map_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _tab = 0;
  String _search = '';
  String _category = '';

  void _newExercise(AppState state) {
    showAppSheet(context, child: ExerciseEditorSheet(state: state));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          PageHeader(
            title: S.get('progress'),
            meta: '${state.library.length} ${S.get('exercises_count')}',
            bottom: SegmentedToggle(
              labels: [S.get('exercises'), S.get('body_map')],
              selected: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _tab == 0
                  ? KeyedSubtree(
                      key: const ValueKey('list'), child: _buildList(state))
                  : const BodyMapScreen(key: ValueKey('map')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(AppState state) {
    final summaries = state.exerciseSummaries();
    final categories = <String>{
      for (final e in state.library)
        if (e.category.trim().isNotEmpty) e.category.trim(),
    }.toList()
      ..sort();

    final term = _search.trim().toLowerCase();
    final filtered = state.library.where((e) {
      final matchesSearch = term.isEmpty ||
          e.name.toLowerCase().contains(term) ||
          e.category.toLowerCase().contains(term);
      final matchesCat = _category.isEmpty || e.category == _category;
      return matchesSearch && matchesCat;
    }).toList();

    final grouped = <String, List<LibraryExercise>>{};
    for (final ex in filtered) {
      final cat = ex.category.isNotEmpty ? ex.category : S.get('uncategorized');
      grouped.putIfAbsent(cat, () => []).add(ex);
    }

    return Column(
      children: [
        // Ricerca e, accanto, il "+" per un esercizio nuovo.
        Padding(
          padding: const EdgeInsets.fromLTRB(kGapPage, 0, kGapPage, 12),
          child: Row(
            children: [
              Expanded(
                child: AppSearchField(
                  hint: S.get('search_exercise'),
                  value: _search,
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const SizedBox(width: 8),
              SquareIconButton(
                icon: PlusIcon(size: 22),
                tooltip: S.get('new'),
                onTap: () => _newExercise(state),
              ),
            ],
          ),
        ),
        CategoryFilterBar(
          categories: categories,
          selected: _category,
          onChanged: (c) => setState(() => _category = c),
        ),
        Expanded(
          child: filtered.isEmpty
              ? EmptyState(
                  title: state.library.isEmpty
                      ? S.get('no_exercise_found_lib')
                      : S.get('no_results'),
                  subtitle: state.library.isEmpty
                      ? S.get('library_empty_sub')
                      : S.get('try_other_search'),
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: kBottomSafeSpace),
                  children: [
                    for (final entry in grouped.entries) ...[
                      SectionTitle(entry.key),
                      Block(children: [
                        for (final ex in entry.value)
                          _row(ex, summaries[ex.name.trim().toLowerCase()]),
                      ]),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _row(LibraryExercise ex, ExerciseSummary? sum) {
    Widget? subtitle;
    if (sum != null) {
      final delta = sum.delta;
      subtitle = Text.rich(
        TextSpan(children: [
          TextSpan(
              text:
                  '${sum.sessions} ${S.get(sum.sessions == 1 ? 'session_short' : 'sessions_short')}'),
          if (delta.abs() > 0.01)
            TextSpan(
              text: ' · ${delta > 0 ? '+' : '−'}${fmtNum(delta.abs())} kg',
              style: TextStyle(
                color: delta > 0 ? kGreen : kRed,
                fontWeight: FontWeight.w500,
              ),
            ),
        ]),
        style: T.meta.copyWith(fontFeatures: kTabular),
      );
    }

    return ListRow(
      title: ex.name,
      subtitleWidget: subtitle,
      subtitle: sum == null ? S.get('never_trained') : null,
      minHeight: 70,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (sum != null)
            Text('${fmtNum(sum.bestMax)} kg',
                style: TextStyle(
                    fontSize: 15,
                    color: kText,
                    fontWeight: FontWeight.w600,
                    fontFeatures: kTabular)),
          const SizedBox(width: 6),
          RowChevron(),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExerciseProgressScreen(exName: ex.name),
        ),
      ),
    );
  }
}

/// Numero senza decimali inutili: 80, 82.5.
String fmtNum(double v) => v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);

/// Passo "tondo" per gli assi (1, 2.5, 5, 10, 25, 50, 100...): senza questo
/// fl_chart sceglieva valori come 236 o 11.5 e le etichette si accavallavano.
double _niceInterval(double raw) {
  if (raw <= 0) return 1;
  final exp = (math.log(raw) / math.ln10).floor();
  final magnitude = math.pow(10, exp).toDouble();
  final norm = raw / magnitude;
  final step = norm <= 1
      ? 1.0
      : norm <= 2
          ? 2.0
          : norm <= 2.5
              ? 2.5
              : norm <= 5
                  ? 5.0
                  : 10.0;
  return step * magnitude;
}

// ─── SCHEDA ESERCIZIO ───────────────────────────────────────────────────────
// Ci si arriva da Progressi, da Oggi e dallo Storico (menu dell'esercizio).

class ExerciseProgressScreen extends StatefulWidget {
  final String exName;
  const ExerciseProgressScreen({super.key, required this.exName});

  @override
  State<ExerciseProgressScreen> createState() => _ExerciseProgressScreenState();
}

class _ExerciseProgressScreenState extends State<ExerciseProgressScreen> {
  late String _name = widget.exName;
  int _chartIndex = 0;

  String _formatDateLabel(String isoDate, String dateFormat) {
    final parts = isoDate.split('-');
    if (parts.length < 3) return isoDate;
    final mm = parts[1];
    final dd = parts[2];
    return dateFormat == 'dd-MM' ? '$dd/$mm' : '$mm/$dd';
  }

  LibraryExercise? _libraryEntry(AppState state) {
    final key = _name.trim().toLowerCase();
    for (final e in state.library) {
      if (e.name.trim().toLowerCase() == key) return e;
    }
    return null;
  }

  void _showMenu(AppState state, LibraryExercise ex) {
    showActionSheet(
      context,
      title: ex.name,
      actions: [
        SheetAction(
          icon: Icons.edit_outlined,
          label: S.get('edit'),
          onTap: () => showAppSheet(
            context,
            child: ExerciseEditorSheet(
              state: state,
              existing: ex,
              onSaved: (name) => setState(() => _name = name),
            ),
          ),
        ),
        SheetAction(
          icon: Icons.delete_outline,
          label: S.get('remove_from_library'),
          destructive: true,
          onTap: () async {
            final ok = await confirmDialog(
              context,
              title: '${S.get('remove_from_library')}?',
              message: S.get('remove_from_library_desc'),
              confirmText: S.get('delete'),
              destructive: true,
            );
            if (!ok || !mounted) return;
            state.removeFromLibrary(ex.id);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final data = state.getProgressData(_name);
    final dateFmt = state.prefs.dateFormat;
    final entry = _libraryEntry(state);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        actions: [
          if (entry != null)
            IconButton(
              onPressed: () => _showMenu(state, entry),
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
            padding: const EdgeInsets.fromLTRB(kGapPage, 8, kGapPage, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_name,
                    style: T.display.copyWith(fontSize: 36, letterSpacing: -1)),
                if (entry != null && muscleSummary(entry).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(muscleSummary(entry),
                      style: T.meta.copyWith(fontSize: 15)),
                ],
              ],
            ),
          ),
          if (data.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: EmptyState(
                title: S.get('no_data_for'),
                subtitle: S.get('no_data_yet_sub'),
              ),
            )
          else
            ..._buildContent(data, dateFmt),
        ],
      ),
    );
  }

  List<Widget> _buildContent(List<Map<String, dynamic>> data, String dateFmt) {
    final maxW = data
        .map((d) => d['maxWeight'] as double)
        .reduce((a, b) => a > b ? a : b);
    final lastW = data.last['maxWeight'] as double;
    final firstW = data.first['maxWeight'] as double;
    final improvement = lastW - firstW;

    return [
      const SizedBox(height: 24),
      StatsBlock(metrics: [
        Metric(value: '${fmtNum(maxW)} kg', label: S.get('record')),
        Metric(value: '${data.length}', label: S.get('total_sessions')),
        Metric(
          value:
              '${improvement >= 0 ? '+' : '−'}${fmtNum(improvement.abs())} kg',
          label: S.get('total_improvement'),
          valueColor:
              improvement > 0 ? kGreen : (improvement < 0 ? kRed : null),
        ),
      ]),
      SectionTitle(
        _chartIndex == 0 ? S.get('weight_tab') : S.get('volume_tab'),
        trailing: SegmentedToggle(
          compact: true,
          labels: [S.get('weight_short'), S.get('volume_tab')],
          selected: _chartIndex,
          onChanged: (i) => setState(() => _chartIndex = i),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: kGapPage),
        child: AppCard(
          padding: const EdgeInsets.fromLTRB(8, 18, 16, 8),
          child: SizedBox(
            height: 200,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _chartIndex == 0
                  ? KeyedSubtree(
                      key: const ValueKey('w'),
                      child: _buildWeightChart(data, dateFmt))
                  : KeyedSubtree(
                      key: const ValueKey('v'),
                      child: _buildVolumeChart(data, dateFmt)),
            ),
          ),
        ),
      ),
      SectionTitle(S.get('recent_sessions')),
      Block(children: [
        for (final d in data.reversed.take(8))
          ListRow(
            title: '${fmtNum(d['maxWeight'] as double)} kg',
            titleStyle: T.title.copyWith(fontSize: 16),
            subtitle:
                '${d['series']} ${S.get('series')} · ${S.get('volume_tab').toLowerCase()} ${(d['totalVolume'] as double).toStringAsFixed(0)}',
            trailing: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                _formatDateLabel(d['date'].toString(), dateFmt),
                style: T.meta.copyWith(fontFeatures: kTabular),
              ),
            ),
            minHeight: 66,
          ),
      ]),
    ];
  }

  Widget _dateTitle(List<Map<String, dynamic>> data, double v, TitleMeta meta,
      String dateFmt) {
    final i = v.toInt();
    if (i < 0 || i >= data.length || v != i.toDouble()) {
      return const SizedBox();
    }
    final interval = (data.length / 4).ceil().clamp(1, 10);
    // Si conta all'indietro dall'ultima sessione: cosi' l'ultima data c'e'
    // sempre ed e' distanziata come le altre.
    if ((data.length - 1 - i) % interval != 0) return const SizedBox();
    return SideTitleWidget(
      axisSide: meta.axisSide,
      fitInside:
          SideTitleFitInsideData.fromTitleMeta(meta, distanceFromEdge: 0),
      space: 8,
      child: Text(
        _formatDateLabel(data[i]['date'].toString(), dateFmt),
        style: TextStyle(fontSize: 10.5, color: kText3, fontFeatures: kTabular),
      ),
    );
  }

  Widget _buildWeightChart(List<Map<String, dynamic>> data, String dateFmt) {
    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), (e.value['maxWeight'] as double)))
        .toList();

    final weights = data.map((d) => d['maxWeight'] as double).toList();
    final minW = weights.reduce(math.min);
    final maxW = weights.reduce(math.max);
    final range = maxW - minW;
    final padding = range > 0 ? range * 0.15 : maxW * 0.2;
    // Assi allineati a valori tondi: l'etichetta piu' in alto non viene piu'
    // tagliata e quella in basso non si accavalla sulle date.
    final step = _niceInterval((range > 0 ? range : maxW * 0.4) / 3);
    final minY = ((minW - padding) / step).floor() * step;
    final maxY = ((maxW + padding) / step).ceil() * step;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        minX: 0,
        maxX: math.max(1, data.length - 1).toDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: step,
          getDrawingHorizontalLine: (_) => FlLine(color: kLine, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (v, meta) => _dateTitle(data, v, meta, dateFmt),
              reservedSize: 26,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: step,
              getTitlesWidget: (v, meta) {
                if ((maxY - v) < step * 0.4 || (v - minY) < step * 0.4) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(fmtNum(v),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 10.5,
                          color: kText3,
                          fontFeatures: kTabular)),
                );
              },
              reservedSize: 40,
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          getTouchedSpotIndicator: (bar, indexes) => indexes
              .map((_) => TouchedSpotIndicatorData(
                    FlLine(color: kSurface3, strokeWidth: 1),
                    FlDotData(
                      getDotPainter: (s, _, __, ___) => FlDotSquarePainter(
                        size: 8,
                        color: kAccent,
                        strokeWidth: 2,
                        strokeColor: kSurface,
                      ),
                    ),
                  ))
              .toList(),
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => kText,
            tooltipRoundedRadius: kRadius,
            getTooltipItems: (spots) => spots
                .map(
                  (s) => LineTooltipItem(
                    '${fmtNum(s.y)} kg\n${_formatDateLabel(data[s.x.toInt()]['date'].toString(), dateFmt)}',
                    TextStyle(
                        color: kBg, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                )
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            // Linea spezzata: con lo stesso esercizio in giorni diversi i
            // valori saltano, e la curva inventava onde che non esistono.
            isCurved: false,
            color: kAccent,
            barWidth: 2.2,
            isStrokeCapRound: true,
            // Solo l'ultimo punto: e' quello che conta.
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, _) => spot.x == spots.last.x,
              // Quadratino, non pallino: niente forme tonde nell'app.
              getDotPainter: (spot, _, __, ___) => FlDotSquarePainter(
                size: 8,
                color: kAccent,
                strokeWidth: 0,
              ),
            ),
            // Area piena e piatta: niente sfumature.
            belowBarData: BarAreaData(
              show: true,
              color: kAccent.withValues(alpha: 0.10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeChart(List<Map<String, dynamic>> data, String dateFmt) {
    final volumes = data.map((d) => d['totalVolume'] as double).toList();
    final maxV = volumes.reduce(math.max);
    final step = _niceInterval(math.max(1, maxV) * 1.15 / 4);
    final maxY = (math.max(1, maxV) * 1.15 / step).ceil() * step;

    return BarChart(
      BarChartData(
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          horizontalInterval: step,
          getDrawingHorizontalLine: (_) => FlLine(color: kLine, strokeWidth: 1),
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) => _dateTitle(data, v, meta, dateFmt),
              reservedSize: 26,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: step,
              getTitlesWidget: (v, _) {
                if ((maxY - v) < step * 0.4 || v < step * 0.4) {
                  return const SizedBox();
                }
                final label = v >= 1000
                    ? '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}k'
                    : '${v.round()}';
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(label,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 10.5,
                          color: kText3,
                          fontFeatures: kTabular)),
                );
              },
              reservedSize: 40,
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => kText,
            tooltipRoundedRadius: kRadius,
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            fitInsideVertically: true,
            fitInsideHorizontally: true,
            getTooltipItem: (group, groupIdx, rod, rodIdx) => BarTooltipItem(
              rod.toY.toStringAsFixed(0),
              TextStyle(color: kBg, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ),
        barGroups: data
            .asMap()
            .entries
            .map((e) => BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: (e.value['totalVolume'] as double),
                      color: e.key == data.length - 1
                          ? kAccent
                          : kAccent.withValues(alpha: 0.35),
                      width: data.length > 12 ? 7 : (data.length > 6 ? 11 : 18),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                ))
            .toList(),
      ),
    );
  }
}
