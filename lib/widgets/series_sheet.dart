// lib/widgets/series_sheet.dart
//
// Foglio per aggiungere/modificare una serie.
// Novita 2.0 (stesse funzioni, meno tap):
//  - quando aggiungi una serie i campi sono gia precompilati con i valori
//    dell'ultima volta NELLO STESSO giorno preimpostato (modificabili subito);
//  - stepper -/+ accanto a peso e reps per correggere al volo senza tastiera.
//
// I numeri mostrati sono contestuali al giorno: la stessa Pec fly a fine
// "Petto" non e' confrontabile con la Pec fly a inizio "Upper". Quando il
// contesto manca (allenamento libero, o prima volta in quel giorno) le
// occorrenze si elencano tutte, con giorno e data, e sceglie l'utente.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme.dart';
import '../l10n/strings.dart';
import 'widgets.dart';

class SeriesSheet extends StatefulWidget {
  final String exerciseName;
  final int seriesNumber;

  /// Storia contestuale dell'esercizio (stesso giorno + fallback).
  final ExerciseHistory history;

  /// Nome del giorno preimpostato della sessione in corso; null = libero.
  final String? currentDayName;

  /// Record: sempre globale, mai filtrato per giorno.
  final List<Series>? bestSeries;
  final Series? editSeries;
  final String dateFormat;
  final Function(Series) onSave;

  const SeriesSheet({
    super.key,
    required this.exerciseName,
    required this.seriesNumber,
    this.history = ExerciseHistory.empty,
    this.currentDayName,
    this.bestSeries,
    this.editSeries,
    this.dateFormat = 'dd-MM',
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required String exerciseName,
    required int seriesNumber,
    ExerciseHistory history = ExerciseHistory.empty,
    String? currentDayName,
    List<Series>? bestSeries,
    Series? editSeries,
    String dateFormat = 'dd-MM',
    required Function(Series) onSave,
  }) {
    return showAppSheet(
      context,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: SeriesSheet(
          exerciseName: exerciseName,
          seriesNumber: seriesNumber,
          history: history,
          currentDayName: currentDayName,
          bestSeries: bestSeries,
          editSeries: editSeries,
          dateFormat: dateFormat,
          onSave: onSave,
        ),
      ),
    );
  }

  @override
  State<SeriesSheet> createState() => _SeriesSheetState();
}

class _SeriesSheetState extends State<SeriesSheet> {
  late TextEditingController _weightCtrl;
  late TextEditingController _repsCtrl;
  SeriesType _type = SeriesType.normal;

  final List<_DropControllers> _dropCtrls = [];

