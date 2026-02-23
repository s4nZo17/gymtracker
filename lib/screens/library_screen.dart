// lib/screens/library_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../services/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final filtered = state.library.where((e) =>
          e.name.toLowerCase().contains(_search.toLowerCase()) ||
          e.category.toLowerCase().contains(_search.toLowerCase())
        ).toList();

        // Group by category
        final grouped = <String, List<LibraryExercise>>{};
        for (final ex in filtered) {
          final cat = ex.category.isNotEmpty ? ex.category : 'Senza categoria';
          grouped.putIfAbsent(cat, () => []).add(ex);
        }

        return Scaffold(
          backgroundColor: kBg,
          appBar: AppBar(title: Text('Esercizi')),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Cerca...',
                    prefixIcon: Icon(Icons.search, color: kText3),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? EmptyState(
                        emoji: '',
                        title: 'Nessun esercizio trovato',
                        subtitle: _search.isEmpty ? 'Aggiungi il primo!' : null,
                      )
                    : ListView.builder(
                        itemCount: grouped.keys.length,
                        itemBuilder: (_, groupIdx) {
                          final cat = grouped.keys.elementAt(groupIdx);
                          final exs = grouped[cat]!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionTitle(cat),
                              ...exs.map((ex) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
                                child: Slidable(
                                  endActionPane: ActionPane(
                                    motion: const DrawerMotion(),
                                    children: [
                                      SlidableAction(
                                        onPressed: (_) => _editExercise(context, state, ex),
                                        backgroundColor: kSurface2,
                                        foregroundColor: kAccent,
                                        icon: Icons.edit_outlined,
                                        label: 'Modifica',
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      SlidableAction(
                                        onPressed: (_) => state.removeFromLibrary(ex.id),
                                        backgroundColor: kRed.withValues(alpha: 0.2),
                                        foregroundColor: kRed,
                                        icon: Icons.delete_outline,
                                        label: 'Elimina',
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: kSurface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: kSurface3),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(ex.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                                              if (ex.category.isNotEmpty)
                                                Text(ex.category, style: TextStyle(fontSize: 12, color: kText3)),
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.chevron_left, color: kText3, size: 16),
                                        Text('scorri', style: TextStyle(fontSize: 11, color: kText3)),
                                      ],
                                    ),
                                  ),
                                ),
                              )),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _addExercise(context, context.read<AppState>()),
            backgroundColor: kAccent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _addExercise(BuildContext context, AppState state) {
    _showExerciseDialog(context, state, null);
  }

  void _editExercise(BuildContext context, AppState state, LibraryExercise ex) {
    _showExerciseDialog(context, state, ex);
  }

  void _showExerciseDialog(BuildContext context, AppState state, LibraryExercise? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final catCtrl = TextEditingController(text: existing?.category ?? '');
    final categories = ['Petto', 'Schiena', 'Gambe', 'Spalle', 'Bicipiti', 'Tricipiti', 'Core'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: kSurface3, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                existing != null ? 'Modifica Esercizio' : 'Nuovo Esercizio',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: InputDecoration(labelText: 'Nome esercizio'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: catCtrl,
                decoration: InputDecoration(labelText: 'Categoria (opzionale)'),
              ),
              const SizedBox(height: 10),
              // Quick category chips
              Wrap(
                spacing: 8, runSpacing: 6,
                children: categories.map((c) => GestureDetector(
                  onTap: () => catCtrl.text = c,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: kSurface2,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kSurface3),
                    ),
                    child: Text(c, style: TextStyle(fontSize: 12, color: kText2)),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  if (existing != null) {
                    state.updateLibraryExercise(existing.id, name, catCtrl.text.trim());
                  } else {
                    state.addToLibrary(name, catCtrl.text.trim());
                  }
                  Navigator.pop(context);
                },
                child: Text(existing != null ? 'Aggiorna' : 'Salva esercizio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


