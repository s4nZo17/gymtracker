// lib/screens/import_screen.dart
//
// Import dal blocco note (testo o file .csv/.txt) — identico alla v1
// nel funzionamento, ripulito nell'aspetto.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../l10n/strings.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int _tabIndex = 0;
  final _textCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  WorkoutTemplate? _selectedTemplate;
  String? _fileName;
  bool _isProcessing = false;
  List<_PreviewRow>? _preview;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (_tab.index != _tabIndex && mounted) {
        setState(() => _tabIndex = _tab.index);
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        withData: false,
        withReadStream: false,
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;

      final content = await File(path).readAsString();
      setState(() {
        _fileName = result.files.single.name;
        _textCtrl.text = content;
        _errorMsg = null;
      });
      _generatePreview(content);
    } catch (e) {
      setState(() => _errorMsg = 'Errore nel leggere il file: $e');
    }
  }

  void _generatePreview(String text) {
    final state = context.read<AppState>();
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final session = state.importPreview(text, dateStr);
    if (session == null) {
      setState(() {
        _preview = null;
        _errorMsg = 'Nessun dato valido trovato. Controlla il formato.';
      });
      return;
    }
    setState(() {
      _errorMsg = null;
      _preview = session.exercises
          .map((ex) => _PreviewRow(
                name: ex.name,
                seriesCount: ex.series.length,
                summary: ex.series.map((s) => s.summary).join(' / '),
              ))
          .toList();
    });
  }

  Future<void> _doImport() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMsg = 'Nessun testo da importare!');
      return;
    }
    setState(() => _isProcessing = true);

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final state = context.read<AppState>();
    final imported = state.importFromBlocknotes(
      text,
      dateStr,
      template: _selectedTemplate,
    );

    setState(() => _isProcessing = false);

    if (imported < 0) {
      setState(() => _errorMsg = 'Errore nel parsing. Controlla il formato.');
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Importazione completata!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  '$imported esercizi importati nella sessione del ${DateFormat('d MMMM yyyy', 'it_IT').format(_selectedDate)}.'),
              const SizedBox(height: 8),
              Text('Li trovi nello Storico.',
                  style: TextStyle(color: kText2, fontSize: 13)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text('Vai allo storico',
                  style:
                      TextStyle(color: kAccent, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _pickTemplate() async {
    final state = context.read<AppState>();

    Widget option(WorkoutTemplate? t) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: AppCard(
            padding: const EdgeInsets.all(14),
            borderColor: t?.id == _selectedTemplate?.id ? kAccent : null,
            onTap: () {
              setState(() => _selectedTemplate = t);
              Navigator.pop(context);
            },
            child: Row(
              children: [
                Icon(t == null ? Icons.flash_off : Icons.flash_on,
                    size: 18,
                    color: t?.id == _selectedTemplate?.id ? kAccent : kText3),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(t?.name ?? S.get('free_workout'),
                      style: TextStyle(fontSize: 14, color: kText)),
                ),
              ],
            ),
          ),
        );

    await showAppSheet(
      context,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SheetTitle(S.get('import_day_label')),
            const SizedBox(height: 6),
            ...state.templates.map(option),
            option(null),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx)
              .colorScheme
              .copyWith(primary: kAccent, surface: kSurface),
        ),
        child: child!,
      ),
    );
    if (d != null) {
      setState(() => _selectedDate = d);
      if (_textCtrl.text.isNotEmpty) _generatePreview(_textCtrl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(title: const Text('Importa allenamento')),
      body: Column(
        children: [
          // Formato supportato
          Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kAccent.withValues(alpha: 0.05),
              border: Border.all(color: kAccent.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: kAccent, size: 14),
                    const SizedBox(width: 6),
                    Text('FORMATO SUPPORTATO',
                        style: TextStyle(
                            fontSize: 10,
                            color: kAccent,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'nome esercizio,peso,rep,peso,rep,...',
                  style: TextStyle(
                      fontSize: 12, color: kText2, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 4),
                Text(
                  '- * = con aiuto   - peso-drop,rep-rep = drop set\n'
                  'Es: pulley,79,8*,79,7*\n'
                  'Es: pec fly,93,8*,93-59,7*-ced',
                  style: TextStyle(fontSize: 11, color: kText3, height: 1.5),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(kGapPage, 12, kGapPage, 0),
            child: SegmentedToggle(
              labels: const ['Incolla testo', 'Da file'],
              selected: _tabIndex,
              onChanged: (i) {
                setState(() => _tabIndex = i);
                _tab.animateTo(i);
              },
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DateSelector(date: _selectedDate, onTap: _pickDate),
                      const SizedBox(height: 10),
                      _DaySelector(
                          template: _selectedTemplate, onTap: _pickTemplate),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _textCtrl,
                        maxLines: 10,
                        onChanged: (v) {
                          if (v.trim().isNotEmpty) {
                            _generatePreview(v);
                          } else {
                            setState(() => _preview = null);
                          }
                        },
                        decoration: const InputDecoration(
                          hintText:
                              'Incolla qui il tuo allenamento...\n\nes:\npulley,79,8*,79,7*\nlat,75,6,75,6\npanca piana,90,2,100,1',
                          alignLabelWithHint: true,
                        ),
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 13),
                      ),
                      if (_errorMsg != null) ...[
                        const SizedBox(height: 8),
                        Text(_errorMsg!,
                            style:
                                const TextStyle(color: kRed, fontSize: 13)),
                      ],
                      if (_preview != null) ...[
                        const SizedBox(height: 16),
                        _PreviewWidget(rows: _preview!, date: _selectedDate),
                      ],
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isProcessing ? null : _doImport,
                        child: _isProcessing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Importa nella cronologia'),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DateSelector(date: _selectedDate, onTap: _pickDate),
                      const SizedBox(height: 10),
                      _DaySelector(
                          template: _selectedTemplate, onTap: _pickTemplate),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: _pickFile,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: kSurface,
                            border: Border.all(
                                color: _fileName != null
                                    ? kAccent.withValues(alpha: 0.4)
                                    : kSurface3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _fileName != null
                                    ? Icons.check_circle_outline
                                    : Icons.upload_file_outlined,
                                color: _fileName != null ? kAccent : kText3,
                                size: 36,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _fileName ??
                                    'Tocca per scegliere un file .csv o .txt',
                                style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      _fileName != null ? kAccent : kText2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (_fileName == null)
                                Text('dal tuo telefono',
                                    style: TextStyle(
                                        fontSize: 12, color: kText3)),
                            ],
                          ),
                        ),
                      ),
                      if (_errorMsg != null) ...[
                        const SizedBox(height: 8),
                        Text(_errorMsg!,
                            style:
                                const TextStyle(color: kRed, fontSize: 13)),
                      ],
                      if (_preview != null) ...[
                        const SizedBox(height: 16),
                        _PreviewWidget(rows: _preview!, date: _selectedDate),
                      ],
                      if (_fileName != null) ...[
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _isProcessing ? null : _doImport,
                          child: _isProcessing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Importa nella cronologia'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── PREVIEW WIDGET ─────────────────────────────────────────────────────────
class _PreviewWidget extends StatelessWidget {
  final List<_PreviewRow> rows;
  final DateTime date;

  const _PreviewWidget({required this.rows, required this.date});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility_outlined, color: kAccent, size: 14),
              const SizedBox(width: 6),
              Text(
                'ANTEPRIMA · ${rows.length} esercizi trovati',
                style: TextStyle(
                    fontSize: 10,
                    color: kAccent,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...rows.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kSurface3.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.name,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          if (r.summary.isNotEmpty)
                            Text(r.summary,
                                style:
                                    TextStyle(fontSize: 12, color: kText2)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kSurface2,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${r.seriesCount} serie',
                          style: TextStyle(fontSize: 11, color: kText2)),
                    ),
                  ],
                ),
              )),
        ],
      );
}

