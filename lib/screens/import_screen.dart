// lib/screens/import_screen.dart
//
// Import dal blocco note: un modulo solo. Prima c'erano due tab ("Incolla
// testo" / "Da file") con lo stesso modulo ripetuto due volte; ora il file
// riempie lo stesso campo di testo, che resta modificabile prima di importare.
//
// A import fatto la pagina si chiude con `true`: chi l'ha aperta porta
// l'utente nello Storico, dove sono finiti i dati.

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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

class _ImportScreenState extends State<ImportScreen> {
  final _textCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  WorkoutTemplate? _selectedTemplate;
  String? _fileName;
  WorkoutSession? _preview;
  String? _errorMsg;

  String get _locale => S.lang == 'en' ? 'en_US' : 'it_IT';

  @override
  void dispose() {
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
      });
      _generatePreview(content);
    } catch (e) {
      setState(() => _errorMsg = '${S.get('import_file_error')}: $e');
    }
  }

  void _generatePreview(String text) {
    if (text.trim().isEmpty) {
      setState(() {
        _preview = null;
        _errorMsg = null;
      });
      return;
    }
    final state = context.read<AppState>();
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final session = state.importPreview(text, dateStr);
    setState(() {
      _preview = session;
      _errorMsg = session == null ? S.get('import_nothing_valid') : null;
    });
  }

  void _doImport() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _preview == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final imported = context.read<AppState>().importFromBlocknotes(
          text,
          dateStr,
          template: _selectedTemplate,
        );

    if (imported < 0) {
      setState(() => _errorMsg = S.get('import_nothing_valid'));
      return;
    }
    Navigator.pop(context, true);
  }

  Future<void> _pickTemplate() async {
    final state = context.read<AppState>();
    await showAppSheet(
      context,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SheetTitle(S.get('import_day_label')),
            Block(children: [
              for (final t in [...state.templates, null])
                Builder(
                  builder: (sheetContext) => ListRow(
                    title: t?.name ?? S.get('free_workout_long'),
                    titleColor: t == null ? kText2 : null,
                    trailing: t?.id == _selectedTemplate?.id
                        ? Icon(Icons.check, size: 22, color: kAccentText)
                        : const SizedBox(width: 22),
                    onTap: () {
                      setState(() => _selectedTemplate = t);
                      Navigator.pop(sheetContext);
                    },
                  ),
                ),
            ]),
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
    );
    if (d != null) {
      setState(() => _selectedDate = d);
      _generatePreview(_textCtrl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final dateLabel = DateFormat('EEEE d MMMM yyyy', _locale).format(_selectedDate);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(kGapPage, 8, kGapPage, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.get('import_blocknotes'),
                    style: T.display.copyWith(fontSize: 34, letterSpacing: -1)),
                const SizedBox(height: 10),
                Text(S.get('import_format_help'),
                    style: T.meta.copyWith(height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Block(children: [
            ListRow(
              title: S.get('import_date_label'),
              titleStyle: T.body,
              trailing: Flexible(
                child: Text(
                  dateLabel[0].toUpperCase() + dateLabel.substring(1),
                  textAlign: TextAlign.right,
                  style: T.meta.copyWith(color: kTextSoft),
                ),
              ),
              onTap: _pickDate,
            ),
            if (state.templates.isNotEmpty)
              ListRow(
                title: S.get('import_day_label'),
                titleStyle: T.body,
                trailing: Text(
                  _selectedTemplate?.name ?? S.get('free_workout_long'),
                  style: T.meta.copyWith(color: kTextSoft),
                ),
                onTap: _pickTemplate,
              ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(kGapPage, 16, kGapPage, 0),
            child: TextField(
              controller: _textCtrl,
              maxLines: 10,
              minLines: 6,
              onChanged: _generatePreview,
              decoration: InputDecoration(
                hintText: S.get('import_paste_hint'),
                alignLabelWithHint: true,
                fillColor: blockColor,
              ),
              style: TextStyle(
                  fontFamily: 'monospace', fontSize: 13, color: kText),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(kGapPage - 8, 4, kGapPage, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _pickFile,
                style: TextButton.styleFrom(foregroundColor: kText2),
                icon: const Icon(Icons.attach_file, size: 18),
                label: Text(_fileName ?? S.get('import_from_file')),
              ),
            ),
          ),
          if (_errorMsg != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(kGapPage, 4, kGapPage, 0),
              child: Text(_errorMsg!,
                  style: const TextStyle(color: kRed, fontSize: 13)),
            ),
          if (_preview != null) ...[
            SectionTitle(
                '${S.get('preview')} · ${_preview!.exercises.length} ${S.get('exercises_count')}'),
            Block(children: [
              ..._preview!.exercises.map(
                (ex) => ListRow(
                  title: ex.name,
                  subtitle: ex.series.map((s) => s.summary).join('   '),
                ),
              ),
            ]),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(kGapPage, 8, kGapPage, 12),
          child: ElevatedButton(
            onPressed: _preview == null ? null : _doImport,
            child: Text(S.get('import_into_history')),
          ),
        ),
      ),
    );
  }
}
