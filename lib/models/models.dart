// lib/models/models.dart

enum SeriesType { normal, help, drop }

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

  const AppPreferences({
    this.language = 'it',
    this.themeMode = 'dark',
    this.accentPreset = 'obsidian',
    this.customAccentHex = '',
    this.dateFormat = 'dd-MM',
    this.setupCompleted = false,
  });

  AppPreferences copyWith({
    String? language,
    String? themeMode,
    String? accentPreset,
    String? customAccentHex,
    String? dateFormat,
    bool? setupCompleted,
  }) {
    return AppPreferences(
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      accentPreset: accentPreset ?? this.accentPreset,
      customAccentHex: customAccentHex ?? this.customAccentHex,
      dateFormat: dateFormat ?? this.dateFormat,
      setupCompleted: setupCompleted ?? this.setupCompleted,
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

  ExerciseLog({
    required this.name,
    List<Series>? series,
  }) : series = series ?? [];

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'series': series.map((s) => s.toJson()).toList(),
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
    );
  }
}

class WorkoutSession {
  String date; // yyyy-MM-dd
  List<ExerciseLog> exercises;

  WorkoutSession({
    required this.date,
    List<ExerciseLog>? exercises,
  }) : exercises = exercises ?? [];

  int get totalSeries => exercises.fold<int>(0, (acc, ex) => acc + ex.series.length);

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'exercises': exercises.map((e) => e.toJson()).toList(),
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
    return WorkoutSession(
      date: _toStringValue(json['date'] ?? json['day']),
      exercises: parsedExercises,
    );
  }
}

class LibraryExercise {
  String id;
  String name;
  String category;

  LibraryExercise({
    required this.id,
    required this.name,
    this.category = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
    };
  }

  factory LibraryExercise.fromJson(Map<String, dynamic> json) {
    final name = _toStringValue(json['name']);
    final id = _toStringValue(json['id']).trim();
    return LibraryExercise(
      id: id.isNotEmpty ? id : _fallbackIdFromName(name),
      name: name,
      category: _toStringValue(json['category']),
    );
  }
}

String _fallbackIdFromName(String name) {
  final normalized = name.toLowerCase().trim();
  final slug = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'_+'), '_');
  return slug.replaceAll(RegExp(r'^_|_$'), '').isEmpty ? 'exercise' : slug;
}