  @override
  void initState() {
    super.initState();
    final s = widget.editSeries;
    _weightCtrl = TextEditingController(text: s != null ? formatWeight(s.weight) : '');
    _repsCtrl = TextEditingController(text: s?.reps ?? '');
    _type = s?.type ?? SeriesType.normal;

    if (s != null && s.drops.isNotEmpty) {
      for (final d in s.drops) {
        _dropCtrls.add(_DropControllers(
          weight: TextEditingController(text: formatWeight(d.weight)),
          reps: TextEditingController(text: d.reps),
        ));
      }
    } else if (_type == SeriesType.drop) {
      _addDropField();
    }

    // 2.0: precompila con i valori dell'ultima volta nello STESSO giorno
    // (stessa serie). Senza contesto non si precompila niente: le occorrenze
    // si mostrano tutte e sceglie l'utente con un tap.
    if (s == null) {
      final source = widget.history.prefillSource;
      if (source != null && source.series.isNotEmpty) {
        final idx = (widget.seriesNumber - 1).clamp(0, source.series.length - 1);
        final ref = source.series[idx];
        _weightCtrl.text = formatWeight(ref.weight);
        _repsCtrl.text = ref.reps;
      }
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    for (final dc in _dropCtrls) {
      dc.weight.dispose();
      dc.reps.dispose();
    }
    super.dispose();
  }

  void _addDropField() {
    // Prefill: peso del drop precedente meno ~20%
    String prefillWeight = '';
    if (_dropCtrls.isNotEmpty) {
      final lastDrop = double.tryParse(_dropCtrls.last.weight.text.replaceAll(',', '.'));
      if (lastDrop != null) prefillWeight = (lastDrop * 0.8).round().toString();
    } else {
      final mainWeight = double.tryParse(_weightCtrl.text.replaceAll(',', '.'));
      if (mainWeight != null) prefillWeight = (mainWeight * 0.8).round().toString();
    }
    setState(() {
      _dropCtrls.add(_DropControllers(
        weight: TextEditingController(text: prefillWeight),
        reps: TextEditingController(),
      ));
    });
  }

  void _removeDropField(int idx) {
    setState(() {
      _dropCtrls[idx].weight.dispose();
      _dropCtrls[idx].reps.dispose();
      _dropCtrls.removeAt(idx);
      if (_dropCtrls.isEmpty && _type == SeriesType.drop) {
        _type = SeriesType.normal;
      }
    });
  }

  void _fillFromHit(ExerciseHistoryHit hit) => _fillFromRef(hit.series);

  void _fillFromRef(List<Series>? ref) {
    if (ref == null || ref.isEmpty) return;
    final idx = (widget.seriesNumber - 1).clamp(0, ref.length - 1);
    final s = ref[idx];
    setState(() {
      _weightCtrl.text = formatWeight(s.weight);
      _repsCtrl.text = s.reps;
      _type = s.type;

      for (final dc in _dropCtrls) {
        dc.weight.dispose();
        dc.reps.dispose();
      }
      _dropCtrls.clear();

      if (s.drops.isNotEmpty) {
        for (final d in s.drops) {
          _dropCtrls.add(_DropControllers(
            weight: TextEditingController(text: formatWeight(d.weight)),
            reps: TextEditingController(text: d.reps),
          ));
        }
      }
    });
    HapticFeedback.selectionClick();
  }

  void _fillFromBest() => _fillFromRef(widget.bestSeries);

  void _stepWeight(double delta) {
    final current = double.tryParse(_weightCtrl.text.replaceAll(',', '.')) ?? 0;
    final next = (current + delta).clamp(0, 999).toDouble();
    setState(() => _weightCtrl.text = formatWeight(next));
    HapticFeedback.selectionClick();
  }

  void _stepReps(int delta) {
    final current = int.tryParse(_repsCtrl.text.trim()) ?? 0;
    final next = (current + delta).clamp(0, 99);
    setState(() => _repsCtrl.text = next.toString());
    HapticFeedback.selectionClick();
  }

  void _save() {
    final w = double.tryParse(_weightCtrl.text.replaceAll(',', '.'));
    final r = _repsCtrl.text.trim();
    if (w == null || r.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.get('insert_weight_reps')), backgroundColor: kRed),
      );
      return;
    }

    List<DropEntry> drops = [];
    if (_type == SeriesType.drop) {
      for (final dc in _dropCtrls) {
        final dw = double.tryParse(dc.weight.text.replaceAll(',', '.'));
        final dr = dc.reps.text.trim();
        if (dw != null) {
          drops.add(DropEntry(weight: dw, reps: dr.isNotEmpty ? dr : 'ced'));
        }
      }
    }

    widget.onSave(Series(
      weight: w,
      reps: r,
      type: _type,
      drops: drops.isNotEmpty ? drops : null,
    ));
    Navigator.pop(context);
  }

  void _setType(SeriesType type) {
    setState(() {
      _type = type;
      if (type == SeriesType.drop && _dropCtrls.isEmpty) {
        _addDropField();
      }
    });
  }

  Widget _stepBtn(String label, VoidCallback onTap) {
    return Material(
      color: kSurface2,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kText2),
          ),
        ),
      ),
    );
  }

  Widget _fieldWithSteppers({
    required TextEditingController controller,
    required String label,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
    required String minusLabel,
    required String plusLabel,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10.5,
            letterSpacing: 1.4,
            color: kText3,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _stepBtn(minusLabel, onMinus),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: keyboardType ??
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: kText,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _stepBtn(plusLabel, onPlus),
          ],
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          letterSpacing: 1.4,
          color: kText3,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Le occorrenze da elencare sotto il riquadro principale: una sola (l'ultima
  /// volta in un altro giorno) se il giorno ha già dato un riferimento, tutte
  /// le ultime se il contesto manca.
  List<ExerciseHistoryHit> get _fallbackHits {
    final history = widget.history;
    if (history.sameDay != null) {
      final elsewhere = history.lastElsewhere;
      return elsewhere == null ? const [] : [elsewhere];
    }
    return history.anyDay;
  }

  @override
  Widget build(BuildContext context) {
    final history = widget.history;
    final sameDay = history.sameDay;
    final inPresetDay = widget.currentDayName != null;
    final hasBest = widget.bestSeries != null && widget.bestSeries!.isNotEmpty;
    final fallbackHits = _fallbackHits;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          Text(
            widget.exerciseName,
            style: GoogleFonts.inter(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: kText,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${S.get('series_n')} ${widget.seriesNumber}',
            style: TextStyle(fontSize: 13, color: kText2),
          ),
          const SizedBox(height: 14),

          // Riga principale: l'ultima volta nello STESSO giorno preimpostato.
          // Senza contesto resta solo il record (globale) con la sua card.
          if (sameDay != null)
            LastSessionCard(
              date:
                  '${sameDay.dayName ?? S.get('free_workout')} · ${formatShortDate(sameDay.sessionDate, widget.dateFormat)}',
              series: sameDay.series,
              bestSeries: widget.bestSeries,
              currentSeriesIndex: widget.seriesNumber - 1,
              onUseSeries: () => _fillFromHit(sameDay),
              onUseBestSeries: _fillFromBest,
            )
          else if (hasBest)
            LastSessionCard(
              date: '',
              series: const [],
              bestSeries: widget.bestSeries,
              currentSeriesIndex: widget.seriesNumber - 1,
              onUseBestSeries: _fillFromBest,
            ),

          // In un giorno preimpostato senza precedenti va detto perche' i
          // numeri qui sotto arrivano da un'altra giornata.
          if (inPresetDay && sameDay == null && fallbackHits.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: kText3),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      S.get('first_time_in_day'),
                      style: TextStyle(fontSize: 12, color: kText3),
                    ),
                  ),
                ],
              ),
            ),

          if (fallbackHits.isNotEmpty) ...[
            _sectionLabel(sameDay != null
                ? S.get('last_other_day')
                : S.get('last_occurrences')),
            ...fallbackHits.map(
              (hit) => HistoryHitRow(
                dayName: hit.dayName,
                dateLabel: formatShortDate(hit.sessionDate, widget.dateFormat),
                series: hit.series,
                secondary: sameDay != null,
                onUse: () => _fillFromHit(hit),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Peso con stepper -/+ 2.5 kg
          _fieldWithSteppers(
            controller: _weightCtrl,
            label: S.get('weight_kg'),
            onMinus: () => _stepWeight(-2.5),
            onPlus: () => _stepWeight(2.5),
            minusLabel: '-2.5',
            plusLabel: '+2.5',
          ),
          const SizedBox(height: 14),

          // Reps con stepper -/+ 1 (il campo resta testo: accetta "ced" ecc.)
          _fieldWithSteppers(
            controller: _repsCtrl,
            label: S.get('reps'),
            onMinus: () => _stepReps(-1),
            onPlus: () => _stepReps(1),
            minusLabel: '-1',
            plusLabel: '+1',
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 16),

          Text(
            S.get('series_type'),
            style: TextStyle(
              fontSize: 10.5,
              letterSpacing: 1.4,
              color: kText3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _typeBtn(SeriesType.normal, S.get('normal'))),
              const SizedBox(width: 8),
              Expanded(child: _typeBtn(SeriesType.help, S.get('with_help'))),
              const SizedBox(width: 8),
              Expanded(child: _typeBtn(SeriesType.drop, S.get('drop_set'))),
            ],
          ),

          if (_type == SeriesType.drop) ...[
            const SizedBox(height: 14),
            ..._dropCtrls.asMap().entries.map((entry) {
              final idx = entry.key;
              final dc = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: kBlue.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'D${idx + 1}',
                        style: const TextStyle(
                            fontSize: 11, color: kBlue, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: dc.weight,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: S.get('drop_weight'),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        style: TextStyle(fontSize: 15, color: kText),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: dc.reps,
                        decoration: InputDecoration(
                          labelText: S.get('drop_reps'),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        style: TextStyle(fontSize: 15, color: kText),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => _removeDropField(idx),
                      icon: Icon(Icons.close, size: 18, color: kText3),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              );
            }),
            OutlinedButton.icon(
              onPressed: _addDropField,
              style: OutlinedButton.styleFrom(
                foregroundColor: kBlue,
                side: BorderSide(color: kBlue.withValues(alpha: 0.35)),
                minimumSize: const Size(double.infinity, 44),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: Text(S.get('add_drop')),
            ),
          ],

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _save,
            child: Text(widget.editSeries != null
                ? S.get('update_series')
                : S.get('save_series')),
          ),
        ],
      ),
    );
  }

  Widget _typeBtn(SeriesType type, String label) {
    final selected = _type == type;
    // Ogni tipo usa il proprio colore, lo stesso del badge che comparira'
    // nella lista: cosi' si impara la codifica scegliendo, non leggendo.
    final color = switch (type) {
      SeriesType.normal => kAccent,
      SeriesType.help => kOrange,
      SeriesType.drop => kBlue,
    };
    return GestureDetector(
      onTap: () => _setType(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : kSurface2,
          border: Border.all(color: selected ? color : Colors.transparent),
          borderRadius: BorderRadius.circular(kRadiusControl),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: selected ? color : kText2,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _DropControllers {
  final TextEditingController weight;
  final TextEditingController reps;
  _DropControllers({required this.weight, required this.reps});
}
