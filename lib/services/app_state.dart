// lib/services/app_state.dart

import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/models.dart';
import '../models/muscle_groups.dart';
import '../theme.dart';
import 'backup_service.dart';
import 'storage_service.dart';

class AppState extends ChangeNotifier {
  AppState({StorageService? storageService, BackupService? backupService})
      : _storage = storageService ?? StorageService(),
        _backup = backupService ?? BackupService();

  final StorageService _storage;
  final BackupService _backup;

  bool isLoading = true;
  bool _initialized = false;
  String storageBasePath = '';

  AppPreferences prefs = const AppPreferences();
  final List<WorkoutSession> workouts = [];
  final List<LibraryExercise> library = [];
  final List<WorkoutTemplate> templates = [];
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

      // Backfill muscle data for exercises that don't have it
      _backfillMuscleData();

      templates
        ..clear()
        ..addAll(await _storage.loadTemplates());

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

  void setTourCompleted() {
    if (prefs.tourCompleted) return;
    prefs = prefs.copyWith(tourCompleted: true);
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

    // Backup automatico ad ogni "Nuovo giorno" (solo quando si chiude
    // davvero una giornata con dati: gli altri rami fanno return prima).
    unawaited(_autoBackup());
  }

  // ─── BACKUP ──────────────────────────────────────────────────────────────

  /// Flush dei dati su disco + snapshot. Usato dall'auto-backup.
  Future<void> _autoBackup() async {
    try {
      await _storage.saveWorkouts(workouts);
      await _storage.saveLibrary(library);
      await _storage.saveTemplates(templates);
      await _storage.savePreferences(prefs);
      await _backup.createBackup(tag: 'nuovogiorno');
    } catch (_) {}
  }

  /// Backup manuale dal pulsante nelle impostazioni. Ritorna il percorso creato.
  Future<String?> createManualBackup() async {
    try {
      await _storage.saveWorkouts(workouts);
      await _storage.saveLibrary(library);
      await _storage.saveTemplates(templates);
      await _storage.savePreferences(prefs);
      return await _backup.createBackup(tag: 'manuale');
    } catch (_) {
      return null;
    }
  }

  /// Esporta/condivide i dati fuori dal telefono. Ritorna true se ha esportato.
  Future<bool> exportBackup() async {
    try {
      await _storage.saveWorkouts(workouts);
      return await _backup.exportAndShare();
    } catch (_) {
      return false;
    }
  }

  Future<DateTime?> lastBackupTime() => _backup.lastBackupTime();
  Future<int> backupCount() => _backup.backupCount();

  // ─── RATING ──────────────────────────────────────────────────────────────

  void setSessionRating(WorkoutSession session, int rating) {
    final clamped = rating.clamp(1, 10);
    final targetSession = _resolveSession(session);
    if (targetSession == null) return;

    targetSession.rating = clamped;
    _persistWorkouts();
    notifyListeners();
  }

  // ─── SESSIONI ────────────────────────────────────────────────────────────

  /// Elimina un'intera sessione dallo storico. Ritorna la posizione che
  /// aveva, da passare a [insertSession] per l'annulla (-1 se non c'era).
  int removeSession(WorkoutSession session) {
    final idx = workouts.indexOf(session);
    if (idx == -1) return -1;
    workouts.removeAt(idx);
    if (identical(_activeSession, session)) _activeSession = null;
    _persistWorkouts();
    notifyListeners();
    return idx;
  }

  void insertSession(int index, WorkoutSession session) {
    if (workouts.contains(session)) return;
    workouts.insert(index.clamp(0, workouts.length), session);
    _persistWorkouts();
    notifyListeners();
  }

  // ─── TEMPLATES ───────────────────────────────────────────────────────────

  void addTemplate(String name, List<TemplateExercise> exercises) {
    final cleanName = name.trim();
    if (cleanName.isEmpty || exercises.isEmpty) return;

    templates.add(WorkoutTemplate(
      id: _createId(cleanName),
      name: cleanName,
      exercises: exercises,
    ));
    _persistTemplates();
    notifyListeners();
  }

