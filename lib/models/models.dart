// lib/models/models.dart

enum SeriesType { normal, help, drop }

/// Tetto alle serie previste per esercizio in un giorno preimpostato.
const int kMaxTargetSeries = 12;

SeriesType seriesTypeFromString(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'help':
      return SeriesType.help;
    case 'drop':
      return SeriesType.drop;
    default:
      return SeriesType.normal;
  }
}

String seriesTypeToString(SeriesType type) => type.name;

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) {
    final normalized = value.replaceAll(',', '.').trim();
    return double.tryParse(normalized) ?? 0;
  }
  return 0;
}

String _toStringValue(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  if (value is String) return value;
  return value.toString();
}

/// Come [_toStringValue] ma i campi assenti o vuoti restano null: serve ai
/// campi opzionali, dove '' e null devono significare la stessa cosa.
String? _toStringOrNull(dynamic value) {
  if (value == null) return null;
  final text = value is String ? value : value.toString();
  final trimmed = text.trim();
  return trimmed.isEmpty ? null : trimmed;
}

bool _toBool(dynamic value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return fallback;
}

String formatWeight(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(1);
}

class AppPreferences {
  final String language;
  final String themeMode;
  final String accentPreset;
  final String customAccentHex;
  final String dateFormat;
  final bool setupCompleted;
  final bool tourCompleted;

  const AppPreferences({
    this.language = 'it',
    this.themeMode = 'dark',
    this.accentPreset = 'obsidian',
    this.customAccentHex = '',
    this.dateFormat = 'dd-MM',
    this.setupCompleted = false,
    this.tourCompleted = false,
  });

  AppPreferences copyWith({
    String? language,
    String? themeMode,
    String? accentPreset,
    String? customAccentHex,
    String? dateFormat,
    bool? setupCompleted,
    bool? tourCompleted,
  }) {
    return AppPreferences(
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      accentPreset: accentPreset ?? this.accentPreset,
      customAccentHex: customAccentHex ?? this.customAccentHex,
      dateFormat: dateFormat ?? this.dateFormat,
      setupCompleted: setupCompleted ?? this.setupCompleted,
      tourCompleted: tourCompleted ?? this.tourCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'themeMode': themeMode,
      'accentPreset': accentPreset,
      'customAccentHex': customAccentHex,
      'dateFormat': dateFormat,
      'setupCompleted': setupCompleted,
      'tourCompleted': tourCompleted,
    };
  }

  factory AppPreferences.fromJson(Map<String, dynamic> json) {
    return AppPreferences(
      language: _toStringValue(json['language'], 'it'),
      themeMode: _toStringValue(json['themeMode'], 'dark'),
      accentPreset: _toStringValue(json['accentPreset'], 'obsidian'),
      customAccentHex: _toStringValue(json['customAccentHex']),
      dateFormat: _toStringValue(json['dateFormat'], 'dd-MM'),
      setupCompleted: _toBool(json['setupCompleted'], false),
      tourCompleted: _toBool(json['tourCompleted'], false),
    );
  }
}

class DropEntry {
  final double weight;
  final String reps;

  const DropEntry({
    required this.weight,
    required this.reps,
  });

  Map<String, dynamic> toJson() {
    return {
      'weight': weight,
      'reps': reps,
    };
  }

  factory DropEntry.fromJson(Map<String, dynamic> json) {
    return DropEntry(
      weight: _toDouble(json['weight']),
      reps: _toStringValue(json['reps']),
    );
  }
}

class Series {
  final double weight;
  final String reps;
  final SeriesType type;
  final List<DropEntry> drops;

  const Series({
    required this.weight,
    required this.reps,
    this.type = SeriesType.normal,
    List<DropEntry>? drops,
  }) : drops = drops ?? const [];

  String get summary {
    final base = '${formatWeight(weight)}x$reps${type == SeriesType.help ? '*' : ''}';
    if (type != SeriesType.drop || drops.isEmpty) {
      return base;
    }
    final tail = drops.map((d) => '${formatWeight(d.weight)}x${d.reps}').join(' -> ');
    return '$base -> $tail';
  }

