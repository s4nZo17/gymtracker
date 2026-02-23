// lib/services/storage_service.dart

import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

import '../models/models.dart';

class StorageService {
  static const String _prefsFile = 'preferences.json';
  static const String _workoutsJsonFile = 'storico.json';
  static const String _workoutsCsvFile = 'storico.csv';
  static const String _libraryJsonFile = 'esercizi.json';
  static const String _libraryCsvFile = 'esercizi.csv';

  Directory? _cachedBaseDir;

  Future<String> getBasePath() async => (await _baseDir()).path;

  Future<AppPreferences> loadPreferences() async {
    final raw = await _readJson(_prefsFile);
    if (raw is Map) {
      return AppPreferences.fromJson(Map<String, dynamic>.from(raw));
    }
    return const AppPreferences();
  }

  Future<void> savePreferences(AppPreferences prefs) async {
    await _writeJson(_prefsFile, prefs.toJson());
  }

  Future<List<WorkoutSession>> loadWorkouts() async {
    final raw = await _readJson(_workoutsJsonFile);
    if (raw is! List) return [];

    final sessions = <WorkoutSession>[];
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        sessions.add(WorkoutSession.fromJson(item));
      } else if (item is Map) {
        sessions.add(WorkoutSession.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    sessions.removeWhere((s) => s.date.trim().isEmpty);
    return sessions;
  }

  Future<void> saveWorkouts(List<WorkoutSession> workouts) async {
    await _writeJson(
      _workoutsJsonFile,
      workouts.map((w) => w.toJson()).toList(),
    );
    await _writeWorkoutsCsv(workouts);
  }

  Future<List<LibraryExercise>> loadLibrary() async {
    final raw = await _readJson(_libraryJsonFile);
    if (raw is! List) return [];

    final items = <LibraryExercise>[];
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        items.add(LibraryExercise.fromJson(item));
      } else if (item is Map) {
        items.add(LibraryExercise.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    items.removeWhere((e) => e.name.trim().isEmpty);
    return items;
  }

  Future<void> saveLibrary(List<LibraryExercise> library) async {
    await _writeJson(
      _libraryJsonFile,
      library.map((e) => e.toJson()).toList(),
    );
    await _writeLibraryCsv(library);
  }

  Future<File> _file(String name) async {
    final dir = await _baseDir();
    return File('${dir.path}${Platform.pathSeparator}$name');
  }

  Future<Directory> _baseDir() async {
    if (_cachedBaseDir != null) return _cachedBaseDir!;

    final resolved = await _resolveBaseDir();
    if (!await resolved.exists()) {
      await resolved.create(recursive: true);
    }
    _cachedBaseDir = resolved;
    return resolved;
  }

  Future<Directory> _resolveBaseDir() async {
    if (Platform.isAndroid) {
      final ext = await getExternalStorageDirectory();
      if (ext != null) {
        final scopedDir = Directory('${ext.path}${Platform.pathSeparator}gymTracker');
        if (!await scopedDir.exists()) {
          await scopedDir.create(recursive: true);
        }
        return scopedDir;
      }
    }

    final docs = await getApplicationDocumentsDirectory();
    return Directory('${docs.path}${Platform.pathSeparator}gymTracker');
  }

  Future<dynamic> _readJson(String fileName) async {
    try {
      final f = await _file(fileName);
      if (!await f.exists()) return null;
      final text = await f.readAsString();
      if (text.trim().isEmpty) return null;
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeJson(String fileName, Object data) async {
    final f = await _file(fileName);
    final encoder = const JsonEncoder.withIndent('  ');
    await f.writeAsString(encoder.convert(data), flush: true);
  }

  Future<void> _writeWorkoutsCsv(List<WorkoutSession> workouts) async {
    final rows = <List<dynamic>>[
      ['date', 'exercise', 'set', 'type', 'weight', 'reps', 'drops'],
    ];

    for (final session in workouts) {
      for (final ex in session.exercises) {
        for (var i = 0; i < ex.series.length; i++) {
          final s = ex.series[i];
          final drops = s.drops.map((d) => '${formatWeight(d.weight)}x${d.reps}').join(' | ');
          rows.add([
            session.date,
            ex.name,
            i + 1,
            seriesTypeToString(s.type),
            formatWeight(s.weight),
            s.reps,
            drops,
          ]);
        }
      }
    }

    final csv = const ListToCsvConverter().convert(rows);
    final f = await _file(_workoutsCsvFile);
    await f.writeAsString(csv, flush: true);
  }

  Future<void> _writeLibraryCsv(List<LibraryExercise> library) async {
    final rows = <List<dynamic>>[
      ['id', 'name', 'category'],
      ...library.map((e) => [e.id, e.name, e.category]),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final f = await _file(_libraryCsvFile);
    await f.writeAsString(csv, flush: true);
  }
}