  void updateTemplate(String id, String name, List<TemplateExercise> exercises) {
    final idx = templates.indexWhere((t) => t.id == id);
    if (idx == -1) return;

    final cleanName = name.trim();
    if (cleanName.isEmpty) return;

    templates[idx]
      ..name = cleanName
      ..exercises = exercises;

    // Le sessioni registrate puntano al giorno per id: allineo anche lo
    // snapshot del nome, così l'export CSV resta leggibile dopo un rename.
    var renamedSessions = false;
    for (final session in workouts) {
      if (session.templateId == id && session.templateName != cleanName) {
        session.templateName = cleanName;
        renamedSessions = true;
      }
    }
    if (renamedSessions) _persistWorkouts();

    _persistTemplates();
    notifyListeners();
  }

  void removeTemplate(String id) {
    templates.removeWhere((t) => t.id == id);
    _persistTemplates();
    notifyListeners();
  }

  void applyTemplate(WorkoutTemplate template) {
    final session = todaySession;
    _claimForToday(session);

    // Il primo giorno applicato fissa il contesto della sessione: se ne
    // applichi un secondo i numeri restano ancorati a quello con cui hai
    // iniziato. Per cambiarlo c'è [setSessionTemplate] (il chip in "Oggi").
    if (session.isFreeWorkout) {
      session.templateId = template.id;
      session.templateName = template.name;
    }

    for (final tpl in template.exercises) {
      final existingIdx = session.exercises.indexWhere((ex) => _sameName(ex.name, tpl.name));
      if (existingIdx == -1) {
        session.exercises.add(ExerciseLog(
          name: tpl.name,
          restSeconds: tpl.restSeconds,
          targetSeries: tpl.targetSeries,
        ));
      } else {
        final existing = session.exercises[existingIdx];
        if (tpl.restSeconds != null && existing.restSeconds == null) {
          existing.restSeconds = tpl.restSeconds;
        }
        if (tpl.targetSeries != null && existing.targetSeries == null) {
          existing.targetSeries = tpl.targetSeries;
        }
      }
    }
    _persistWorkouts();
    notifyListeners();
  }

  /// Cambia il giorno preimpostato di una sessione, o lo azzera passando null
  /// (= allenamento libero). Serve quando applichi il giorno sbagliato o
  /// quando etichetti a mano una sessione partita libera.
  void setSessionTemplate(WorkoutSession session, WorkoutTemplate? template) {
    final target = _resolveSession(session);
    if (target == null) return;

    target.templateId = template?.id;
    target.templateName = template?.name;
    _persistWorkouts();
    notifyListeners();
  }

  void updateExerciseRest(int exerciseIndex, int? restSeconds) {
    updateExerciseRestInSession(todaySession, exerciseIndex, restSeconds);
  }

  void updateExerciseRestInSession(WorkoutSession session, int exerciseIndex, int? restSeconds) {
    final targetSession = _resolveSession(session);
    if (targetSession == null) return;
    if (exerciseIndex < 0 || exerciseIndex >= targetSession.exercises.length) return;

    targetSession.exercises[exerciseIndex].restSeconds =
        (restSeconds != null && restSeconds > 0) ? restSeconds : null;
    _persistWorkouts();
    notifyListeners();
  }

  int? getLastRestForExercise(String exerciseName) {
    final target = exerciseName.trim().toLowerCase();
    if (target.isEmpty) return null;
    final currentSession = todaySession;
    for (var i = workouts.length - 1; i >= 0; i--) {
      final session = workouts[i];
      if (identical(session, currentSession)) continue;
      for (final ex in session.exercises) {
        if (_sameName(ex.name, target) && ex.restSeconds != null) {
          return ex.restSeconds;
        }
      }
    }
    return null;
  }

  // ─── MUSCLE MAP ──────────────────────────────────────────────────────────

