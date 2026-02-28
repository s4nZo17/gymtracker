// lib/services/app_state.dart

import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/models.dart';
import '../theme.dart';
import 'storage_service.dart';

class AppState extends ChangeNotifier {
  AppState({StorageService? storageService}) : _storage = storageService ?? StorageService();

  final StorageService _storage;

  bool isLoading = true;
  bool _initialized = false;
  String storageBasePath = '';

  AppPreferences prefs = const AppPreferences();
  final List<WorkoutSession> workouts = [];
  final List<LibraryExercise> library = [];
  WorkoutSession? _activeSession;

  bool get needsSetup => !prefs.setupCompleted;
  Color? get customAccentColor => parseHexColor(prefs.customAccentHex);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      storageBasePath = await _storage.getBasePath();
      prefs = await _storage.loadPreferences();
      _applyPreferences();

      workouts
        ..clear()
        ..addAll(await _storage.loadWorkouts());

      library
        ..clear()
        ..addAll(await _storage.loadLibrary());

      if (library.isEmpty) {
        library.addAll(_defaultLibrary());
        await _storage.saveLibrary(library);
      }

      _ensureActiveSessionExists();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  WorkoutSession get todaySession => _ensureActiveSessionExists();

  List<String> get allExerciseNames {
    final names = <String>{};
    for (final session in workouts) {
      for (final ex in session.exercises) {
        if (ex.series.isNotEmpty) names.add(ex.name);
      }
    }

    final sorted = names.toList();
    sorted.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sorted;
  }

  void updatePreferences(AppPreferences newPrefs) {
    prefs = newPrefs;
    _applyPreferences();
    _persistPreferences();
    notifyListeners();
  }

  void setLanguage(String language) {
    if (prefs.language == language) return;
    prefs = prefs.copyWith(language: language);
    _applyPreferences();
    _persistPreferences();
    notifyListeners();
  }

  void setThemeMode(String mode) {
    if (prefs.themeMode == mode) return;
    prefs = prefs.copyWith(themeMode: mode);
    _applyPreferences();
    _persistPreferences();
    notifyListeners();
  }

  void setAccentPreset(String presetId) {
    if (prefs.accentPreset == presetId) return;
    prefs = prefs.copyWith(accentPreset: presetId);
    _applyPreferences();
    _persistPreferences();
    notifyListeners();
  }

  void setCustomAccentColor(Color color) {
    final hex = colorToHexString(color);
    if (prefs.accentPreset == 'custom' && prefs.customAccentHex == hex) return;
    prefs = prefs.copyWith(
      accentPreset: 'custom',
      customAccentHex: hex,
    );
    _applyPreferences();
    _persistPreferences();
    notifyListeners();
  }

  void setDateFormat(String format) {
    if (prefs.dateFormat == format) return;
    prefs = prefs.copyWith(dateFormat: format);
    _persistPreferences();
    notifyListeners();
  }

  void startNewDay() {
    final today = _todayIso();
    final current = _ensureActiveSessionExists();
    if (current.date == today && current.exercises.isEmpty) return;

    if (workouts.isNotEmpty) {
      final last = workouts.last;
      if (last.date == today && last.exercises.isEmpty) {
        _activeSession = last;
        notifyListeners();
        return;
      }
    }

    final created = WorkoutSession(date: today);
    workouts.add(created);
    _activeSession = created;
    _persistWorkouts();
    notifyListeners();
  }

  void addExerciseToToday(String exerciseName) {
    addExerciseToSession(todaySession, exerciseName);
  }

  void removeExerciseFromToday(int exerciseIndex) {
    removeExerciseFromSession(todaySession, exerciseIndex);
  }

  void addSeries(int exerciseIndex, Series series) {
    addSeriesToSession(todaySession, exerciseIndex, series);
  }

  void removeSeries(int exerciseIndex, int seriesIndex) {
    removeSeriesFromSession(todaySession, exerciseIndex, seriesIndex);
  }

  void updateSeries(int exerciseIndex, int seriesIndex, Series series) {
    updateSeriesInSession(todaySession, exerciseIndex, seriesIndex, series);
  }

  bool addExerciseToSession(WorkoutSession session, String exerciseName) {
    final name = exerciseName.trim();
    if (name.isEmpty) return false;

    final targetSession = _resolveSession(session);
    if (targetSession == null) return false;

    final exists = targetSession.exercises.any((ex) => _sameName(ex.name, name));
    if (exists) return false;

    targetSession.exercises.add(ExerciseLog(name: name));
    _persistWorkouts();
    notifyListeners();
    return true;
  }

