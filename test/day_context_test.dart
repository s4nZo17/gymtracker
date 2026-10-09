// test/day_context_test.dart
//
// Copre la parte che non si vede a occhio nell'app: quale sessione passata
// viene scelta come "ultima volta" e cosa succede quando il contesto manca.

import 'package:flutter_test/flutter_test.dart';
import 'package:gymtracker2/models/models.dart';
import 'package:gymtracker2/services/app_state.dart';
import 'package:gymtracker2/services/storage_service.dart';

/// Storage che non tocca il disco: i test girano senza path_provider.
class _MemoryStorage extends StorageService {
  @override
  Future<void> saveWorkouts(List<WorkoutSession> workouts) async {}
  @override
  Future<void> saveLibrary(List<LibraryExercise> library) async {}
  @override
  Future<void> saveTemplates(List<WorkoutTemplate> templates) async {}
  @override
  Future<void> savePreferences(AppPreferences prefs) async {}
}

AppState _newState() => AppState(storageService: _MemoryStorage());

Series _s(double weight, String reps) => Series(weight: weight, reps: reps);

WorkoutSession _session(
  String date, {
  String? templateId,
  String? templateName,
  required List<ExerciseLog> exercises,
}) {
  return WorkoutSession(
    date: date,
    templateId: templateId,
    templateName: templateName,
    exercises: exercises,
  );
}

