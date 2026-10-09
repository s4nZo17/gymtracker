// lib/screens/history_screen.dart
//
// Storico: un elenco piatto di sessioni, raggruppate per mese. Una riga per
// allenamento (data, giorno, quanto hai fatto); tocchi e si apre la sessione,
// che si modifica con gli stessi blocchi di Oggi.
//
// Prima la card si espandeva sul posto, con bottoni e cinque icone per
// esercizio: in lista ora resta solo cio' che serve a riconoscere un giorno.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import 'session_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final active = state.todaySession;
        final order = {
          for (var i = 0; i < state.workouts.length; i++) state.workouts[i]: i
        };
        // L'allenamento in corso entra nello Storico solo quando ha almeno una
        // serie: finche' e' una lista di esercizi da fare vive in Oggi.
        final all = state.workouts
            .where((w) =>
                w.exercises.isNotEmpty &&
                (!identical(w, active) || w.totalSeries > 0))
            .toList()
          // A parita' di data, il piu' recente (e quindi quello in corso)
          // va per primo.
          ..sort((a, b) {
            final byDate = b.date.compareTo(a.date);
            return byDate != 0 ? byDate : order[b]!.compareTo(order[a]!);
          });

        final term = _search.trim().toLowerCase();
        final sessions = term.isEmpty
            ? all
            : all
                .where((s) =>
                    s.exercises.any((e) => e.name.toLowerCase().contains(term)))
                .toList();

        final locale = state.prefs.language == 'en' ? 'en_US' : 'it_IT';
        final now = DateTime.now();
        final thisMonth = all.where((s) {
          final d = DateTime.tryParse(s.date);
          return d != null && d.year == now.year && d.month == now.month;
        }).length;

        final items = <Widget>[];
        String currentMonth = '';
        for (final s in sessions) {
          final d = DateTime.tryParse(s.date);
          final monthKey = d == null
              ? ''
              : DateFormat('MMMM yyyy', locale).format(DateTime(d.year, d.month));
          if (monthKey != currentMonth) {
            currentMonth = monthKey;
            items.add(SectionTitle(_capitalize(monthKey)));
          }
          items.add(_SessionRow(
            session: s,
            locale: locale,
            highlight: term,
            isActive: identical(s, state.todaySession),
          ));
        }

        return Scaffold(
          backgroundColor: kBg,
          body: Column(
            children: [
              PageHeader(
                title: S.get('history'),
                subtitle: all.isEmpty
                    ? null
                    : '${all.length} ${S.get('workouts_count')} · $thisMonth ${S.get('this_month_short')}',
                bottom: all.isEmpty
                    ? null
                    : AppSearchField(
                        hint: S.get('search_in_history'),
                        value: _search,
                        onChanged: (v) => setState(() => _search = v),
                      ),
              ),
              Expanded(
                child: all.isEmpty
                    ? EmptyState(
                        title: S.get('no_workouts'),
                        subtitle: S.get('start_first_workout'),
                      )
                    : sessions.isEmpty
                        ? EmptyState(
                            title: S.get('no_results'),
                            subtitle: S.get('try_other_search'),
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.only(bottom: kBottomSafeSpace),
                            itemCount: items.length,
                            itemBuilder: (_, i) => items[i],
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class _SessionRow extends StatelessWidget {
  final WorkoutSession session;
  final String locale;
  final String highlight;
  final bool isActive;

  const _SessionRow({
    required this.session,
    required this.locale,
    required this.highlight,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final date = DateTime.tryParse(session.date) ?? DateTime.now();
    final dayName = state.dayNameOf(session);

    // Il titolo e' il giorno preimpostato se c'e'; altrimenti i primi
    // esercizi, che bastano a riconoscere un allenamento libero.
    final names = session.exercises.map((e) => e.name).toList();
    final matched = highlight.isEmpty
        ? const <String>[]
        : names.where((n) => n.toLowerCase().contains(highlight)).toList();
    final title = dayName ?? names.take(2).join(', ');
    final meta = [
      '${session.exercises.length} ${S.get('exercises_count')}',
      '${session.totalSeries} ${S.get('series')}',
      if (matched.isNotEmpty) matched.join(', '),
    ].join(' · ');

    return ListRow(
      title: title,
      subtitle: meta,
      leading: SizedBox(
        width: 40,
        child: Column(
          children: [
            Text(
              DateFormat('d', locale).format(date),
              style: T.title.copyWith(fontSize: 19, fontFeatures: kTabular),
            ),
            Text(
              DateFormat('EEE', locale).format(date).replaceAll('.', ''),
              style: T.label.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(S.get('in_progress'),
                  style: T.label.copyWith(color: kAccent, fontSize: 12)),
            )
          else if (session.rating != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: RatingBadge(session.rating!, fontSize: 13, showLabel: false),
            ),
          RowChevron(),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SessionScreen(session: session)),
      ),
    );
  }
}
