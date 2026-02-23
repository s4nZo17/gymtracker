// lib/screens/import_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../theme.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _textCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _fileName;
  bool _isProcessing = false;
  List<_PreviewRow>? _preview;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  // â”€â”€â”€ FILE PICKER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
        _fileName = result.files.single.name;        _textCtrl.text = content;
        _errorMsg = null;
      });
      _generatePreview(content);
    } catch (e) {
      setState(() => _errorMsg = 'Errore nel leggere il file: $e');
    }
  }

  // â”€â”€â”€ PREVIEW â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
      _preview = session.exercises.map((ex) => _PreviewRow(
        name: ex.name,
        seriesCount: ex.series.length,
        summary: ex.series.map((s) => s.summary).join(' / '),
      )).toList();
    });
  }

  // â”€â”€â”€ IMPORT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _doImport() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMsg = 'Nessun testo da importare!');
      return;
    }
    setState(() => _isProcessing = true);

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final state = context.read<AppState>();
    final imported = state.importFromBlocknotes(text, dateStr);

    setState(() => _isProcessing = false);

    if (imported < 0) {
      setState(() => _errorMsg = 'Errore nel parsing. Controlla il formato.');
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: kSurface,
          title: const Text('Importazione completata!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$imported esercizi importati nella sessione del ${DateFormat('d MMMM yyyy', 'it_IT').format(_selectedDate)}.'),
              const SizedBox(height: 8),
              Text('Li trovi nello Storico.', style: TextStyle(color: kText2, fontSize: 13)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text('Vai allo storico', style: TextStyle(color: kAccent)),
            ),
          ],
        ),
      );
    }
  }

  // â”€â”€â”€ DATE PICKER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(primary: kAccent, onPrimary: Colors.black, surface: kSurface),
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
      appBar: AppBar(title: Text('Importa allenamento')),
      body: Column(
        children: [
          // Format info banner
          Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kAccent.withValues(alpha: 0.05),
              border: Border.all(color: kAccent.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: kAccent, size: 14),
                    SizedBox(width: 6),
                    Text('FORMATO SUPPORTATO', style: TextStyle(fontSize: 10, color: kAccent, letterSpacing: 1)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'nome esercizio,peso,rep,peso,rep,...',
                  style: TextStyle(fontSize: 12, color: kText2, fontFamily: 'monospace'),
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

          // Tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Container(
              decoration: BoxDecoration(color: kSurface2, borderRadius: BorderRadius.circular(12)),
              child: TabBar(
                controller: _tab,
                labelColor: Colors.black,
                unselectedLabelColor: kText2,
                indicator: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(10)),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [Tab(text: 'Incolla testo'), Tab(text: 'Da file')],
              ),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                // â”€â”€â”€ TAB 1: PASTE TEXT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DateSelector(date: _selectedDate, onTap: _pickDate),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _textCtrl,
                        maxLines: 10,
                        onChanged: (v) {
                          if (v.trim().isNotEmpty) _generatePreview(v);
                          else setState(() => _preview = null);
                        },
                        decoration: InputDecoration(
                          hintText: 'Incolla qui il tuo allenamento...\n\nes:\npulley,79,8*,79,7*\nlat,75,6,75,6\npanca piana,90,2,100,1',
                          alignLabelWithHint: true,
                        ),
                        style: TextStyle(fontFamily: 'monospace', fontSize: 13),
                      ),
                      if (_errorMsg != null) ...[
                        const SizedBox(height: 8),
                        Text(_errorMsg!, style: TextStyle(color: kRed, fontSize: 13)),
                      ],
                      if (_preview != null) ...[
                        const SizedBox(height: 16),
                        _PreviewWidget(rows: _preview!, date: _selectedDate),
                      ],
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isProcessing ? null : _doImport,
                        child: _isProcessing
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : Text('Importa nella cronologia'),
                      ),
                    ],
                  ),
                ),

                // â”€â”€â”€ TAB 2: FILE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DateSelector(date: _selectedDate, onTap: _pickDate),
                      const SizedBox(height: 14),

                      // File picker button
                      GestureDetector(
                        onTap: _pickFile,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: kSurface,
                            border: Border.all(color: _fileName != null ? kAccent.withValues(alpha: 0.4) : kSurface3, style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _fileName != null ? Icons.check_circle_outline : Icons.upload_file_outlined,
                                color: _fileName != null ? kAccent : kText3,
                                size: 36,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _fileName ?? 'Tocca per scegliere un file .csv o .txt',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _fileName != null ? kAccent : kText2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (_fileName == null)
                                Text('dal tuo telefono', style: TextStyle(fontSize: 12, color: kText3)),
                            ],
                          ),
                        ),
                      ),

                      if (_errorMsg != null) ...[
                        const SizedBox(height: 8),
                        Text(_errorMsg!, style: TextStyle(color: kRed, fontSize: 13)),
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
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                              : Text('Importa nella cronologia'),
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

// â”€â”€â”€ PREVIEW WIDGET â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                'ANTEPRIMA - ${rows.length} esercizi trovati',
                style: TextStyle(fontSize: 10, color: kAccent, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...rows.map((r) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kSurface3),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      if (r.summary.isNotEmpty)
                        Text(r.summary, style: TextStyle(fontSize: 12, color: kText2)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kSurface2, borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${r.seriesCount} serie', style: TextStyle(fontSize: 11, color: kText2)),
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
  _PreviewRow({required this.name, required this.seriesCount, required this.summary});
}

// â”€â”€â”€ DATE SELECTOR â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _DateSelector extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DateSelector({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kSurface3),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined, color: kAccent, size: 18),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Data allenamento', style: TextStyle(fontSize: 10, color: kText3, letterSpacing: 1)),
                  Text(
                    DateFormat('EEEE d MMMM yyyy', 'it_IT').format(date),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const Spacer(),
              Icon(Icons.edit_outlined, color: kText3, size: 16),
            ],
          ),
        ),
      );
}