void main() {
  group('historyFor', () {
    test('nello stesso giorno preimpostato salta gli altri giorni', () {
      final state = _newState();
      state.workouts.addAll([
        _session('2026-08-01', templateId: 'petto', templateName: 'Petto',
            exercises: [ExerciseLog(name: 'Pec fly', series: [_s(30, '12')])]),
        _session('2026-08-04', templateId: 'upper', templateName: 'Upper',
            exercises: [ExerciseLog(name: 'Pec fly', series: [_s(45, '10')])]),
        _session('2026-08-08', templateId: 'petto', templateName: 'Petto',
            exercises: [ExerciseLog(name: 'Pec fly', series: [_s(32.5, '12')])]),
        _session('2026-08-11', templateId: 'petto', templateName: 'Petto',
            exercises: []),
      ]);

      final history = state.historyForToday('Pec fly');

      // Il riferimento è la Pec fly dell'ultimo giorno "Petto", non quella
      // (più pesante) fatta a inizio "Upper".
      expect(history.sameDay, isNotNull);
      expect(history.sameDay!.sessionDate, '2026-08-08');
      expect(history.sameDay!.series.first.weight, 32.5);
      expect(history.sameDay!.dayName, 'Petto');

      // Il confronto con l'altro giorno resta disponibile ed è etichettato.
      expect(history.lastElsewhere!.sessionDate, '2026-08-04');
      expect(history.lastElsewhere!.dayName, 'Upper');
    });

    test('senza occorrenze in altri giorni non c\'è la riga di confronto', () {
      final state = _newState();
      state.workouts.addAll([
        _session('2026-08-01', templateId: 'petto', templateName: 'Petto',
            exercises: [ExerciseLog(name: 'Pec fly', series: [_s(30, '12')])]),
        _session('2026-08-08', templateId: 'petto', templateName: 'Petto',
            exercises: [ExerciseLog(name: 'Pec fly', series: [_s(32.5, '12')])]),
        _session('2026-08-11', templateId: 'petto', templateName: 'Petto',
            exercises: []),
      ]);

      final history = state.historyForToday('Pec fly');

      // L'esercizio lo fa solo nel giorno "Petto": la riga secondaria
      // mostrerebbe una volta più vecchia dello stesso giorno, che non
      // aggiunge niente.
      expect(history.sameDay!.sessionDate, '2026-08-08');
      expect(history.lastElsewhere, isNull);
    });

    test('l\'altro giorno si trova anche oltre il limite del fallback', () {
      final state = _newState();
      state.workouts.addAll([
        _session('2026-07-01', templateId: 'upper', templateName: 'Upper',
            exercises: [ExerciseLog(name: 'Pec fly', series: [_s(45, '10')])]),
        for (final d in ['2026-08-01', '2026-08-04', '2026-08-08'])
          _session(d, templateId: 'petto', templateName: 'Petto',
              exercises: [ExerciseLog(name: 'Pec fly', series: [_s(30, '12')])]),
        _session('2026-08-11', templateId: 'petto', templateName: 'Petto',
            exercises: []),
      ]);

      // Le 3 occorrenze più recenti sono tutte nel giorno "Petto": la
      // ricerca non si ferma lì, l'Upper di luglio va comunque trovato.
      final history = state.historyForToday('Pec fly');

      expect(history.sameDay!.sessionDate, '2026-08-08');
      expect(history.lastElsewhere!.sessionDate, '2026-07-01');
      expect(history.lastElsewhere!.dayName, 'Upper');
    });

    test('in allenamento libero non c\'è nessuna riga di confronto dedicata', () {
      final state = _newState();
      state.workouts.addAll([
        _session('2026-08-04', templateId: 'upper', templateName: 'Upper',
            exercises: [ExerciseLog(name: 'Pec fly', series: [_s(45, '10')])]),
        _session('2026-08-11', exercises: []),
      ]);

      final history = state.historyForToday('Pec fly');

      expect(history.sameDay, isNull);
      expect(history.lastElsewhere, isNull,
          reason: 'da libero si elencano tutte le occorrenze, senza gerarchia');
      expect(history.anyDay, hasLength(1));
    });

    test('senza precedenti nello stesso giorno resta solo il fallback', () {
      final state = _newState();
      state.workouts.addAll([
        _session('2026-08-04', templateId: 'upper', templateName: 'Upper',
            exercises: [ExerciseLog(name: 'Pec fly', series: [_s(45, '10')])]),
        _session('2026-08-11', templateId: 'petto', templateName: 'Petto',
            exercises: []),
      ]);

      final history = state.historyForToday('Pec fly');

      expect(history.sameDay, isNull);
      expect(history.prefillSource, isNull, reason: 'niente prefill senza contesto');
      expect(history.anyDay.single.dayName, 'Upper');
    });

    test('in allenamento libero elenca le ultime occorrenze, tutte etichettate', () {
      final state = _newState();
      state.workouts.addAll([
        _session('2026-07-20',
            exercises: [ExerciseLog(name: 'Pec fly', series: [_s(25, '12')])]),
        _session('2026-08-01', templateId: 'petto', templateName: 'Petto',
            exercises: [ExerciseLog(name: 'Pec fly', series: [_s(30, '12')])]),
        _session('2026-08-04', templateId: 'upper', templateName: 'Upper',
            exercises: [ExerciseLog(name: 'Pec fly', series: [_s(45, '10')])]),
        _session('2026-08-08', templateId: 'petto', templateName: 'Petto',
            exercises: [ExerciseLog(name: 'Pec fly', series: [_s(32.5, '12')])]),
        _session('2026-08-11', exercises: []),
      ]);

      final history = state.historyForToday('Pec fly');

      expect(history.sameDay, isNull);
      expect(history.anyDay.length, 3);
      expect(
        history.anyDay.map((h) => h.sessionDate).toList(),
        ['2026-08-08', '2026-08-04', '2026-08-01'],
      );
      expect(history.anyDay.map((h) => h.dayName).toList(),
          ['Petto', 'Upper', 'Petto']);
    });

    test('ordina per data anche se la lista è disordinata (sessione importata)',
        () {
      final state = _newState();
      final current = _session('2026-08-11', exercises: []);
      state.workouts.addAll([
        _session('2026-08-08',
            exercises: [ExerciseLog(name: 'Panca', series: [_s(80, '5')])]),
        current,
        // Import di un allenamento vecchio: finisce in coda alla lista.
        _session('2026-06-02',
            exercises: [ExerciseLog(name: 'Panca', series: [_s(60, '8')])]),
      ]);

      final history = state.historyFor(current, 'Panca');

      expect(history.anyDay.first.sessionDate, '2026-08-08');
    });

    test('lo storico senza contesto ricade nel fallback, non nel vuoto', () {
      final state = _newState();
      state.workouts.addAll([
        // Sessione vecchia, salvata prima dei giorni preimpostati.
        _session('2026-05-05',
            exercises: [ExerciseLog(name: 'Squat', series: [_s(70, '8')])]),
        _session('2026-08-11', templateId: 'gambe', templateName: 'Gambe',
            exercises: []),
      ]);

      final history = state.historyForToday('Squat');

      expect(history.sameDay, isNull);
      expect(history.anyDay.single.dayName, isNull, reason: 'era libero');
    });

    test('il giorno rinominato si riflette sullo storico via id', () {
      final state = _newState();
      state.templates.add(WorkoutTemplate(id: 'petto', name: 'Petto e bicipiti'));
      state.workouts.addAll([
        _session('2026-08-01', templateId: 'petto', templateName: 'Petto',
            exercises: [ExerciseLog(name: 'Pec fly', series: [_s(30, '12')])]),
        _session('2026-08-08', templateId: 'petto', templateName: 'Petto',
            exercises: []),
      ]);

      expect(state.historyForToday('Pec fly').sameDay!.dayName, 'Petto e bicipiti');
    });

    test('la sessione in corso non entra nella propria storia', () {
      final state = _newState();
      state.workouts.add(_session('2026-08-11', templateId: 'petto',
          templateName: 'Petto',
          exercises: [ExerciseLog(name: 'Pec fly', series: [_s(35, '10')])]));

      expect(state.historyForToday('Pec fly').isEmpty, isTrue);
    });
  });

  group('record', () {
    test('resta globale: non lo filtra il giorno preimpostato', () {
      final state = _newState();
      state.workouts.addAll([
        _session('2026-08-01', templateId: 'petto', templateName: 'Petto',
            exercises: [ExerciseLog(name: 'Pec fly', series: [_s(30, '12')])]),
        _session('2026-08-04', templateId: 'upper', templateName: 'Upper',
            exercises: [ExerciseLog(name: 'Pec fly', series: [_s(45, '10')])]),
        _session('2026-08-11', templateId: 'petto', templateName: 'Petto',
            exercises: []),
      ]);

      // Il massimo arriva dal giorno "Upper" pur essendo in un giorno "Petto".
      expect(state.getBestSeriesEver('Pec fly').first.weight, 45);
    });
  });

  group('applyTemplate', () {
    test('il primo giorno applicato fissa il contesto, il secondo no', () {
      final state = _newState();
      final petto = WorkoutTemplate(id: 'petto', name: 'Petto', exercises: [
        TemplateExercise(name: 'Pec fly', targetSeries: 4, restSeconds: 90),
      ]);
      final upper = WorkoutTemplate(id: 'upper', name: 'Upper', exercises: [
        TemplateExercise(name: 'Lat machine', targetSeries: 3),
      ]);

      state.applyTemplate(petto);
      state.applyTemplate(upper);

      final session = state.todaySession;
      expect(session.templateId, 'petto');
      expect(session.templateName, 'Petto');
      expect(session.exercises.length, 2, reason: 'gli esercizi si aggiungono comunque');
    });

    test('copia le serie target e il recupero sugli esercizi', () {
      final state = _newState();
      state.applyTemplate(WorkoutTemplate(id: 'petto', name: 'Petto', exercises: [
        TemplateExercise(name: 'Pec fly', targetSeries: 4, restSeconds: 90),
      ]));

      final ex = state.todaySession.exercises.single;
      expect(ex.targetSeries, 4);
      expect(ex.restSeconds, 90);
      expect(ex.pendingTargetSeries, 4);
    });

    test('il target non viene sovrascritto da quanto fai davvero', () {
      final state = _newState();
      final template = WorkoutTemplate(id: 'petto', name: 'Petto', exercises: [
        TemplateExercise(name: 'Pec fly', targetSeries: 4),
      ]);
      state.applyTemplate(template);

      final ex = state.todaySession.exercises.single;
      ex.series.addAll([_s(30, '12'), _s(30, '12'), _s(30, '10'),
        _s(30, '10'), _s(27.5, '10')]);

      expect(ex.targetSeries, 4, reason: '5 serie fatte, target invariato');
      expect(ex.pendingTargetSeries, 0);
      expect(template.exercises.single.targetSeries, 4,
          reason: 'il giorno preimpostato non si riscrive');
    });

    test('rinominare il giorno allinea lo snapshot nelle sessioni', () {
      final state = _newState();
      state.templates.add(WorkoutTemplate(id: 'petto', name: 'Petto'));
      state.workouts.add(_session('2026-08-01',
          templateId: 'petto', templateName: 'Petto', exercises: []));

      state.updateTemplate('petto', 'Petto e bicipiti', []);

      expect(state.workouts.first.templateName, 'Petto e bicipiti');
    });

    test('setSessionTemplate etichetta e azzera il contesto', () {
      final state = _newState();
      final session = state.todaySession;
      final petto = WorkoutTemplate(id: 'petto', name: 'Petto');

      state.setSessionTemplate(session, petto);
      expect(session.templateId, 'petto');
      expect(session.isFreeWorkout, isFalse);

      state.setSessionTemplate(session, null);
      expect(session.isFreeWorkout, isTrue);
    });
  });

  group('persistenza', () {
    test('round-trip dei campi nuovi', () {
      final session = _session('2026-08-11',
          templateId: 'petto',
          templateName: 'Petto',
          exercises: [
            ExerciseLog(name: 'Pec fly', targetSeries: 4, series: [_s(30, '12')])
          ]);

      final back = WorkoutSession.fromJson(session.toJson());

      expect(back.templateId, 'petto');
      expect(back.templateName, 'Petto');
      expect(back.exercises.single.targetSeries, 4);
    });

    test('i backup vecchi restano leggibili e senza contesto', () {
      final back = WorkoutSession.fromJson({
        'date': '2026-01-10',
        'exercises': [
          {
            'name': 'Panca piana',
            'series': [
              {'weight': 80, 'reps': '5', 'type': 'normal'}
            ]
          }
        ],
      });

      expect(back.isFreeWorkout, isTrue);
      expect(back.exercises.single.targetSeries, isNull);
      expect(back.exercises.single.series.single.weight, 80);
    });

    test('un giorno preimpostato senza target resta senza target', () {
      final back = TemplateExercise.fromJson({'name': 'Pec fly', 'restSeconds': 90});
      expect(back.targetSeries, isNull);
      expect(back.toJson().containsKey('targetSeries'), isFalse);
    });
  });

  group('import scheda da testo', () {
    test('legge nome, serie e recupero', () {
      final state = _newState();
      final parsed = state.parseTemplateText('''
# Push Day
- Panca piana | 4x | 2:30
- Alzate laterali | 3x
- Pushdown cavo | 60
- Croci ai cavi
''');

      expect(parsed, isNotNull);
      expect(parsed!.name, 'Push Day');
      expect(parsed.exercises.map((e) => e.name).toList(),
          ['Panca piana', 'Alzate laterali', 'Pushdown cavo', 'Croci ai cavi']);
      expect(parsed.exercises[0].targetSeries, 4);
      expect(parsed.exercises[0].restSeconds, 150);
      expect(parsed.exercises[1].targetSeries, 3);
      expect(parsed.exercises[1].restSeconds, isNull);
      // Un numero nudo resta il recupero, come nel formato originale.
      expect(parsed.exercises[2].restSeconds, 60);
      expect(parsed.exercises[2].targetSeries, isNull);
      expect(parsed.exercises[3].restSeconds, isNull);
    });

    test('non tronca i nomi che contengono un separatore', () {
      final state = _newState();
      final parsed = state.parseTemplateText('''
# Pull
- Curl - manubri alternato | 90
''');

      expect(parsed!.exercises.single.name, 'Curl - manubri alternato');
      expect(parsed.exercises.single.restSeconds, 90);
    });
  });
}
