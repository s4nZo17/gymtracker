// lib/screens/progress_screen.dart
//
// Progressi 2.0: al posto di ricerca + menu a tendina c'e una lista di
// esercizi filtrabile: tocchi l'esercizio e vedi subito i grafici.
// Stessi dati e stessi grafici della v1 (peso max, volume, sessioni recenti).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../services/app_state.dart';
import '../theme.dart';
import '../l10n/strings.dart';
import '../widgets/widgets.dart';
import 'body_map_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _mainTab;
  String _search = '';
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _mainTab = TabController(length: 2, vsync: this);
    _mainTab.addListener(() {
      if (_mainTab.index != _tabIndex && mounted) {
        setState(() => _tabIndex = _mainTab.index);
      }
    });
  }

  @override
  void dispose() {
    _mainTab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          PageHeader(
            title: S.get('progress'),
            bottom: SegmentedToggle(
              labels: [S.get('charts'), S.get('body_map')],
              selected: _tabIndex,
              onChanged: (i) {
                setState(() => _tabIndex = i);
                _mainTab.animateTo(i);
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _mainTab,
              children: [
                _buildExerciseList(),
                const BodyMapScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList() {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final exNames = state.allExerciseNames;
        final term = _search.trim().toLowerCase();
        final filteredNames = term.isEmpty
            ? exNames
            : exNames.where((n) => n.toLowerCase().contains(term)).toList();

        if (exNames.isEmpty) {
          return EmptyState(
            icon: Icons.show_chart,
            title: S.get('no_data_yet'),
            subtitle: S.get('no_data_yet_sub'),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(kGapPage, 6, kGapPage, 4),
              child: AppSearchField(
                hint: S.get('search_exercise'),
                value: _search,
                onChanged: (value) => setState(() => _search = value),
              ),
            ),
            Expanded(
              child: filteredNames.isEmpty
                  ? EmptyState(
                      icon: Icons.search_off,
                      title: S.get('no_results'),
                      subtitle: S.get('try_other_search'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                          top: 8, bottom: kBottomSafeSpace),
                      itemCount: filteredNames.length,
                      itemBuilder: (context, i) {
                        final name = filteredNames[i];
                        final data = state.getProgressData(name);
                        final lastW = data.isNotEmpty
                            ? data.last['maxWeight'] as double
                            : null;
                        final firstW = data.isNotEmpty
                            ? data.first['maxWeight'] as double
                            : null;
                        final delta = (lastW != null && firstW != null)
                            ? lastW - firstW
                            : 0.0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: kGapPage, vertical: 3),
                          child: AppCard(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 13),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ExerciseProgressScreen(exName: name),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: kText),
                                      ),
                                      if (data.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Text(
                                              '${data.length} ${S.get('total_sessions').toLowerCase()}',
                                              style: TextStyle(
                                                  fontSize: 12, color: kText2),
                                            ),
                                            if (delta.abs() > 0.01) ...[
                                              Text(' · ',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: kText3)),
                                              Icon(
                                                delta > 0
                                                    ? Icons.trending_up
                                                    : Icons.trending_down,
                                                size: 13,
                                                color:
                                                    delta > 0 ? kGreen : kRed,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                '${delta > 0 ? '+' : ''}${_fmt(delta)} kg',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      delta > 0 ? kGreen : kRed,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (lastW != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: kAccent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${_fmt(lastW)} kg',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: kAccent,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                const SizedBox(width: 4),
                                Icon(Icons.chevron_right,
                                    color: kText3, size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

String _fmt(double v) =>
    v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);

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

// ─── DETTAGLIO ESERCIZIO ────────────────────────────────────────────────────
// Pubblica: ci si arriva anche da Oggi, Storico e Libreria.

class ExerciseProgressScreen extends StatefulWidget {
  final String exName;
  const ExerciseProgressScreen({super.key, required this.exName});

  @override
  State<ExerciseProgressScreen> createState() =>
      _ExerciseProgressScreenState();
}

class _ExerciseProgressScreenState extends State<ExerciseProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int _chartIndex = 0;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (_tab.index != _chartIndex && mounted) {
        setState(() => _chartIndex = _tab.index);
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  String _formatDateLabel(String isoDate, String dateFormat) {
    final parts = isoDate.split('-');
    if (parts.length < 3) return isoDate;
    final mm = parts[1];
    final dd = parts[2];
    return dateFormat == 'dd-MM' ? '$dd-$mm' : '$mm-$dd';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final data = state.getProgressData(widget.exName);
    final dateFmt = state.prefs.dateFormat;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(title: Text(widget.exName)),
      body: data.isEmpty
          ? EmptyState(icon: Icons.show_chart, title: S.get('no_data_for'))
          : _buildContent(data, dateFmt),
    );
  }

  Widget _buildContent(List<Map<String, dynamic>> data, String dateFmt) {
    final maxW = data
        .map((d) => d['maxWeight'] as double)
        .reduce((a, b) => a > b ? a : b);
    final totalSessions = data.length;
    final lastW = data.last['maxWeight'] as double;
    final firstW = data.first['maxWeight'] as double;
    final improvement = lastW - firstW;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          kGapPage, kGapPage, kGapPage, kBottomSafeSpace),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: StatCard(
                      value: '${_fmt(maxW)} kg',
                      label: S.get('max_weight'))),
              const SizedBox(width: 10),
              Expanded(
                  child: StatCard(
                      value: '$totalSessions',
                      label: S.get('total_sessions'))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: StatCard(
                value:
                    '${improvement >= 0 ? '+' : ''}${improvement.toStringAsFixed(1)} kg',
                label: S.get('total_improvement'),
                valueColor: improvement >= 0 ? kGreen : kRed,
              )),
              const SizedBox(width: 10),
              Expanded(
                  child: StatCard(
                value: '${data.last['series']}',
                label: S.get('last_session_series'),
              )),
            ],
          ),
          const SizedBox(height: 20),
          SegmentedToggle(
            labels: [S.get('weight_tab'), S.get('volume_tab')],
            selected: _chartIndex,
            onChanged: (i) {
              setState(() => _chartIndex = i);
              _tab.animateTo(i);
            },
          ),
          const SizedBox(height: 18),
          // Il grafico sta dentro una card: cosi' ha un contorno chiaro e le
          // etichette degli assi non toccano piu' i bordi dello schermo.
          Container(
            padding: const EdgeInsets.fromLTRB(6, 18, 14, 6),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(kRadiusCard),
              border: Border.all(color: kSurface3.withValues(alpha: 0.6)),
            ),
            child: SizedBox(
              height: 232,
              child: TabBarView(
                controller: _tab,
                children: [
                  _buildWeightChart(data, dateFmt),
                  _buildVolumeChart(data, dateFmt),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SectionTitle(S.get('recent_sessions')),
          ...data.reversed.take(8).map((d) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kSurface3.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    Text(
                      _formatDateLabel(d['date'].toString(), dateFmt),
                      style: TextStyle(
                          fontSize: 13,
                          color: kText2,
                          fontFamily: 'monospace'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${d['maxWeight']} kg max · vol ${(d['totalVolume'] as double).toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 13, color: kText),
                      ),
                    ),
                    Text(
                      '${d['series']} ${S.get('series')}',
                      style: TextStyle(fontSize: 12, color: kText3),
                    ),
                  ],
                ),
              )),
        ],
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
        gridData: FlGridData(
          show: true,
          horizontalInterval: step,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: kSurface3.withValues(alpha: 0.5), strokeWidth: 0.5),
          getDrawingVerticalLine: (_) =>
              FlLine(color: kSurface3.withValues(alpha: 0.35), strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox();
                final interval = (data.length / 5).ceil().clamp(1, 10);
                // Si conta all'indietro dall'ultima sessione: cosi' l'ultima
                // data c'e' sempre ed e' distanziata come le altre. Contando in
                // avanti e poi forzando l'ultima, le due finali si sovrapponevano
                // (si leggeva "15-0722-07").
                if ((data.length - 1 - i) % interval != 0) {
                  return const SizedBox();
                }
                // fitInside tiene l'ultima data dentro al riquadro: prima
                // veniva tagliata a meta' sul bordo destro.
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  fitInside: SideTitleFitInsideData.fromTitleMeta(meta,
                      distanceFromEdge: 0),
                  space: 6,
                  child: Text(
                    _formatDateLabel(data[i]['date'].toString(), dateFmt),
                    style: TextStyle(fontSize: 10, color: kText3),
                  ),
                );
              },
              reservedSize: 24,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: step,
              getTitlesWidget: (v, meta) {
                // Salta le etichette attaccate ai bordi: sono quelle che
                // prima si accavallavano con il grafico e con le date.
                if ((maxY - v) < step * 0.4 || (v - minY) < step * 0.4) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(_fmt(v),
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 10, color: kText3)),
                );
              },
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => kSurface2,
            getTooltipItems: (spots) => spots
                .map(
                  (s) => LineTooltipItem(
                    '${s.y.toStringAsFixed(1)} kg',
                    TextStyle(
                        color: kAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                )
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: kAccent,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) {
                final radius = data.length > 15 ? 2.5 : 3.5;
                return FlDotCirclePainter(
                  radius: radius,
                  color: kAccent,
                  strokeWidth: 1.5,
                  strokeColor: kBg,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  kAccent.withValues(alpha: 0.15),
                  kAccent.withValues(alpha: 0.0)
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeChart(List<Map<String, dynamic>> data, String dateFmt) {
    final volumes = data.map((d) => d['totalVolume'] as double).toList();
    final maxV = volumes.reduce(math.max);
    final step = _niceInterval(maxV * 1.15 / 4);
    final maxY = (maxV * 1.15 / step).ceil() * step;

    return BarChart(
      BarChartData(
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          horizontalInterval: step,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: kSurface3.withValues(alpha: 0.5), strokeWidth: 0.5),
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox();
                final interval = (data.length / 5).ceil().clamp(1, 10);
                // Si conta all'indietro dall'ultima sessione: cosi' l'ultima
                // data c'e' sempre ed e' distanziata come le altre. Contando in
                // avanti e poi forzando l'ultima, le due finali si sovrapponevano
                // (si leggeva "15-0722-07").
                if ((data.length - 1 - i) % interval != 0) {
                  return const SizedBox();
                }
                // fitInside tiene l'ultima data dentro al riquadro: prima
                // veniva tagliata a meta' sul bordo destro.
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  fitInside: SideTitleFitInsideData.fromTitleMeta(meta,
                      distanceFromEdge: 0),
                  space: 6,
                  child: Text(
                    _formatDateLabel(data[i]['date'].toString(), dateFmt),
                    style: TextStyle(fontSize: 10, color: kText3),
                  ),
                );
              },
              reservedSize: 24,
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
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(label,
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 10, color: kText3)),
                );
              },
              reservedSize: 42,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => kSurface2,
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            fitInsideVertically: true,
            fitInsideHorizontally: true,
            getTooltipItem: (group, groupIdx, rod, rodIdx) => BarTooltipItem(
              'Vol: ${rod.toY.toStringAsFixed(0)}',
              TextStyle(
                  color: kAccent2, fontWeight: FontWeight.w600, fontSize: 13),
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
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          kAccent2.withValues(alpha: 0.4),
                          kAccent2.withValues(alpha: 0.8)
                        ],
                      ),
                      width: data.length > 12 ? 8 : (data.length > 6 ? 12 : 20),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ))
            .toList(),
      ),
    );
  }
}
