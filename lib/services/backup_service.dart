// lib/services/backup_service.dart
//
// Backup automatico/manuale dei dati dell'app.
// I backup sono cartelle con timestamp dentro <cartella dati>/backups/.
// Sono sfogliabili da PC/file manager. La funzione "esporta" usa la
// condivisione di sistema per mandarne una copia FUORI dal telefono,
// così resta al sicuro anche in caso di disinstallazione.

import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
  static const List<String> _dataFiles = [
    'storico.json',
    'storico.csv',
    'esercizi.json',
    'esercizi.csv',
    'templates.json',
    'preferences.json',
  ];

  /// File condivisi nell'esportazione manuale (i più utili a recuperare tutto).
  static const List<String> _exportFiles = [
    'storico.json',
    'storico.csv',
    'esercizi.json',
    'templates.json',
  ];

  static const int maxBackups = 30;

  Directory? _cachedBase;

  Future<Directory> _baseDir() async {
    if (_cachedBase != null) return _cachedBase!;
    Directory dir;
    if (Platform.isAndroid) {
      final ext = await getExternalStorageDirectory();
      if (ext != null) {
        dir = Directory('${ext.path}${Platform.pathSeparator}gymTracker');
      } else {
        final docs = await getApplicationDocumentsDirectory();
        dir = Directory('${docs.path}${Platform.pathSeparator}gymTracker');
      }
    } else {
      final docs = await getApplicationDocumentsDirectory();
      dir = Directory('${docs.path}${Platform.pathSeparator}gymTracker');
    }
    if (!await dir.exists()) await dir.create(recursive: true);
    _cachedBase = dir;
    return dir;
  }

  Future<Directory> backupsRoot() async {
    final base = await _baseDir();
    final dir = Directory('${base.path}${Platform.pathSeparator}backups');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  String _stamp(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}${two(t.month)}${two(t.day)}_'
        '${two(t.hour)}${two(t.minute)}${two(t.second)}';
  }

  /// Crea uno snapshot dei file dati in backups/<timestamp>[_tag]/.
  /// Ritorna il percorso della cartella creata, o null se non c'è nulla da salvare.
  Future<String?> createBackup({String? tag}) async {
    final base = await _baseDir();

    // Niente da salvare se non esiste ancora lo storico.
    final storico = File('${base.path}${Platform.pathSeparator}storico.json');
    if (!await storico.exists()) return null;

    final root = await backupsRoot();
    final name = tag != null && tag.isNotEmpty
        ? '${_stamp(DateTime.now())}_$tag'
        : _stamp(DateTime.now());
    final dest = Directory('${root.path}${Platform.pathSeparator}$name');
    if (!await dest.exists()) await dest.create(recursive: true);

    for (final f in _dataFiles) {
      final src = File('${base.path}${Platform.pathSeparator}$f');
      if (await src.exists()) {
        await src.copy('${dest.path}${Platform.pathSeparator}$f');
      }
    }

    await _prune(root);
    return dest.path;
  }

  Future<void> _prune(Directory root) async {
    final entries = await root.list().toList();
    final dirs = entries.whereType<Directory>().toList();
    if (dirs.length <= maxBackups) return;
    // I nomi con timestamp si ordinano cronologicamente.
    dirs.sort((a, b) => a.path.compareTo(b.path));
    final toRemove = dirs.length - maxBackups;
    for (var i = 0; i < toRemove; i++) {
      try {
        await dirs[i].delete(recursive: true);
      } catch (_) {}
    }
  }

  /// Lista dei backup, dal più recente al più vecchio.
  Future<List<Directory>> listBackups() async {
    final root = await backupsRoot();
    final dirs = (await root.list().toList()).whereType<Directory>().toList();
    dirs.sort((a, b) => b.path.compareTo(a.path));
    return dirs;
  }

  Future<int> backupCount() async => (await listBackups()).length;

  Future<DateTime?> lastBackupTime() async {
    final dirs = await listBackups();
    if (dirs.isEmpty) return null;
    try {
      return (await dirs.first.stat()).modified;
    } catch (_) {
      return null;
    }
  }

  /// Condivide i file dati con la condivisione di sistema così l'utente può
  /// salvarli fuori dal telefono. Ritorna true se c'era qualcosa da esportare.
  Future<bool> exportAndShare() async {
    final base = await _baseDir();
    final files = <XFile>[];
    for (final f in _exportFiles) {
      final src = File('${base.path}${Platform.pathSeparator}$f');
      if (await src.exists()) files.add(XFile(src.path));
    }
    if (files.isEmpty) return false;
    await Share.shareXFiles(files, subject: 'Backup GymTracker');
    return true;
  }
}