  bool updateExerciseNameInSession(WorkoutSession session, int exerciseIndex, String exerciseName) {
    final name = exerciseName.trim();
    if (name.isEmpty) return false;

    final targetSession = _resolveSession(session);
    if (targetSession == null) return false;
    if (exerciseIndex < 0 || exerciseIndex >= targetSession.exercises.length) return false;

    final duplicate = targetSession.exercises.asMap().entries.any(
      (entry) => entry.key != exerciseIndex && _sameName(entry.value.name, name),
    );
    if (duplicate) return false;

    targetSession.exercises[exerciseIndex].name = name;
    _persistWorkouts();
    notifyListeners();
    return true;
  }

  void removeExerciseFromSession(WorkoutSession session, int exerciseIndex) {
    final targetSession = _resolveSession(session);
    if (targetSession == null) return;
    if (exerciseIndex < 0 || exerciseIndex >= targetSession.exercises.length) return;

    targetSession.exercises.removeAt(exerciseIndex);
    _persistWorkouts();
    notifyListeners();
  }

  void addSeriesToSession(WorkoutSession session, int exerciseIndex, Series series) {
    final targetSession = _resolveSession(session);
    if (targetSession == null) return;
    if (exerciseIndex < 0 || exerciseIndex >= targetSession.exercises.length) return;

    targetSession.exercises[exerciseIndex].series.add(series);
    _persistWorkouts();
    notifyListeners();
  }

  void updateSeriesInSession(WorkoutSession session, int exerciseIndex, int seriesIndex, Series series) {
    final targetSession = _resolveSession(session);
    if (targetSession == null) return;
    if (exerciseIndex < 0 || exerciseIndex >= targetSession.exercises.length) return;

    final targetSeries = targetSession.exercises[exerciseIndex].series;
    if (seriesIndex < 0 || seriesIndex >= targetSeries.length) return;

    targetSeries[seriesIndex] = series;
    _persistWorkouts();
    notifyListeners();
  }

  void removeSeriesFromSession(WorkoutSession session, int exerciseIndex, int seriesIndex) {
    final targetSession = _resolveSession(session);
    if (targetSession == null) return;
    if (exerciseIndex < 0 || exerciseIndex >= targetSession.exercises.length) return;

    final target = targetSession.exercises[exerciseIndex].series;
    if (seriesIndex < 0 || seriesIndex >= target.length) return;

    target.removeAt(seriesIndex);
    _persistWorkouts();
    notifyListeners();
  }

  bool updateSessionDate(WorkoutSession session, String isoDate) {
    final cleanDate = isoDate.trim();
    if (cleanDate.isEmpty) return false;

    final parsedDate = DateTime.tryParse(cleanDate);
    if (parsedDate == null) return false;

    final targetSession = _resolveSession(session);
    if (targetSession == null) return false;

    targetSession.date = parsedDate.toIso8601String().split('T').first;
    _persistWorkouts();
    notifyListeners();
    return true;
  }

  ExerciseLog? getLastExerciseLog(String exerciseName) {
    final target = exerciseName.trim().toLowerCase();
    if (target.isEmpty) return null;

    final currentSession = todaySession;

    for (var i = workouts.length - 1; i >= 0; i--) {
      final session = workouts[i];
      if (identical(session, currentSession)) continue;

      for (final ex in session.exercises) {
        if (_sameName(ex.name, target) && ex.series.isNotEmpty) {
          return ex;
        }
      }
    }
    return null;
  }

  ExerciseLog? getPreviousExerciseLog(WorkoutSession session, String exerciseName) {
    final target = exerciseName.trim().toLowerCase();
    if (target.isEmpty) return null;

    final sessionIndex = workouts.indexOf(session);
    if (sessionIndex <= 0) return null;

    for (var i = sessionIndex - 1; i >= 0; i--) {
      for (final ex in workouts[i].exercises) {
        if (_sameName(ex.name, target) && ex.series.isNotEmpty) {
          return ex;
        }
      }
    }
    return null;
  }