class _PreviewRow {
  final String name;
  final int seriesCount;
  final String summary;
  _PreviewRow(
      {required this.name, required this.seriesCount, required this.summary});
}

// ─── DATE SELECTOR ──────────────────────────────────────────────────────────
/// Giorno preimpostato da assegnare alla sessione importata. Opzionale: senza
/// scelta la sessione resta libera, che è il vero stato dello storico vecchio.
class _DaySelector extends StatelessWidget {
  final WorkoutTemplate? template;
  final VoidCallback onTap;

  const _DaySelector({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: onTap,
        child: Row(
          children: [
            Icon(template == null ? Icons.flash_off : Icons.flash_on,
                color: template == null ? kText3 : kAccent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(S.get('import_day_label'),
                      style: TextStyle(
                          fontSize: 10, color: kText3, letterSpacing: 1)),
                  Text(
                    template?.name ?? S.get('free_workout'),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_outlined, color: kText3, size: 16),
          ],
        ),
      );
}

class _DateSelector extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DateSelector({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: onTap,
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, color: kAccent, size: 18),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Data allenamento',
                    style: TextStyle(
                        fontSize: 10, color: kText3, letterSpacing: 1)),
                Text(
                  DateFormat('EEEE d MMMM yyyy', 'it_IT').format(date),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.edit_outlined, color: kText3, size: 16),
          ],
        ),
      );
}