  /// Get muscle stimulation data for a given week (Monday to Sunday).
  /// Returns a map: muscleId -> effective sets (primary * 1.0 + secondary * 0.5).
  Map<String, double> getWeeklyMuscleStimulation(DateTime weekStart) {
    final monday = _toMonday(weekStart);
    final sunday = monday.add(const Duration(days: 7));

    final stimulation = <String, double>{};
    for (final m in allMuscleGroups) {
      stimulation[m.id] = 0;
    }

    for (final session in workouts) {
      final sessionDate = DateTime.tryParse(session.date);
      if (sessionDate == null) continue;
      if (sessionDate.isBefore(monday) || !sessionDate.isBefore(sunday)) continue;

      for (final ex in session.exercises) {
        final seriesCount = ex.series.length.toDouble();
        if (seriesCount <= 0) continue;

        final libEx = _findLibraryExercise(ex.name);
        if (libEx == null) continue;

        for (final muscleId in libEx.primaryMuscles) {
          stimulation[muscleId] = (stimulation[muscleId] ?? 0) + seriesCount;
        }
        for (final muscleId in libEx.secondaryMuscles) {
          stimulation[muscleId] = (stimulation[muscleId] ?? 0) + seriesCount * 0.5;
        }
      }
    }

    return stimulation;
  }

  /// Get muscles targeted by a specific exercise (from library).
  Map<String, List<String>> getMusclesForExercise(String exerciseName) {
    final libEx = _findLibraryExercise(exerciseName);
    if (libEx == null) return {'primary': [], 'secondary': []};
    return {
      'primary': libEx.primaryMuscles,
      'secondary': libEx.secondaryMuscles,
    };
  }

  void updateExerciseMuscles(String id, List<String> primary, List<String> secondary) {
    final idx = library.indexWhere((e) => e.id == id);
    if (idx == -1) return;

    library[idx].primaryMuscles = primary;
    library[idx].secondaryMuscles = secondary;
    _persistLibrary();
    notifyListeners();
  }

  // ─── TODAY SHORTCUTS ─────────────────────────────────────────────────────

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

  void insertSeries(int exerciseIndex, int seriesIndex, Series series) {
    insertSeriesInSession(todaySession, exerciseIndex, seriesIndex, series);
  }

  void insertExerciseInToday(int exerciseIndex, ExerciseLog exercise) {
    insertExerciseInSession(todaySession, exerciseIndex, exercise);
  }

  void updateSeries(int exerciseIndex, int seriesIndex, Series series) {
    updateSeriesInSession(todaySession, exerciseIndex, seriesIndex, series);
  }

  void updateExerciseNote(int exerciseIndex, String note) {
    updateExerciseNoteInSession(todaySession, exerciseIndex, note);
  }

  void updateExerciseNoteInSession(WorkoutSession session, int exerciseIndex, String? note) {
    final targetSession = _resolveSession(session);
    if (targetSession == null) return;
    if (exerciseIndex < 0 || exerciseIndex >= targetSession.exercises.length) return;

    targetSession.exercises[exerciseIndex].note = (note == null || note.trim().isEmpty) ? null : note.trim();
    _persistWorkouts();
    notifyListeners();
  }