  List<Map<String, dynamic>> getProgressData(String exerciseName) {
    final target = exerciseName.trim().toLowerCase();
    if (target.isEmpty) return [];

    final ordered = workouts.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final out = <Map<String, dynamic>>[];

    for (final session in ordered) {
      ExerciseLog? log;
      for (final ex in session.exercises) {
        if (_sameName(ex.name, target)) {
          log = ex;
          break;
        }
      }

      if (log == null || log.series.isEmpty) continue;

      var maxWeight = log.series.first.weight;
      var totalVolume = 0.0;

      for (final s in log.series) {
        if (s.weight > maxWeight) maxWeight = s.weight;

        final reps = _parseReps(s.reps);
        totalVolume += s.weight * reps;

        for (final d in s.drops) {
          final dropReps = _parseReps(d.reps);
          totalVolume += d.weight * dropReps;
        }
      }

      out.add({
        'date': session.date,
        'maxWeight': maxWeight,
        'totalVolume': totalVolume,
        'series': log.series.length,
      });
    }

    return out;
  }

  WorkoutSession? importPreview(String text, String date) {
    return _parseBlocknotes(text, date);
  }

  int importFromBlocknotes(String text, String date) {
    final parsed = _parseBlocknotes(text, date);
    if (parsed == null || parsed.exercises.isEmpty) {
      return -1;
    }

    workouts.add(parsed);
    _mergeLibraryFromSession(parsed);

    _persistWorkouts();
    _persistLibrary();
    notifyListeners();

    return parsed.exercises.length;
  }

  void addToLibrary(String name, String category) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;

    final exists = library.any((e) => _sameName(e.name, cleanName));
    if (exists) return;

    library.add(LibraryExercise(
      id: _createId(cleanName),
      name: cleanName,
      category: category.trim(),
    ));

