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
//
// Il record non c'e' piu': in palestra serve sapere cosa hai fatto l'ultima
// volta, il massimo di sempre si guarda in Progressi.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  final Series? editSeries;
  final String dateFormat;
  final Function(Series) onSave;

  const SeriesSheet({
    super.key,
    required this.exerciseName,
    required this.seriesNumber,
    this.history = ExerciseHistory.empty,
    this.currentDayName,
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
  bool _missingValues = false;

  // Al tocco il numero si seleziona tutto: si scrive quello nuovo senza
  // cancellare prima. Senza stepper grandi la tastiera e' il modo principale.
  final _weightFocus = FocusNode();
  final _repsFocus = FocusNode();

  void _selectAllOnFocus(FocusNode node, TextEditingController ctrl) {
    node.addListener(() {
      if (!node.hasFocus) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ctrl.selection =
            TextSelection(baseOffset: 0, extentOffset: ctrl.text.length);
      });
    });
  }

  final List<_DropControllers> _dropCtrls = [];

  @override
  void initState() {
    super.initState();
    final s = widget.editSeries;
    _weightCtrl = TextEditingController(text: s != null ? formatWeight(s.weight) : '');
    _repsCtrl = TextEditingController(text: s?.reps ?? '');
    _type = s?.type ?? SeriesType.normal;
    _selectAllOnFocus(_weightFocus, _weightCtrl);
    _selectAllOnFocus(_repsFocus, _repsCtrl);

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
    _weightFocus.dispose();
    _repsFocus.dispose();
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
    if (_missingValues) setState(() => _missingValues = false);
    if (w == null || r.isEmpty) {
      // L'errore sta nello sheet: una snackbar finirebbe dietro, invisibile.
      setState(() => _missingValues = true);
      HapticFeedback.heavyImpact();
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

  /// Riquadro di un numero (peso o reps): etichetta piccola, numero grande da
  /// scrivere con la tastiera, e ai lati un "−" e un "+" piccoli e spenti per
  /// le correzioni al volo. Passo 1: si sale spesso di uno, e su molte
  /// macchine il peso e' in libbre, dove i 2.5 kg non hanno senso.
  Widget _numberBox({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
    TextInputType? keyboardType,
  }) {
    Widget nudge(IconData icon, VoidCallback onTap) => InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kRadius),
          child: SizedBox(
            width: 36,
            height: 52,
            child: Icon(icon, size: 20, color: kText2),
          ),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
      decoration: BoxDecoration(
        color: kSurface2,
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: Column(
        children: [
          Text(label.toUpperCase(), style: T.section),
          Row(
            children: [
              nudge(Icons.remove, onMinus),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: keyboardType ??
                      const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: T.number.copyWith(fontSize: 40, letterSpacing: -1),
                  decoration: const InputDecoration(
                    filled: false,
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
              nudge(Icons.add, onPlus),
            ],
          ),
        ],
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
    final fallbackHits = _fallbackHits;

    return Padding(
      padding: const EdgeInsets.fromLTRB(kGapPage, 0, kGapPage, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 18),
          Text.rich(
            TextSpan(children: [
              TextSpan(text: widget.exerciseName),
              TextSpan(
                text: '   ${S.get('series_n')} ${widget.seriesNumber}',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w400, color: kText2),
              ),
            ]),
            style: T.title.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),

          // Riga principale: l'ultima volta nello STESSO giorno preimpostato.
          if (sameDay != null)
            LastSessionCard(
              date:
                  '${sameDay.dayName ?? S.get('free_workout')} · ${formatShortDate(sameDay.sessionDate, widget.dateFormat)}',
              series: sameDay.series,
              currentSeriesIndex: widget.seriesNumber - 1,
              onUseSeries: () => _fillFromHit(sameDay),
            ),

          if (fallbackHits.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              // In un giorno preimpostato senza precedenti va detto perche'
              // i numeri qui sotto arrivano da un'altra giornata.
              inPresetDay && sameDay == null
                  ? S.get('first_time_in_day')
                  : (sameDay != null
                      ? S.get('last_other_day')
                      : S.get('last_occurrences')),
              style: TextStyle(fontSize: 13, color: kText2),
            ),
            ...fallbackHits.map(
              (hit) => HistoryHitRow(
                dayName: hit.dayName,
                dateLabel: formatShortDate(hit.sessionDate, widget.dateFormat),
                series: hit.series,
                secondary: sameDay != null,
                onUse: () => _fillFromHit(hit),
              ),
            ),
            const SizedBox(height: 14),
          ],

          if (fallbackHits.isEmpty) const SizedBox(height: 14),
          // Peso e reps affiancati: lo sheet e' piu' corto e "Salva serie"
          // resta visibile anche con la tastiera aperta.
          Row(
            children: [
              Expanded(
                child: _numberBox(
                  controller: _weightCtrl,
                  focusNode: _weightFocus,
                  label: S.get('weight_kg'),
                  onMinus: () => _stepWeight(-1),
                  onPlus: () => _stepWeight(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                // Le reps restano testo: accettano anche "ced".
                child: _numberBox(
                  controller: _repsCtrl,
                  focusNode: _repsFocus,
                  label: S.get('reps'),
                  onMinus: () => _stepReps(-1),
                  onPlus: () => _stepReps(1),
                  keyboardType: TextInputType.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tipo serie: tre pastiglie. Il colore compare solo se scegli un
          // tipo speciale, ed e' lo stesso del segno che vedrai nella lista.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Pill(
                label: S.get('normal'),
                selected: _type == SeriesType.normal,
                onTap: () => _setType(SeriesType.normal),
              ),
              Pill(
                label: S.get('with_help'),
                selected: _type == SeriesType.help,
                color: kOrange,
                onTap: () => _setType(SeriesType.help),
              ),
              Pill(
                label: S.get('drop_set'),
                selected: _type == SeriesType.drop,
                color: kBlue,
                onTap: () => _setType(SeriesType.drop),
              ),
            ],
          ),

          if (_type == SeriesType.drop) ...[
            const SizedBox(height: 14),
            ..._dropCtrls.asMap().entries.map((entry) {
              final idx = entry.key;
              final dc = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        'D${idx + 1}',
                        style: const TextStyle(
                            fontSize: 13,
                            color: kBlue,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: dc.weight,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          hintText: S.get('drop_weight'),
                          isDense: true,
                        ),
                        style: TextStyle(
                            fontSize: 16, color: kText, fontFeatures: kTabular),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: dc.reps,
                        decoration: InputDecoration(
                          hintText: S.get('drop_reps'),
                          isDense: true,
                        ),
                        style: TextStyle(
                            fontSize: 16, color: kText, fontFeatures: kTabular),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeDropField(idx),
                      icon: Icon(Icons.close, size: 18, color: kText3),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: _addDropField,
              style: TextButton.styleFrom(
                foregroundColor: kBlue,
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.add, size: 18),
              label: Text(S.get('add_drop')),
            ),
          ],

          const SizedBox(height: 18),
          if (_missingValues)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(S.get('insert_weight_reps'),
                  style: const TextStyle(color: kRed, fontSize: 13.5)),
            ),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              textStyle:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            child: Text(widget.editSeries != null
                ? S.get('update_series')
                : S.get('save_series')),
          ),
        ],
      ),
    );
  }
}


class _DropControllers {
  final TextEditingController weight;
  final TextEditingController reps;
  _DropControllers({required this.weight, required this.reps});
}