  bool addExerciseToSession(WorkoutSession session, String exerciseName) {
    final name = exerciseName.trim();
    if (name.isEmpty) return false;

    final targetSession = _resolveSession(session);
    if (targetSession == null) return false;

    final exists = targetSession.exercises.any((ex) => _sameName(ex.name, name));
    if (exists) return false;

    _claimForToday(targetSession);
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

  /// Reinserisce una serie in una posizione precisa: serve all'"Annulla"
  /// dopo un'eliminazione, cosi' la serie torna dov'era e non in fondo.
  void insertSeriesInSession(
      WorkoutSession session, int exerciseIndex, int seriesIndex, Series series) {
    final targetSession = _resolveSession(session);
    if (targetSession == null) return;
    if (exerciseIndex < 0 || exerciseIndex >= targetSession.exercises.length) return;

    final target = targetSession.exercises[exerciseIndex].series;
    final index = seriesIndex.clamp(0, target.length);
    target.insert(index, series);
    _persistWorkouts();
    notifyListeners();
  }

  /// Reinserisce un esercizio eliminato nella posizione originale (Annulla).
  void insertExerciseInSession(
      WorkoutSession session, int exerciseIndex, ExerciseLog exercise) {
    final targetSession = _resolveSession(session);
    if (targetSession == null) return;

    final index = exerciseIndex.clamp(0, targetSession.exercises.length);
    targetSession.exercises.insert(index, exercise);
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

  // ─── STORICO CONTESTUALE ─────────────────────────────────────────────────

  /// Nome da mostrare per il giorno di una sessione: quello attuale del
  /// giorno preimpostato se esiste ancora (così rinominarlo si riflette su
  /// tutto lo storico), altrimenti lo snapshot salvato nella sessione.
  /// null = allenamento libero.
  String? dayNameOf(WorkoutSession session) {
    final id = session.templateId;
    if (id != null) {
      for (final t in templates) {
        if (t.id == id) return t.name;
      }
    }
    return session.templateName;
  }

  /// Storia di un esercizio vista dalla sessione [ref]: l'ultima volta nello
  /// STESSO giorno preimpostato, l'ultima volta in un giorno DIVERSO e le
  /// ultime occorrenze in qualsiasi giorno come fallback, ognuna etichettata
  /// col giorno di provenienza.
  ///
  /// Il record NON passa da qui: resta globale, vedi [getBestSeriesEver].
  ExerciseHistory historyFor(
    WorkoutSession ref,
    String exerciseName, {
    int limit = 3,
  }) {
    final target = exerciseName.trim().toLowerCase();
    if (target.isEmpty) return ExerciseHistory.empty;

    final wantsSameDay = !ref.isFreeWorkout;
    ExerciseHistoryHit? sameDay;
    ExerciseHistoryHit? elsewhere;
    final anyDay = <ExerciseHistoryHit>[];

    for (final session in _sessionsBefore(ref)) {
      final log = _findLogWithSeries(session, target);
      if (log == null) continue;

      final hit = ExerciseHistoryHit(
        log: log,
        sessionDate: session.date,
        dayName: dayNameOf(session),
      );

      if (wantsSameDay) {
        // Le due righe della scheda rispondono a due domande diverse: come è
        // andata l'ultima volta in QUESTA giornata, e come va lo stesso
        // esercizio quando lo incontri altrove (dove arrivi più o meno
        // fresco). Un'occorrenza più vecchia nello stesso giorno non serve a
        // nessuna delle due.
        if (_sameDayContext(ref, session)) {
          sameDay ??= hit;
        } else {
          elsewhere ??= hit;
        }
      }
      if (anyDay.length < limit) anyDay.add(hit);

      // Si può smettere quando si è raccolto il fallback e, se serviva, anche
      // l'occorrenza nello stesso giorno e quella in un altro giorno.
      if (anyDay.length >= limit &&
          (!wantsSameDay || (sameDay != null && elsewhere != null))) {
        break;
      }
    }

    return ExerciseHistory(
      sameDay: sameDay,
      lastElsewhere: elsewhere,
      anyDay: anyDay,
    );
  }

  /// Storia dell'esercizio dal punto di vista dell'allenamento in corso.
  ExerciseHistory historyForToday(String exerciseName, {int limit = 3}) =>
      historyFor(todaySession, exerciseName, limit: limit);

  /// Returns a synthetic ExerciseLog containing the heaviest Series
  /// for each set position across all past sessions.
  /// Volutamente GLOBALE: il record è il record, non si filtra per giorno.
  List<Series> getBestSeriesEver(String exerciseName) {
    final target = exerciseName.trim().toLowerCase();
    if (target.isEmpty) return [];

    final currentSession = todaySession;
    // best[i] = heaviest Series ever at position i
    final best = <int, Series>{};

    for (final session in workouts) {
      if (identical(session, currentSession)) continue;
      for (final ex in session.exercises) {
        if (!_sameName(ex.name, target) || ex.series.isEmpty) continue;
        for (var i = 0; i < ex.series.length; i++) {
          final s = ex.series[i];
          if (!best.containsKey(i) || s.weight > best[i]!.weight) {
            best[i] = s;
          }
        }
      }
    }

    if (best.isEmpty) return [];
    final maxIdx = best.keys.reduce((a, b) => a > b ? a : b);
    return List.generate(maxIdx + 1, (i) => best[i] ?? best.values.first);
  }

  /// Riepilogo di tutti gli esercizi in una passata sola (la lista di
  /// Progressi chiamava getProgressData per ogni riga, ordinando ogni volta
  /// tutto lo storico). Chiave: nome in minuscolo.
  Map<String, ExerciseSummary> exerciseSummaries() {
    final ordered = workouts.toList()..sort((a, b) => a.date.compareTo(b.date));
    final out = <String, ExerciseSummary>{};
    for (final session in ordered) {
      for (final ex in session.exercises) {
        if (ex.series.isEmpty) continue;
        final key = ex.name.trim().toLowerCase();
        var maxW = ex.series.first.weight;
        for (final s in ex.series) {
          if (s.weight > maxW) maxW = s.weight;
        }
        final prev = out[key];
        out[key] = ExerciseSummary(
          firstMax: prev?.firstMax ?? maxW,
          lastMax: maxW,
          bestMax: prev == null || maxW > prev.bestMax ? maxW : prev.bestMax,
          sessions: (prev?.sessions ?? 0) + 1,
          lastDate: session.date,
        );
      }
    }
    return out;
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

  // ─── TEMPLATE TEXT IMPORT ────────────────────────────────────────────────

  WorkoutTemplate? parseTemplateText(String raw) {
    final lines = raw
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.length < 2) return null;

    final name = _cleanTemplateName(lines.first);
    if (name.isEmpty) return null;

    final exercises = <TemplateExercise>[];
    final seen = <String>{};
    for (final line in lines.skip(1)) {
      final parsed = _parseTemplateExerciseLine(line);
      if (parsed == null) continue;
      final key = parsed.name.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      exercises.add(parsed);
    }
    if (exercises.isEmpty) return null;

    return WorkoutTemplate(
      id: _createId(name),
      name: name,
      exercises: exercises,
    );
  }

  bool importTemplateFromText(String raw) {
    final parsed = parseTemplateText(raw);
    if (parsed == null) return false;
    templates.add(parsed);
    _persistTemplates();
    notifyListeners();
    return true;
  }

  String _cleanTemplateName(String line) {
    var n = line.trim();
    // strip leading markdown / prefixes
    n = n.replaceFirst(RegExp(r'^(#{1,6}\s*|[-*]\s*)'), '');
    n = n.replaceFirst(
      RegExp(r'^(nome|name|titolo|title|scheda|workout|giorno|day)\s*[:\-]\s*',
          caseSensitive: false),
      '',
    );
    return n.trim();
  }

  TemplateExercise? _parseTemplateExerciseLine(String raw) {
    var line = raw.trim();
    if (line.isEmpty) return null;
    // strip list bullets / numbering
    line = line.replaceFirst(RegExp(r'^([-*•]|\d+[\.\)])\s+'), '').trim();
    if (line.isEmpty) return null;

    // Dopo il nome possono arrivare recupero e serie previste, in ordine
    // libero e entrambi opzionali. Un separatore si accetta solo se TUTTI i
    // pezzi a destra si riconoscono: così un nome che contiene un separatore
    // (es. "Curl - manubri") non viene troncato a meta'.
    for (final sep in ['|', ';', '\t', ',', ' - ']) {
      if (!line.contains(sep)) continue;

      final parts = line.split(sep).map((p) => p.trim()).toList();
      if (parts.length < 2) continue;

      final name = _stripRestLabel(parts.first);
      if (name.isEmpty) continue;

      int? rest;
      int? target;
      var allRecognized = true;
      for (final part in parts.skip(1)) {
        if (part.isEmpty) continue;

        final asTarget = _parseSeriesToken(part);
        if (asTarget != null) {
          target ??= asTarget;
          continue;
        }
        final asRest = _parseRestToken(part);
        if (asRest != null) {
          rest ??= asRest;
          continue;
        }
        allRecognized = false;
        break;
      }

      if (!allRecognized || (rest == null && target == null)) continue;
      return TemplateExercise(name: name, restSeconds: rest, targetSeries: target);
    }

    final bareName = _stripRestLabel(line);
    if (bareName.isEmpty) return null;
    return TemplateExercise(name: bareName);
  }

  /// Toglie dal nome un'etichetta finale tipo "rest", "recupero", "riposo".
  String _stripRestLabel(String raw) {
    return raw
        .replaceFirst(
          RegExp(r'\s+(rest|recupero|riposo|pausa|serie|series|sets?)\s*[:\-]?\s*$',
              caseSensitive: false),
          '',
        )
        .trim();
  }

  /// Riconosce le serie previste: "4x", "x4", "4 serie", "4 sets".
  /// Un numero nudo NON è una serie: resta un recupero in secondi, come nel
  /// formato originale delle schede.
  int? _parseSeriesToken(String raw) {
    final s = raw.trim().toLowerCase();
    if (s.isEmpty) return null;

    final match = RegExp(r'^(?:(\d{1,2})\s*(?:x|series|serie|sets?)|x\s*(\d{1,2}))$')
        .firstMatch(s);
    if (match == null) return null;

    final value = int.tryParse(match.group(1) ?? match.group(2) ?? '');
    if (value == null || value <= 0) return null;
    return value > kMaxTargetSeries ? kMaxTargetSeries : value;
  }

  /// Parses "2:00", "2m", "2m30s", "90s", "90", "2 min 30 sec", optionally
  /// preceded by "rest", "recupero", "riposo", "pausa" labels.
  int? _parseRestToken(String raw) {
    var s = raw.trim().toLowerCase();
    if (s.isEmpty) return null;
    s = s.replaceFirst(
      RegExp(r'^(rest|recupero|riposo|pausa)\s*[:\-]?\s*'),
      '',
    );
    if (s.isEmpty) return null;

    // m:ss
    final mss = RegExp(r'^(\d+):([0-5]?\d)$').firstMatch(s);
    if (mss != null) {
      final m = int.parse(mss.group(1)!);
      final sec = int.parse(mss.group(2)!);
      final t = m * 60 + sec;
      return t > 0 ? t : null;
    }

    // composite: 2m30s / 2m 30s / 2 min 30 sec
    final composite = RegExp(
            r'^(?:(\d+)\s*(?:m|min|minuti|minutes?)\b)?\s*(?:(\d+)\s*(?:s|sec|secondi|seconds?)\b)?$')
        .firstMatch(s);
    if (composite != null && (composite.group(1) != null || composite.group(2) != null)) {
      final m = int.tryParse(composite.group(1) ?? '0') ?? 0;
      final sec = int.tryParse(composite.group(2) ?? '0') ?? 0;
      final t = m * 60 + sec;
      return t > 0 ? t : null;
    }

    // bare integer = seconds
    final bare = int.tryParse(s);
    if (bare != null && bare > 0) return bare;
    return null;
  }

  /// Importa una sessione dal blocco note. [template] è opzionale: se non lo
  /// passi la sessione resta un allenamento libero (nessun contesto inventato
  /// per lo storico che non ce l'ha).
  int importFromBlocknotes(String text, String date, {WorkoutTemplate? template}) {
    final parsed = _parseBlocknotes(text, date);
    if (parsed == null || parsed.exercises.isEmpty) {
      return -1;
    }

    if (template != null) {
      parsed.templateId = template.id;
      parsed.templateName = template.name;
    }

    workouts.add(parsed);
    _mergeLibraryFromSession(parsed);

    _persistWorkouts();
    _persistLibrary();
    notifyListeners();

    return parsed.exercises.length;
  }

  void addToLibrary(String name, String category, {List<String>? primaryMuscles, List<String>? secondaryMuscles}) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;

    final exists = library.any((e) => _sameName(e.name, cleanName));
    if (exists) return;

    library.add(LibraryExercise(
      id: _createId(cleanName),
      name: cleanName,
      category: category.trim(),
      primaryMuscles: primaryMuscles,
      secondaryMuscles: secondaryMuscles,
    ));

    library.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _persistLibrary();
    notifyListeners();
  }

  bool updateLibraryExercise(String id, String name, String category, {List<String>? primaryMuscles, List<String>? secondaryMuscles}) {
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

    if (primaryMuscles != null) library[idx].primaryMuscles = primaryMuscles;
    if (secondaryMuscles != null) library[idx].secondaryMuscles = secondaryMuscles;

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

    templates.clear();

    await _storage.saveWorkouts(workouts);
    await _storage.saveLibrary(library);
    await _storage.saveTemplates(templates);
    notifyListeners();
  }

  // ─── PRIVATE ─────────────────────────────────────────────────────────────

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

  void _persistTemplates() {
    unawaited(_storage.saveTemplates(templates));
  }

  /// Sessioni che precedono [ref], dalla più recente. Ordinate per data e non
  /// per posizione in lista: l'import dal blocco note appende in coda sessioni
  /// vecchie, e senza ordinare diventerebbero loro "l'ultima volta".
  List<WorkoutSession> _sessionsBefore(WorkoutSession ref) {
    final refIdx = workouts.indexOf(ref);
    final indices = <int>[];

    for (var i = 0; i < workouts.length; i++) {
      if (i == refIdx) continue;
      final cmp = workouts[i].date.compareTo(ref.date);
      if (cmp > 0) continue;
      // A pari data decide l'ordine di inserimento: quello che è stato
      // aggiunto dopo la sessione di riferimento non viene "prima".
      if (cmp == 0 && refIdx != -1 && i > refIdx) continue;
      indices.add(i);
    }

    indices.sort((a, b) {
      final byDate = workouts[b].date.compareTo(workouts[a].date);
      return byDate != 0 ? byDate : b.compareTo(a);
    });

    return indices.map((i) => workouts[i]).toList();
  }

  ExerciseLog? _findLogWithSeries(WorkoutSession session, String lowerName) {
    for (final ex in session.exercises) {
      if (_sameName(ex.name, lowerName) && ex.series.isNotEmpty) return ex;
    }
    return null;
  }

  /// Due sessioni condividono il contesto se puntano allo stesso giorno
  /// preimpostato: l'id è la chiave, il nome è il ripiego per i giorni
  /// cancellati, dove l'id non risolve più niente.
  bool _sameDayContext(WorkoutSession a, WorkoutSession b) {
    if (a.isFreeWorkout || b.isFreeWorkout) return false;

    final idA = a.templateId;
    final idB = b.templateId;
    if (idA != null && idB != null) return idA == idB;

    final nameA = a.templateName;
    final nameB = b.templateName;
    if (nameA == null || nameB == null) return false;
    return _sameName(nameA, nameB);
  }

  LibraryExercise? _findLibraryExercise(String name) {
    for (final ex in library) {
      if (_sameName(ex.name, name)) return ex;
    }
    return null;
  }

  DateTime _toMonday(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  /// Backfill muscle data for library exercises that have empty muscle lists.
  void _backfillMuscleData() {
    var changed = false;
    for (final ex in library) {
      if (ex.primaryMuscles.isEmpty && ex.secondaryMuscles.isEmpty) {
        final defaults = getDefaultMuscles(ex.name);
        if (defaults != null) {
          ex.primaryMuscles = List<String>.from(defaults['primary'] ?? []);
          ex.secondaryMuscles = List<String>.from(defaults['secondary'] ?? []);
          changed = true;
        }
      }
    }
    if (changed) {
      _persistLibrary();
    }
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

  /// La sessione attiva vuota rimasta da un altro giorno diventa quella di
  /// oggi appena ci metti dentro qualcosa: prima gli esercizi finivano con la
  /// data vecchia. Una sessione con dati non si tocca mai (si puo' finire un
  /// allenamento dopo mezzanotte).
  void _claimForToday(WorkoutSession session) {
    if (!identical(session, _activeSession)) return;
    if (session.exercises.isNotEmpty) return;
    session.date = _todayIso();
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
        final defaults = getDefaultMuscles(ex.name);
        library.add(LibraryExercise(
          id: _createId(ex.name),
          name: ex.name,
          primaryMuscles: defaults != null ? List<String>.from(defaults['primary'] ?? []) : null,
          secondaryMuscles: defaults != null ? List<String>.from(defaults['secondary'] ?? []) : null,
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
        .map((e) {
          final name = e.value[0];
          final muscles = getDefaultMuscles(name);
          return LibraryExercise(
            id: 'default_${e.key}',
            name: name,
            category: e.value[1],
            primaryMuscles: muscles != null ? List<String>.from(muscles['primary'] ?? []) : null,
            secondaryMuscles: muscles != null ? List<String>.from(muscles['secondary'] ?? []) : null,
          );
        })
        .toList();
  }
}

/// Numeri essenziali di un esercizio su tutto lo storico.
class ExerciseSummary {
  final double firstMax;
  final double lastMax;
  final double bestMax;
  final int sessions;
  final String lastDate;

  const ExerciseSummary({
    required this.firstMax,
    required this.lastMax,
    required this.bestMax,
    required this.sessions,
    required this.lastDate,
  });

  double get delta => lastMax - firstMax;
}