  Map<String, dynamic> toJson() {
    return {
      'weight': weight,
      'reps': reps,
      'type': seriesTypeToString(type),
      'drops': drops.map((d) => d.toJson()).toList(),
    };
  }

  factory Series.fromJson(Map<String, dynamic> json) {
    final rawDrops = json['drops'];
    final parsedDrops = <DropEntry>[];
    if (rawDrops is List) {
      for (final item in rawDrops) {
        if (item is Map<String, dynamic>) {
          parsedDrops.add(DropEntry.fromJson(item));
        } else if (item is Map) {
          parsedDrops.add(DropEntry.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return Series(
      weight: _toDouble(json['weight']),
      reps: _toStringValue(json['reps']),
      type: seriesTypeFromString(_toStringValue(json['type'])),
      drops: parsedDrops,
    );
  }
}

class ExerciseLog {
  String name;
  List<Series> series;
  String? note;
  int? restSeconds;

  /// Serie previste dal giorno preimpostato, copiate all'applicazione del
  /// giorno. È solo un promemoria: [series] registra sempre il reale, e fare
  /// più o meno serie del previsto non tocca questo valore.
  int? targetSeries;

  ExerciseLog({
    required this.name,
    List<Series>? series,
    this.note,
    this.restSeconds,
    this.targetSeries,
  }) : series = series ?? [];

  /// Righe da fare ancora per arrivare al target (0 se il target manca o è
  /// già stato raggiunto/superato).
  int get pendingTargetSeries {
    final target = targetSeries;
    if (target == null) return 0;
    final missing = target - series.length;
    return missing > 0 ? missing : 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'series': series.map((s) => s.toJson()).toList(),
      if (note != null && note!.isNotEmpty) 'note': note,
      if (restSeconds != null) 'restSeconds': restSeconds,
      if (targetSeries != null) 'targetSeries': targetSeries,
    };
  }

  factory ExerciseLog.fromJson(Map<String, dynamic> json) {
    final rawSeries = json['series'] ?? json['sets'];
    final parsedSeries = <Series>[];
    if (rawSeries is List) {
      for (final item in rawSeries) {
        if (item is Map<String, dynamic>) {
          parsedSeries.add(Series.fromJson(item));
        } else if (item is Map) {
          parsedSeries.add(Series.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return ExerciseLog(
      name: _toStringValue(json['name'] ?? json['exercise']),
      series: parsedSeries,
      note: json['note'] != null ? _toStringValue(json['note']) : null,
      restSeconds: _toIntOrNull(json['restSeconds']),
      targetSeries: _toIntOrNull(json['targetSeries']),
    );
  }
}

int? _toIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final n = int.tryParse(value.trim());
    return n;
  }
  return null;
}

/// Data breve ("12-08" o "08-12") secondo la preferenza dell'utente.
String formatShortDate(String isoDate, String dateFormat) {
  final parts = isoDate.split('-');
  if (parts.length < 3) return isoDate;
  final dd = parts[2].padLeft(2, '0');
  final mm = parts[1].padLeft(2, '0');
  return dateFormat == 'MM-dd' ? '$mm-$dd' : '$dd-$mm';
}

String formatRest(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

class WorkoutSession {
  String date; // yyyy-MM-dd
  List<ExerciseLog> exercises;
  int? rating; // 1-10 post-workout feeling

  /// Giorno preimpostato a cui appartiene la sessione; null = allenamento
  /// libero. Serve a confrontare un esercizio con la volta in cui l'hai fatto
  /// nella STESSA posizione di giornata: una Pec fly a fine "Petto", dopo due
  /// esercizi di petto, non è confrontabile con la stessa Pec fly a inizio
  /// "Upper".
  ///
  /// [templateId] è la chiave del confronto; [templateName] è lo snapshot del
  /// nome, che tiene in piedi l'etichetta anche se il giorno viene rinominato
  /// o cancellato. Le serie non duplicano niente: il contesto si legge da qui.
  String? templateId;
  String? templateName;

  WorkoutSession({
    required this.date,
    List<ExerciseLog>? exercises,
    this.rating,
    this.templateId,
    this.templateName,
  }) : exercises = exercises ?? [];

  int get totalSeries => exercises.fold<int>(0, (acc, ex) => acc + ex.series.length);

  /// true se la sessione non appartiene a nessun giorno preimpostato.
  bool get isFreeWorkout => templateId == null && templateName == null;

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      if (rating != null) 'rating': rating,
      if (templateId != null) 'templateId': templateId,
      if (templateName != null) 'templateName': templateName,
    };
  }

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    final rawExercises = json['exercises'] ?? json['logs'];
    final parsedExercises = <ExerciseLog>[];
    if (rawExercises is List) {
      for (final item in rawExercises) {
        if (item is Map<String, dynamic>) {
          parsedExercises.add(ExerciseLog.fromJson(item));
        } else if (item is Map) {
          parsedExercises.add(ExerciseLog.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    final rawRating = json['rating'];
    int? parsedRating;
    if (rawRating is int) {
      parsedRating = rawRating;
    } else if (rawRating is num) {
      parsedRating = rawRating.toInt();
    }

    // Lo storico scritto prima dei giorni preimpostati non ha il contesto:
    // resta null e il lookup ricade sul fallback "in qualsiasi giorno".
    return WorkoutSession(
      date: _toStringValue(json['date'] ?? json['day']),
      exercises: parsedExercises,
      rating: parsedRating,
      templateId: _toStringOrNull(json['templateId']),
      templateName: _toStringOrNull(json['templateName']),
    );
  }
}

class LibraryExercise {
  String id;
  String name;
  String category;
  List<String> primaryMuscles;
  List<String> secondaryMuscles;

  LibraryExercise({
    required this.id,
    required this.name,
    this.category = '',
    List<String>? primaryMuscles,
    List<String>? secondaryMuscles,
  })  : primaryMuscles = primaryMuscles ?? [],
        secondaryMuscles = secondaryMuscles ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'primaryMuscles': primaryMuscles,
      'secondaryMuscles': secondaryMuscles,
    };
  }

  factory LibraryExercise.fromJson(Map<String, dynamic> json) {
    final name = _toStringValue(json['name']);
    final id = _toStringValue(json['id']).trim();
    return LibraryExercise(
      id: id.isNotEmpty ? id : _fallbackIdFromName(name),
      name: name,
      category: _toStringValue(json['category']),
      primaryMuscles: _toStringList(json['primaryMuscles']),
      secondaryMuscles: _toStringList(json['secondaryMuscles']),
    );
  }
}

class TemplateExercise {
  String name;
  int? restSeconds;

  /// Serie previste per questo esercizio nel giorno. All'applicazione del
  /// giorno l'app precrea altrettante righe da compilare; il valore qui non
  /// viene mai riscritto da quello che fai davvero in palestra.
  int? targetSeries;

  TemplateExercise({required this.name, this.restSeconds, this.targetSeries});

  TemplateExercise copyWith({
    String? name,
    int? restSeconds,
    bool clearRest = false,
    int? targetSeries,
    bool clearTarget = false,
  }) {
    return TemplateExercise(
      name: name ?? this.name,
      restSeconds: clearRest ? null : (restSeconds ?? this.restSeconds),
      targetSeries: clearTarget ? null : (targetSeries ?? this.targetSeries),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (restSeconds != null) 'restSeconds': restSeconds,
      if (targetSeries != null) 'targetSeries': targetSeries,
    };
  }

  factory TemplateExercise.fromJson(Map<String, dynamic> json) {
    return TemplateExercise(
      name: _toStringValue(json['name']),
      restSeconds: _toIntOrNull(json['restSeconds']),
      targetSeries: _toIntOrNull(json['targetSeries']),
    );
  }
}

class WorkoutTemplate {
  String id;
  String name;
  List<TemplateExercise> exercises;

  WorkoutTemplate({
    required this.id,
    required this.name,
    List<TemplateExercise>? exercises,
  }) : exercises = exercises ?? [];

  List<String> get exerciseNames => exercises.map((e) => e.name).toList();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) {
    final parsed = <TemplateExercise>[];
    final rawExercises = json['exercises'];
    if (rawExercises is List) {
      for (final item in rawExercises) {
        if (item is Map<String, dynamic>) {
          parsed.add(TemplateExercise.fromJson(item));
        } else if (item is Map) {
          parsed.add(TemplateExercise.fromJson(Map<String, dynamic>.from(item)));
        } else if (item is String) {
          parsed.add(TemplateExercise(name: item));
        }
      }
    } else {
      // backward-compat: old field exerciseNames: List<String>
      for (final n in _toStringList(json['exerciseNames'])) {
        parsed.add(TemplateExercise(name: n));
      }
    }
    return WorkoutTemplate(
      id: _toStringValue(json['id']),
      name: _toStringValue(json['name']),
      exercises: parsed,
    );
  }
}

// ─── STORICO CONTESTUALE ────────────────────────────────────────────────────

/// Un'occorrenza passata di un esercizio, con il giorno da cui arriva.
/// Senza il giorno i numeri non si leggono: la stessa Pec fly pesa diverso
/// se è la prima cosa che fai o se ci arrivi dopo due esercizi di petto.
class ExerciseHistoryHit {
  final ExerciseLog log;
  final String sessionDate; // yyyy-MM-dd
  /// Nome del giorno preimpostato; null = quella volta era allenamento libero.
  final String? dayName;

  const ExerciseHistoryHit({
    required this.log,
    required this.sessionDate,
    this.dayName,
  });

  List<Series> get series => log.series;
  bool get isFreeWorkout => dayName == null;
}

/// Storia di un esercizio letta dal punto di vista di una sessione:
/// l'ultima volta nello stesso giorno preimpostato più il fallback con le
/// ultime occorrenze in qualsiasi giorno. Il record NON sta qui: resta
/// globale (`AppState.getBestSeriesEver`).
class ExerciseHistory {
  final ExerciseHistoryHit? sameDay;

  /// L'ultima volta in un giorno DIVERSO da quello della sessione di
  /// riferimento (libero incluso): è il confronto che spiega perché altrove
  /// i numeri sono altri. null quando la sessione è libera o quando
  /// l'esercizio lo si è sempre fatto in questo stesso giorno.
  final ExerciseHistoryHit? lastElsewhere;

  /// Ultime occorrenze in qualsiasi giorno, dalla più recente.
  final List<ExerciseHistoryHit> anyDay;

  const ExerciseHistory({
    this.sameDay,
    this.lastElsewhere,
    this.anyDay = const [],
  });

  static const ExerciseHistory empty = ExerciseHistory();

  bool get isEmpty => sameDay == null && anyDay.isEmpty;

  /// L'occorrenza da cui precompilare i campi: quella dello stesso giorno se
  /// esiste, altrimenti niente — in allenamento libero le occorrenze si
  /// mostrano tutte e sceglie l'utente, senza euristiche.
  ExerciseHistoryHit? get prefillSource => sameDay;

  /// La nota più pertinente da riproporre: quella dello stesso giorno, se c'è.
  String? get relevantNote {
    final note = sameDay?.log.note;
    if (note != null && note.isNotEmpty) return note;
    for (final hit in anyDay) {
      final n = hit.log.note;
      if (n != null && n.isNotEmpty) return n;
    }
    return null;
  }
}

List<String> _toStringList(dynamic value) {
  if (value is List) {
    return value.whereType<String>().toList();
  }
  return [];
}

String _fallbackIdFromName(String name) {
  final normalized = name.toLowerCase().trim();
  final slug = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'_+'), '_');
  return slug.replaceAll(RegExp(r'^_|_$'), '').isEmpty ? 'exercise' : slug;
}
