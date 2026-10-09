// test/finish_workout_test.dart
//
// Chiusura dell'allenamento, annulla, cambio di giorno preimpostato e voto
// da 1 a 5 (con la conversione dei voti vecchi da 1 a 10).

import 'package:flutter_test/flutter_test.dart';
import 'package:gymtracker2/models/models.dart';
import 'package:gymtracker2/services/app_state.dart';
import 'package:gymtracker2/services/storage_service.dart';

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

String get _today => DateTime.now().toIso8601String().split('T').first;

final _pull = WorkoutTemplate(
  id: 'pull',
  name: 'Pull Day',
  exercises: [
    TemplateExercise(name: 'Lat machine', targetSeries: 3),
    TemplateExercise(name: 'Curl bilanciere'),
  ],
);

/// Allenamento in corso con una serie di panca.
AppState _withWorkout({bool withSeries = true}) {
  final state = _newState();
  state.templates.add(_pull);
  final session = state.todaySession;
  state.addExerciseToSession(session, 'Panca piana');
  if (withSeries) {
    state.addSeriesToSession(session, 0, const Series(weight: 80, reps: '8'));
  }
  return state;
}

void main() {
  group('voto 1-5', () {
    test('i voti vecchi 1-10 si convertono alla lettura', () {
      expect(
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map(moodFromLegacyRating).toList(),
        [1, 1, 2, 2, 3, 3, 4, 4, 5, 5],
      );
      final old = WorkoutSession.fromJson({
        'date': '2026-08-01',
        'exercises': [],
        'rating': 8,
      });
      expect(old.rating, 4);
    });

    test('il voto nuovo si salva come mood e si rilegge uguale', () {
      final s = WorkoutSession(date: '2026-10-09', rating: 2);
      final json = s.toJson();
      expect(json['mood'], 2);
      expect(json.containsKey('rating'), isFalse);
      expect(WorkoutSession.fromJson(json).rating, 2);
    });

    test('mood ha la precedenza su rating', () {
      final s = WorkoutSession.fromJson(
          {'date': '2026-10-09', 'exercises': [], 'mood': 5, 'rating': 2});
      expect(s.rating, 5);
    });
  });

  group('finisci allenamento', () {
    test('salva la sessione col voto e apre una giornata nuova', () {
      final state = _withWorkout();
      final old = state.todaySession;

      final done = state.finishWorkout(mood: 4);

      expect(done, isNotNull);
      expect(done!.saved, isTrue);
      expect(state.workouts, contains(old));
      expect(old.rating, 4);
      expect(identical(state.todaySession, old), isFalse);
      expect(state.todaySession.exercises, isEmpty);
      expect(state.todaySession.date, _today);
    });

    test('senza serie non resta nello Storico', () {
      final state = _withWorkout(withSeries: false);
      final old = state.todaySession;

      final done = state.finishWorkout();

      expect(done!.saved, isFalse);
      expect(state.workouts, isNot(contains(old)));
    });

    test('annulla riapre la sessione com\'era, voto compreso', () {
      final state = _withWorkout();
      final old = state.todaySession;
      final countBefore = state.workouts.length;

      final done = state.finishWorkout(mood: 5);
      state.undoFinish(done!);

      expect(identical(state.todaySession, old), isTrue);
      expect(old.rating, isNull);
      expect(state.workouts.length, countBefore);
    });

    test('annulla dopo "non salvare" rimette la sessione al suo posto', () {
      final state = _withWorkout();
      final old = state.todaySession;
      final index = state.workouts.indexOf(old);

      final done = state.finishWorkout(save: false);
      expect(state.workouts, isNot(contains(old)));
      state.undoFinish(done!);

      expect(state.workouts.indexOf(old), index);
      expect(identical(state.todaySession, old), isTrue);
    });

    test('una sessione vuota non si chiude', () {
      final state = _newState();
      final session = state.todaySession;
      expect(state.finishWorkout(), isNull);
      expect(identical(state.todaySession, session), isTrue);
    });
  });

  group('cambio giorno preimpostato', () {
    test('salva e inizia: la vecchia resta, la nuova ha solo il giorno', () {
      final state = _withWorkout();
      final old = state.todaySession;

      state.finishWorkout(next: _pull);

      expect(state.workouts, contains(old));
      final now = state.todaySession;
      expect(now.exercises.map((e) => e.name), ['Lat machine', 'Curl bilanciere']);
      expect(now.templateId, 'pull');
      expect(now.exercises.first.targetSeries, 3);
    });

    test('non salvare: la vecchia sparisce, la nuova ha il giorno', () {
      final state = _withWorkout();
      final old = state.todaySession;

      state.finishWorkout(save: false, next: _pull);

      expect(state.workouts, isNot(contains(old)));
      expect(state.todaySession.templateId, 'pull');
      expect(state.todaySession.exercises.length, 2);
    });

    test('con la giornata vuota il giorno si carica e basta', () {
      final state = _newState();
      final session = state.todaySession;

      expect(state.finishWorkout(next: _pull), isNull);

      expect(identical(state.todaySession, session), isTrue);
      expect(session.templateId, 'pull');
    });
  });
}
