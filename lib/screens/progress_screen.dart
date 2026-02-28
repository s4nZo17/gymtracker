// lib/screens/progress_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../services/app_state.dart';
import '../theme.dart';
import '../l10n/strings.dart';
import '../widgets/widgets.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String? _selectedEx;
  String _search = '';

  bool _matchesSearch(String name, String term) {
    final cleanTerm = term.trim().toLowerCase();
    if (cleanTerm.isEmpty) return true;
    return name.toLowerCase().contains(cleanTerm);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final exNames = state.allExerciseNames;
        final filteredNames = exNames.where((name) => _matchesSearch(name, _search)).toList();

        if (_selectedEx != null && !exNames.contains(_selectedEx)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _selectedEx = null);
          });
        }

        final selectedEx = filteredNames.contains(_selectedEx) ? _selectedEx : null;

        return Scaffold(
          backgroundColor: kBg,
          appBar: AppBar(title: Text(S.get('progress'))),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _search = value;
                      if (_selectedEx != null && !_matchesSearch(_selectedEx!, value)) {
                        _selectedEx = null;
                      }
                    });
                  },
                  decoration: InputDecoration(
                    hintText: S.get('search_exercise'),
                    prefixIcon: Icon(Icons.search, color: kText3),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kSurface3),
                  ),
                  child: DropdownButton<String>(
                    value: selectedEx,
                    hint: Text(S.get('select_exercise'), style: TextStyle(color: kText2)),
                    isExpanded: true,
                    underline: const SizedBox(),
                    dropdownColor: kSurface,
                    items: filteredNames.map((n) => DropdownMenuItem(
                      value: n,
                      child: Text(n, style: TextStyle(color: kText)),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedEx = v),
                  ),
                ),
              ),
              if (selectedEx == null)
                Expanded(
                  child: exNames.isEmpty
                      ? EmptyState(emoji: '', title: S.get('no_data_yet'))
                      : filteredNames.isEmpty
                          ? EmptyState(emoji: '', title: S.get('no_exercise_found'))
                      : EmptyState(emoji: '', title: S.get('select_to_see')),
                )
              else
                Expanded(child: _ChartContent(exName: selectedEx)),
            ],
          ),
        );
      },
    );
  }
}

class _ChartContent extends StatefulWidget {
  final String exName;
  const _ChartContent({required this.exName});

  @override
  State<_ChartContent> createState() => _ChartContentState();
}

class _ChartContentState extends State<_ChartContent> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  String _formatDateLabel(String isoDate, String dateFormat) {
    // isoDate = "2026-02-19" -> parts: [2026, 02, 19]
    final parts = isoDate.split('-');
    if (parts.length < 3) return isoDate;
    final mm = parts[1];
    final dd = parts[2];
    return dateFormat == 'dd-MM' ? '$dd-$mm' : '$mm-$dd';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final data = state.getProgressData(widget.exName);
    final dateFmt = state.prefs.dateFormat;

    if (data.isEmpty) {
      return EmptyState(emoji: '', title: S.get('no_data_for'));
    }

