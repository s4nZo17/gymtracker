// lib/models/muscle_groups.dart

class MuscleGroup {
  final String id;
  final String nameIt;
  final String nameEn;
  final bool visibleFront;
  final bool visibleBack;

  const MuscleGroup({
    required this.id,
    required this.nameIt,
    required this.nameEn,
    this.visibleFront = false,
    this.visibleBack = false,
  });

  String name(String lang) => lang == 'it' ? nameIt : nameEn;
}

const allMuscleGroups = [
  MuscleGroup(id: 'chest', nameIt: 'Petto', nameEn: 'Chest', visibleFront: true),
  MuscleGroup(id: 'upper_back', nameIt: 'Schiena alta', nameEn: 'Upper back', visibleBack: true),
  MuscleGroup(id: 'lats', nameIt: 'Dorsali', nameEn: 'Lats', visibleBack: true),
  MuscleGroup(id: 'shoulders', nameIt: 'Spalle', nameEn: 'Shoulders', visibleFront: true, visibleBack: true),
  MuscleGroup(id: 'biceps', nameIt: 'Bicipiti', nameEn: 'Biceps', visibleFront: true),
  MuscleGroup(id: 'triceps', nameIt: 'Tricipiti', nameEn: 'Triceps', visibleBack: true),
  MuscleGroup(id: 'forearms', nameIt: 'Avambracci', nameEn: 'Forearms', visibleFront: true),
  MuscleGroup(id: 'abs', nameIt: 'Addominali', nameEn: 'Abs', visibleFront: true),
  MuscleGroup(id: 'quads', nameIt: 'Quadricipiti', nameEn: 'Quads', visibleFront: true),
  MuscleGroup(id: 'hamstrings', nameIt: 'Femorali', nameEn: 'Hamstrings', visibleBack: true),
  MuscleGroup(id: 'glutes', nameIt: 'Glutei', nameEn: 'Glutes', visibleBack: true),
  MuscleGroup(id: 'calves', nameIt: 'Polpacci', nameEn: 'Calves', visibleFront: true, visibleBack: true),
];

MuscleGroup? getMuscleGroup(String id) {
  for (final m in allMuscleGroups) {
    if (m.id == id) return m;
  }
  return null;
}

/// Default muscle mappings for built-in exercises.
/// Key = exercise name (lowercase), value = {primary: [...], secondary: [...]}
const defaultMuscleMappings = <String, Map<String, List<String>>>{
  'panca piana': {'primary': ['chest'], 'secondary': ['triceps', 'shoulders']},
  'panca inclinata manubri': {'primary': ['chest'], 'secondary': ['shoulders', 'triceps']},
  'chest press': {'primary': ['chest'], 'secondary': ['triceps', 'shoulders']},
  'croci ai cavi': {'primary': ['chest'], 'secondary': ['shoulders']},

  'lat machine avanti': {'primary': ['lats'], 'secondary': ['biceps', 'upper_back']},
  'pulley basso': {'primary': ['lats'], 'secondary': ['biceps', 'upper_back']},
  'rematore manubrio': {'primary': ['lats'], 'secondary': ['biceps', 'upper_back']},
  'pulldown presa stretta': {'primary': ['lats'], 'secondary': ['biceps']},

  'squat bilanciere': {'primary': ['quads', 'glutes'], 'secondary': ['hamstrings', 'abs']},
  'leg press': {'primary': ['quads', 'glutes'], 'secondary': ['hamstrings']},
  'affondi camminati': {'primary': ['quads', 'glutes'], 'secondary': ['hamstrings']},
  'leg extension': {'primary': ['quads'], 'secondary': []},
  'leg curl': {'primary': ['hamstrings'], 'secondary': []},
  'stacchi rumeni': {'primary': ['hamstrings', 'glutes'], 'secondary': ['lats']},

  'military press': {'primary': ['shoulders'], 'secondary': ['triceps']},
  'alzate laterali': {'primary': ['shoulders'], 'secondary': []},
  'rear delts machine': {'primary': ['shoulders'], 'secondary': ['upper_back']},

  'curl bilanciere': {'primary': ['biceps'], 'secondary': ['forearms']},
  'curl manubri alternato': {'primary': ['biceps'], 'secondary': ['forearms']},
  'curl cavo basso': {'primary': ['biceps'], 'secondary': []},

  'pushdown cavo': {'primary': ['triceps'], 'secondary': []},
  'french press': {'primary': ['triceps'], 'secondary': []},
  'dip alle parallele': {'primary': ['triceps'], 'secondary': ['chest', 'shoulders']},

  'crunch machine': {'primary': ['abs'], 'secondary': []},
  'plank': {'primary': ['abs'], 'secondary': []},
  'hanging leg raise': {'primary': ['abs'], 'secondary': []},
};

/// Look up default muscles for an exercise name.
Map<String, List<String>>? getDefaultMuscles(String exerciseName) {
  final key = exerciseName.trim().toLowerCase();
  return defaultMuscleMappings[key];
}

/// Stimulation level from effective sets count.
enum StimulationLevel { none, low, medium, high }

StimulationLevel stimulationFromSets(double effectiveSets) {
  if (effectiveSets <= 0) return StimulationLevel.none;
  if (effectiveSets <= 5) return StimulationLevel.low;
  if (effectiveSets <= 12) return StimulationLevel.medium;
  return StimulationLevel.high;
}
