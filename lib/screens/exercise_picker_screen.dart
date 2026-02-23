// lib/screens/exercise_picker_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import 'library_screen.dart';

class ExercisePickerScreen extends StatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  State<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends State<ExercisePickerScreen> {
  String _search = '';
  String _selectedCat = 'Tutti';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final categories = ['Tutti', ...{...state.library.map((e) => e.category).where((c) => c.isNotEmpty)}];

        final filtered = state.library.where((ex) {
          final matchSearch = ex.name.toLowerCase().contains(_search.toLowerCase());
          final matchCat = _selectedCat == 'Tutti' || ex.category == _selectedCat;
          return matchSearch && matchCat;
        }).toList();

        // Group by category
        final grouped = <String, List<dynamic>>{};
        for (final ex in filtered) {
          final cat = ex.category.isNotEmpty ? ex.category : 'Altro';
          grouped.putIfAbsent(cat, () => []).add(ex);
        }

        return Scaffold(
          backgroundColor: kBg,
          appBar: AppBar(
            title: Text('Aggiungi Esercizio'),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LibraryScreen()),
                ),
                icon: Icon(Icons.add, color: kAccent, size: 18),
                label: Text('Nuovo', style: TextStyle(color: kAccent)),
              ),
            ],
          ),
          body: Column(
            children: [
              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Cerca esercizio...',
                    prefixIcon: Icon(Icons.search, color: kText3),
                  ),
                ),
              ),

              // Category chips
              SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => CategoryChip(
                    label: categories[i],
                    selected: _selectedCat == categories[i],
                    onTap: () => setState(() => _selectedCat = categories[i]),
                  ),
                ),
              ),

              // List
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyState(emoji: '', title: 'Nessun esercizio trovato')
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _selectedCat == 'Tutti' ? grouped.keys.length : 1,
                        itemBuilder: (context, groupIdx) {
                          final catName = _selectedCat == 'Tutti'
                              ? grouped.keys.elementAt(groupIdx)
                              : _selectedCat;
                          final exercises = grouped[catName] ?? filtered;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_selectedCat == 'Tutti')
                                SectionTitle(catName),
                              ...exercises.map((ex) {
                                final lastLog = state.getLastExerciseLog(ex.name);
                                final alreadyAdded = state.todaySession.exercises
                                    .any((e) => e.name == ex.name);

                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
                                  child: GestureDetector(
                                    onTap: () {
                                      state.addExerciseToToday(ex.name);
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: alreadyAdded ? kAccent.withValues(alpha: 0.05) : kSurface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: alreadyAdded ? kAccent.withValues(alpha: 0.3) : kSurface3,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      ex.name,
                                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                                    ),
                                                    if (alreadyAdded) ...[
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: kAccent.withValues(alpha: 0.15),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text('gia aggiunto', style: TextStyle(fontSize: 10, color: kAccent)),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  lastLog != null
                                                      ? 'Ultima volta: ${lastLog.series.map((s) => s.summary).join(' / ')}'
                                                      : 'Nessuna sessione precedente',
                                                  style: TextStyle(fontSize: 12, color: kText2),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(Icons.add_circle_outline, color: kText3, size: 20),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}



