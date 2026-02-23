// lib/widgets/series_sheet.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme.dart';
import '../l10n/strings.dart';
import 'widgets.dart';

class SeriesSheet extends StatefulWidget {
  final String exerciseName;
  final int seriesNumber;
  final List<Series>? lastSeries;
  final Series? editSeries;
  final Function(Series) onSave;

  const SeriesSheet({
    super.key,
    required this.exerciseName,
    required this.seriesNumber,
    this.lastSeries,
    this.editSeries,
    required this.onSave,
  });

  @override
  State<SeriesSheet> createState() => _SeriesSheetState();
}

class _SeriesSheetState extends State<SeriesSheet> {
  late TextEditingController _weightCtrl;
  late TextEditingController _repsCtrl;
  SeriesType _type = SeriesType.normal;

  // Multiple drops
  final List<_DropControllers> _dropCtrls = [];

  @override
  void initState() {
    super.initState();
    final s = widget.editSeries;
    _weightCtrl = TextEditingController(text: s?.weight.toString() ?? '');
    _repsCtrl = TextEditingController(text: s?.reps ?? '');
    _type = s?.type ?? SeriesType.normal;

    // Load existing drops
    if (s != null && s.drops.isNotEmpty) {
      for (final d in s.drops) {
        _dropCtrls.add(_DropControllers(
          weight: TextEditingController(text: d.weight.toString()),
          reps: TextEditingController(text: d.reps),
        ));
      }
    } else if (_type == SeriesType.drop) {
      _addDropField();
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
    // Pre-fill with previous drop weight minus ~20%
    String prefillWeight = '';
    if (_dropCtrls.isNotEmpty) {
      final lastDrop = double.tryParse(_dropCtrls.last.weight.text);
      if (lastDrop != null) prefillWeight = (lastDrop * 0.8).round().toString();
    } else {
      final mainWeight = double.tryParse(_weightCtrl.text);
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

  void _fillFromLast() {
    final ref = widget.lastSeries;
    if (ref == null || ref.isEmpty) return;
    final idx = (widget.seriesNumber - 1).clamp(0, ref.length - 1);
    final s = ref[idx];
    setState(() {
      _weightCtrl.text = s.weight.toString();
      _repsCtrl.text = s.reps;
      _type = s.type;

      // Clear existing drops
      for (final dc in _dropCtrls) {
        dc.weight.dispose();
        dc.reps.dispose();
      }
      _dropCtrls.clear();

      // Fill drops
      if (s.drops.isNotEmpty) {
        for (final d in s.drops) {
          _dropCtrls.add(_DropControllers(
            weight: TextEditingController(text: d.weight.toString()),
            reps: TextEditingController(text: d.reps),
          ));
        }
      }
    });
  }

  void _save() {
    final w = double.tryParse(_weightCtrl.text);
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
        final dw = double.tryParse(dc.weight.text);
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

  @override
  Widget build(BuildContext context) {
    final lastSeriesForThis = widget.lastSeries != null && widget.lastSeries!.isNotEmpty
        ? widget.lastSeries
        : null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: kSurface3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${S.get('series_n')} ${widget.seriesNumber} - ${widget.exerciseName}',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: kText,
                  letterSpacing: 0.15,
                ),
              ),
              const SizedBox(height: 16),

              // Last session hint
              if (lastSeriesForThis != null)
                LastSessionCard(
                  date: S.get('previous_session'),
                  series: lastSeriesForThis,
                  currentSeriesIndex: widget.seriesNumber - 1,
                  onUseSeries: _fillFromLast,
                ),

              // Weight & Reps
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: S.get('weight_kg')),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kText),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _repsCtrl,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(labelText: S.get('reps')),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kText),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Type selector
              Text(S.get('series_type'), style: TextStyle(fontSize: 10, letterSpacing: 2, color: kText3)),
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

              // Drop set fields (multiple)
              if (_type == SeriesType.drop) ...[
                const SizedBox(height: 14),
                ..._dropCtrls.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final dc = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        // Drop number
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: kBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'D${idx + 1}',
                            style: TextStyle(fontSize: 11, color: kBlue, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: dc.weight,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: S.get('drop_weight'),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            style: TextStyle(fontSize: 15, color: kText),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _removeDropField(idx),
                          child: Icon(Icons.close, size: 18, color: kText3),
                        ),
                      ],
                    ),
                  );
                }),
                // Add another drop button
                GestureDetector(
                  onTap: _addDropField,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: kBlue.withValues(alpha: 0.08),
                      border: Border.all(color: kBlue.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      S.get('add_drop'),
                      style: TextStyle(fontSize: 13, color: kBlue, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _save,
                child: Text(widget.editSeries != null ? S.get('update_series') : S.get('save_series')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeBtn(SeriesType type, String label) {
    final selected = _type == type;
    return GestureDetector(
      onTap: () => _setType(type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? kAccent.withValues(alpha: 0.15) : kSurface2,
          border: Border.all(color: selected ? kAccent : kSurface3),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? kAccent : kText2,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
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