    library.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _persistLibrary();
    notifyListeners();
  }

  bool updateLibraryExercise(String id, String name, String category) {
    final idx = library.indexWhere((e) => e.id == id);
    if (idx == -1) return false;

    final cleanName = name.trim();
    if (cleanName.isEmpty) return false;

    final duplicate = library.any((e) => e.id != id && _sameName(e.name, cleanName));
    if (duplicate) return false;

    final previousName = library[idx].name;

    library[idx]
      ..name = cleanName
      ..category = category.trim();

    var didRenameOccurrences = false;
    if (previousName != cleanName) {
      for (final session in workouts) {
        for (final ex in session.exercises) {
          if (_sameName(ex.name, previousName)) {
            ex.name = cleanName;
            didRenameOccurrences = true;
          }
        }
      }
    }

    library.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (didRenameOccurrences) {
      _persistWorkouts();
    }
    _persistLibrary();
    notifyListeners();
    return true;
  }

  void removeFromLibrary(String id) {
    library.removeWhere((e) => e.id == id);
    _persistLibrary();
    notifyListeners();
  }

  Future<void> resetAllData() async {
    final fresh = WorkoutSession(date: _todayIso());
    workouts
      ..clear()
      ..add(fresh);
    _activeSession = fresh;

    library
      ..clear()
      ..addAll(_defaultLibrary());

    await _storage.saveWorkouts(workouts);
    await _storage.saveLibrary(library);
    notifyListeners();
  }

  void _applyPreferences() {
    S.setLang(prefs.language);
    AppTheme.apply(
      prefs.themeMode,
      prefs.accentPreset,
      customPrimary: customAccentColor,
    );
  }

  void _persistPreferences() {
    unawaited(_storage.savePreferences(prefs));
  }

  void _persistWorkouts() {
    unawaited(_storage.saveWorkouts(workouts));
  }

  void _persistLibrary() {
    unawaited(_storage.saveLibrary(library));
  }

  WorkoutSession _ensureActiveSessionExists() {
    final current = _activeSession;
    if (current != null && workouts.contains(current)) {
      return current;
    }

    if (workouts.isNotEmpty) {
      _activeSession = workouts.last;
      return _activeSession!;
    }

    final created = WorkoutSession(date: _todayIso());
    workouts.add(created);
    _activeSession = created;
    _persistWorkouts();
    return created;
  }

  WorkoutSession? _resolveSession(WorkoutSession session) {
    final idx = workouts.indexOf(session);
    if (idx == -1) return null;
    return workouts[idx];
  }

  WorkoutSession? _parseBlocknotes(String text, String date) {
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) return null;

    final exercises = <ExerciseLog>[];
    for (final line in lines) {
      final parsed = _parseBlocknotesLine(line);
      if (parsed != null) {
        exercises.add(parsed);
      }
    }

    if (exercises.isEmpty) return null;

    return WorkoutSession(date: date, exercises: exercises);
  }

  ExerciseLog? _parseBlocknotesLine(String line) {
    final tokens = line
        .split(RegExp(r'[;,]'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (tokens.length < 3) return null;

    final name = tokens.first;
    final series = <Series>[];

    for (var i = 1; i + 1 < tokens.length; i += 2) {
      final parsedSeries = _parseSeriesTokens(tokens[i], tokens[i + 1]);
      if (parsedSeries != null) {
        series.add(parsedSeries);
      }
    }

    if (series.isEmpty) return null;
    return ExerciseLog(name: name, series: series);
  }

  Series? _parseSeriesTokens(String weightToken, String repsToken) {
    final weights = weightToken
        .split('-')
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList();

    final repsValues = repsToken
        .split('-')
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList();

    if (weights.isEmpty) return null;

    final mainWeight = _parseWeight(weights.first);
    if (mainWeight == null) return null;

    final mainRepsRaw = repsValues.isNotEmpty ? repsValues.first : '';
    final mainReps = _cleanReps(mainRepsRaw);

    final hasDrops = weights.length > 1 || repsValues.length > 1;
    final mainIsHelp = mainRepsRaw.contains('*');

    final drops = <DropEntry>[];
    if (hasDrops) {
      final count = (weights.length > repsValues.length ? weights.length : repsValues.length) - 1;
      for (var i = 0; i < count; i++) {
        final w = (i + 1 < weights.length) ? weights[i + 1] : weights.last;
        final r = (i + 1 < repsValues.length) ? repsValues[i + 1] : repsValues.last;

        final dropWeight = _parseWeight(w);
        if (dropWeight == null) continue;

        final dropReps = _cleanReps(r);
        drops.add(DropEntry(
          weight: dropWeight,
          reps: dropReps.isEmpty ? 'ced' : dropReps,
        ));
      }
    }

    return Series(
      weight: mainWeight,
      reps: mainReps.isEmpty ? 'ced' : mainReps,
      type: hasDrops
          ? SeriesType.drop
          : (mainIsHelp ? SeriesType.help : SeriesType.normal),
      drops: drops,
    );
  }

  void _mergeLibraryFromSession(WorkoutSession session) {
    for (final ex in session.exercises) {
      final exists = library.any((item) => _sameName(item.name, ex.name));
      if (!exists) {
        library.add(LibraryExercise(
          id: _createId(ex.name),
          name: ex.name,
        ));
      }
    }

    library.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  double _parseReps(String reps) {
    final match = RegExp(r'([0-9]+(?:[\.,][0-9]+)?)').firstMatch(reps);
    if (match == null) return 0;
    return double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 0;
  }

  double? _parseWeight(String raw) {
    final normalized = raw.replaceAll(',', '.').trim();
    return double.tryParse(normalized);
  }

  String _cleanReps(String raw) => raw.replaceAll('*', '').trim();

  bool _sameName(String a, String b) => a.trim().toLowerCase() == b.trim().toLowerCase();

  String _todayIso() => DateTime.now().toIso8601String().split('T').first;

  String _createId(String source) {
    final slug = source
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final safeSlug = slug.isEmpty ? 'exercise' : slug;
    return '${safeSlug}_${DateTime.now().microsecondsSinceEpoch}';
  }

  List<LibraryExercise> _defaultLibrary() {
    const defaults = [
      ['Panca piana', 'Petto'],
      ['Panca inclinata manubri', 'Petto'],
      ['Chest press', 'Petto'],
      ['Croci ai cavi', 'Petto'],
      ['Lat machine avanti', 'Schiena'],
      ['Pulley basso', 'Schiena'],
      ['Rematore manubrio', 'Schiena'],
      ['Pulldown presa stretta', 'Schiena'],
      ['Squat bilanciere', 'Gambe'],
      ['Leg press', 'Gambe'],
      ['Affondi camminati', 'Gambe'],
      ['Leg extension', 'Gambe'],
      ['Leg curl', 'Gambe'],
      ['Stacchi rumeni', 'Gambe'],
      ['Military press', 'Spalle'],
      ['Alzate laterali', 'Spalle'],
      ['Rear delts machine', 'Spalle'],
      ['Curl bilanciere', 'Bicipiti'],
      ['Curl manubri alternato', 'Bicipiti'],
      ['Curl cavo basso', 'Bicipiti'],
      ['Pushdown cavo', 'Tricipiti'],
      ['French press', 'Tricipiti'],
      ['Dip alle parallele', 'Tricipiti'],
      ['Crunch machine', 'Core'],
      ['Plank', 'Core'],
      ['Hanging leg raise', 'Core'],
    ];

    return defaults
        .asMap()
        .entries
        .map((e) => LibraryExercise(
              id: 'default_${e.key}',
              name: e.value[0],
              category: e.value[1],
            ))
        .toList();
  }
}