    final maxW = data.map((d) => d['maxWeight'] as double).reduce((a, b) => a > b ? a : b);
    final totalSessions = data.length;
    final lastW = data.last['maxWeight'] as double;
    final firstW = data.first['maxWeight'] as double;
    final improvement = lastW - firstW;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: StatCard(value: '${maxW.toStringAsFixed(1)} kg', label: S.get('max_weight'))),
              const SizedBox(width: 10),
              Expanded(child: StatCard(value: '$totalSessions', label: S.get('total_sessions'))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: StatCard(
                value: '${improvement >= 0 ? '+' : ''}${improvement.toStringAsFixed(1)} kg',
                label: S.get('total_improvement'),
                valueColor: improvement >= 0 ? kGreen : kRed,
              )),
              const SizedBox(width: 10),
              Expanded(child: StatCard(
                value: '${data.last['series']}',
                label: S.get('last_session_series'),
              )),
            ],
          ),
          const SizedBox(height: 20),

          Container(
            decoration: BoxDecoration(
              color: kSurface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tab,
              labelColor: Colors.white,
              unselectedLabelColor: kText2,
              indicator: BoxDecoration(
                color: kAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: [Tab(text: S.get('weight_tab')), Tab(text: S.get('volume_tab'))],
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 240,
            child: TabBarView(
              controller: _tab,
              children: [
                _buildWeightChart(data, dateFmt),
                _buildVolumeChart(data, dateFmt),
              ],
            ),
          ),

          const SizedBox(height: 20),
          SectionTitle(S.get('recent_sessions')),
          ...data.reversed.take(8).map((d) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kSurface3),
            ),
            child: Row(
              children: [
                Text(
                  _formatDateLabel(d['date'].toString(), dateFmt),
                  style: TextStyle(fontSize: 13, color: kText2, fontFamily: 'monospace'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${d['maxWeight']} kg max - vol ${(d['totalVolume'] as double).toStringAsFixed(0)}',
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
    final spots = data.asMap().entries.map((e) =>
      FlSpot(e.key.toDouble(), (e.value['maxWeight'] as double))
    ).toList();

    final weights = data.map((d) => d['maxWeight'] as double).toList();
    final minW = weights.reduce(math.min);
    final maxW = weights.reduce(math.max);
    final range = maxW - minW;
    final padding = range > 0 ? range * 0.15 : maxW * 0.2;
    final minY = (minW - padding).clamp(0.0, double.infinity);
    final maxY = maxW + padding;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (_) => FlLine(color: kSurface3, strokeWidth: 0.5),
          getDrawingVerticalLine: (_) => FlLine(color: kSurface3, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox();
                final interval = (data.length / 5).ceil().clamp(1, 10);
                if (i % interval != 0 && i != data.length - 1) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatDateLabel(data[i]['date'].toString(), dateFmt),
                    style: TextStyle(fontSize: 9, color: kText3),
                  ),
                );
              },
              reservedSize: 22,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => Text('${v.toInt()}', style: TextStyle(fontSize: 9, color: kText3)),
              reservedSize: 36,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => kSurface2,
            getTooltipItems: (spots) => spots.map((s) =>
              LineTooltipItem(
                '${s.y.toStringAsFixed(1)} kg',
                TextStyle(color: kAccent, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ).toList(),
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
                colors: [kAccent.withValues(alpha: 0.15), kAccent.withValues(alpha: 0.0)],
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
    final maxY = maxV * 1.15;

    return BarChart(
      BarChartData(
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (_) => FlLine(color: kSurface3, strokeWidth: 0.5),
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox();
                final interval = (data.length / 5).ceil().clamp(1, 10);
                if (i % interval != 0 && i != data.length - 1) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatDateLabel(data[i]['date'].toString(), dateFmt),
                    style: TextStyle(fontSize: 9, color: kText3),
                  ),
                );
              },
              reservedSize: 22,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => Text('${v.toInt()}', style: TextStyle(fontSize: 9, color: kText3)),
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => kSurface2,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            fitInsideVertically: true,
            fitInsideHorizontally: true,
            getTooltipItem: (group, groupIdx, rod, rodIdx) =>
              BarTooltipItem(
                'Vol: ${rod.toY.toStringAsFixed(0)}',
                TextStyle(color: kAccent2, fontWeight: FontWeight.w600, fontSize: 13),
              ),
          ),
        ),
        barGroups: data.asMap().entries.map((e) => BarChartGroupData(
          x: e.key,
          barRods: [
            BarChartRodData(
              toY: (e.value['totalVolume'] as double),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [kAccent2.withValues(alpha: 0.4), kAccent2.withValues(alpha: 0.8)],
              ),
              width: data.length > 12 ? 8 : (data.length > 6 ? 12 : 20),
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        )).toList(),
      ),
    );
  }
}


