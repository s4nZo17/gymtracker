// lib/widgets/widgets.dart
//
// Componenti condivisi della UI 2.0.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme.dart';
import '../l10n/strings.dart';

// ─── BOTTOM SHEET STANDARD ──────────────────────────────────────────────────
// Tutti i fogli dell'app passano da qui: stesso raggio, stessa maniglia,
// stesso padding. Piu coerenza = piu semplicita d'uso.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required Widget child,
  bool isScrollControlled = true,
}) {
  final media = MediaQuery.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    // Il foglio non deve mai finire sotto la status bar, nemmeno con la
    // tastiera aperta: lascio sempre libera la zona di sistema + 12px.
    constraints: BoxConstraints(
      maxHeight: media.size.height - media.padding.top - 12,
    ),
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: media.size.height - media.padding.top - 12,
        ),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(kRadiusSheet)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: kSurface3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Titolo standard dentro un bottom sheet.
class SheetTitle extends StatelessWidget {
  final String text;
  final String? subtitle;
  const SheetTitle(this.text, {super.key, this.subtitle});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: kText,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(subtitle!, style: TextStyle(fontSize: 13, color: kText2)),
            ],
          ],
        ),
      );
}

// ─── CONFERMA STANDARD ──────────────────────────────────────────────────────
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  String? confirmText,
  bool destructive = false,
}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: message != null ? Text(message) : null,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(S.get('cancel'), style: TextStyle(color: kText2)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            confirmText ?? S.get('confirm'),
            style: TextStyle(
              color: destructive ? kRed : kAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
  return res == true;
}

// ─── SNACKBAR STANDARD ──────────────────────────────────────────────────────
// Un solo modo di dare feedback. Se l'azione e' annullabile passa onUndo:
// niente conferme preventive, si agisce subito e si puo' tornare indietro.
void showAppSnack(
  BuildContext context,
  String message, {
  VoidCallback? onUndo,
  IconData? icon,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: kAccent),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(message, style: TextStyle(color: kText, fontSize: 13.5)),
          ),
        ],
      ),
      duration: Duration(seconds: onUndo != null ? 5 : 2),
      action: onUndo == null
          ? null
          : SnackBarAction(
              label: S.get('undo'),
              textColor: kAccent,
              onPressed: onUndo,
            ),
    ),
  );
}

// ─── HEADER DI PAGINA ───────────────────────────────────────────────────────
// Tutte e cinque le schede usano questo header: stesso titolo, stesso
// allineamento, stessa aria. Sostituisce le AppBar disomogenee della 2.0.
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? bottom;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          kGapPage, MediaQuery.of(context).padding.top + 14, kGapPage, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                        color: kText,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!,
                          style: TextStyle(fontSize: 13, color: kText2)),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (bottom != null) ...[const SizedBox(height: 12), bottom!],
        ],
      ),
    );
  }
}

// ─── CAMPO DI RICERCA ───────────────────────────────────────────────────────
class AppSearchField extends StatelessWidget {
  final String hint;
  final String value;
  final ValueChanged<String> onChanged;

  const AppSearchField({
    super.key,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: value);
    controller.selection =
        TextSelection.collapsed(offset: controller.text.length);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: TextStyle(color: kText, fontSize: 14.5),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        prefixIcon: Icon(Icons.search, color: kText3, size: 20),
        prefixIconConstraints: const BoxConstraints(minWidth: 42),
        suffixIcon: value.isEmpty
            ? null
            : IconButton(
                onPressed: () => onChanged(''),
                icon: Icon(Icons.close, size: 18, color: kText3),
                visualDensity: VisualDensity.compact,
              ),
      ),
    );
  }
}

// ─── TOGGLE SEGMENTATO ──────────────────────────────────────────────────────
// Un solo componente per tutti i selettori a due o piu' voci
// (Grafici/Mappa, Peso/Volume, Incolla/Da file, IT/EN, Scuro/Chiaro...).
class SegmentedToggle extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  final bool compact;

  const SegmentedToggle({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: kSurface2,
        borderRadius: BorderRadius.circular(compact ? 11 : 14),
      ),
      child: Row(
        children: labels.asMap().entries.map((e) {
          final isSel = e.key == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isSel) HapticFeedback.selectionClick();
                onChanged(e.key);
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(vertical: compact ? 7 : 11),
                decoration: BoxDecoration(
                  color: isSel ? kAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(compact ? 9 : 11),
                ),
                alignment: Alignment.center,
                child: Text(
                  e.value,
                  style: TextStyle(
                    fontSize: compact ? 12.5 : 14,
                    fontWeight: FontWeight.w600,
                    color: isSel ? Colors.white : kText2,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── RIGA SERIE ─────────────────────────────────────────────────────────────
// Stessa riga in Oggi e nello Storico: tocca per modificare, scorri per
// eliminare (con annulla). Niente piu' "x" sempre armata sotto il pollice.
class SeriesRow extends StatelessWidget {
  final int index;
  final Series series;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool dense;

  const SeriesRow({
    super.key,
    required this.index,
    required this.series,
    required this.onTap,
    required this.onDelete,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('series-$index-${series.weight}-${series.reps}-${series.type}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        onDelete();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        decoration: BoxDecoration(
          color: kRed.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: kRed, size: 20),
      ),
      child: Material(
        color: kSurface2.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: 10, vertical: dense ? 7 : 10),
            child: Row(
              children: [
                SeriesNumBadge(index + 1),
                const SizedBox(width: 10),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${formatWeight(series.weight)} kg × ${series.reps}',
                        style: GoogleFonts.inter(
                          fontSize: dense ? 14 : 15,
                          fontWeight: FontWeight.w600,
                          color: kText,
                        ),
                      ),
                      SeriesBadge(series.type),
                      if (series.type == SeriesType.drop && series.drops.isNotEmpty)
                        DropsDisplay(series.drops),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: kText3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── SECTION TITLE ──────────────────────────────────────────────────────────
class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Text(
              text.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.6,
                color: kText3,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

// ─── CARD BASE ──────────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: borderColor ?? kSurface3.withValues(alpha: 0.6)),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(kRadiusCard),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

// ─── SERIES BADGE ───────────────────────────────────────────────────────────
class SeriesBadge extends StatelessWidget {
  final SeriesType type;
  const SeriesBadge(this.type, {super.key});

  @override
  Widget build(BuildContext context) {
    if (type == SeriesType.normal) return const SizedBox.shrink();
    final isHelp = type == SeriesType.help;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: (isHelp ? kOrange : kBlue).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        isHelp ? '* ${S.get('help_short')}' : 'drop',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isHelp ? kOrange : kBlue,
        ),
      ),
    );
  }
}

// ─── DROPS DISPLAY ──────────────────────────────────────────────────────────
class DropsDisplay extends StatelessWidget {
  final List<DropEntry> drops;
  const DropsDisplay(this.drops, {super.key});

  @override
  Widget build(BuildContext context) {
    if (drops.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: drops
          .map(
            (d) => Text(
              '→ ${formatWeight(d.weight)}×${d.reps}',
              style: const TextStyle(fontSize: 12, color: kBlue),
            ),
          )
          .toList(),
    );
  }
}

// ─── SERIES NUMBER BADGE ────────────────────────────────────────────────────
class SeriesNumBadge extends StatelessWidget {
  final int num;
  final bool accent;
  const SeriesNumBadge(this.num, {super.key, this.accent = false});

  @override
  Widget build(BuildContext context) => Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: accent ? kAccent.withValues(alpha: 0.14) : kSurface2,
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: Text(
          '$num',
          style: TextStyle(
            fontSize: 12,
            color: accent ? kAccent : kText2,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

// ─── LAST SESSION / RECORD CARD ─────────────────────────────────────────────
class LastSessionCard extends StatefulWidget {
  final String date;
  final List<Series> series;
  final List<Series>? bestSeries;
  final VoidCallback? onUseSeries;
  final VoidCallback? onUseBestSeries;
  final int currentSeriesIndex;

  const LastSessionCard({
    super.key,
    required this.date,
    required this.series,
    this.bestSeries,
    this.onUseSeries,
    this.onUseBestSeries,
    this.currentSeriesIndex = 0,
  });

  @override
  State<LastSessionCard> createState() => _LastSessionCardState();
}

class _LastSessionCardState extends State<LastSessionCard> {
  int _page = 0;

  bool get _hasLast => widget.series.isNotEmpty;
  bool get _hasBest => widget.bestSeries != null && widget.bestSeries!.isNotEmpty;

  /// Il toggle serve solo se ci sono davvero due viste: passando una lista di
  /// serie vuota la card diventa la sola vista "record".
  bool get _canToggle => _hasLast && _hasBest;

  @override
  Widget build(BuildContext context) {
    // Niente piu' PageView ad altezza calcolata a mano (andava in overflow
    // quando le serie erano tante): la card si dimensiona sul contenuto e le
    // due viste si scelgono con un toggle esplicito, non con uno swipe nascosto.
    final showBest = _hasBest && (_page == 1 || !_hasLast);
    final highlight = showBest ? kOrange : kAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: highlight.withValues(alpha: 0.06),
        border: Border.all(color: highlight.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(showBest ? Icons.emoji_events : Icons.bolt,
                  color: highlight, size: 15),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  // Col toggle accanto, ripetere "ULTIMA VOLTA" era rumore:
                  // basta dire di quale sessione si tratta.
                  showBest
                      ? (_canToggle
                          ? S.get('best_ever_sub')
                          : '${S.get('tab_best')} · ${S.get('best_ever_sub')}')
                      : (_canToggle
                          ? widget.date
                          : '${S.get('last_session')} · ${widget.date}'),
                  style: TextStyle(
                    fontSize: 11,
                    color: highlight,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_canToggle)
                SizedBox(
                  width: 132,
                  child: SegmentedToggle(
                    compact: true,
                    labels: [S.get('tab_last'), S.get('tab_best')],
                    selected: _page,
                    onChanged: (i) => setState(() => _page = i),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: (showBest ? widget.bestSeries! : widget.series)
                .asMap()
                .entries
                .map((e) {
              final isHighlighted =
                  !showBest && e.key == widget.currentSeriesIndex;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? highlight.withValues(alpha: 0.16)
                      : kSurface2,
                  borderRadius: BorderRadius.circular(8),
                  border: isHighlighted
                      ? Border.all(color: highlight.withValues(alpha: 0.4))
                      : null,
                ),
                child: Text(
                  'S${e.key + 1}: ${e.value.summary}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isHighlighted ? highlight : kText2,
                    fontWeight:
                        isHighlighted ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              );
            }).toList(),
          ),
          if ((showBest ? widget.onUseBestSeries : widget.onUseSeries) !=
              null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: highlight.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap:
                      showBest ? widget.onUseBestSeries : widget.onUseSeries,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.download_outlined, size: 15, color: highlight),
                        const SizedBox(width: 6),
                        Text(
                          showBest
                              ? S.get('use_best_values')
                              : S.get('use_same_values'),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: highlight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── STAT CARD ──────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;

  const StatCard({super.key, required this.value, required this.label, this.valueColor});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(kRadiusCard),
          border: Border.all(color: kSurface3.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
                color: valueColor ?? kAccent,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11.5, color: kText2)),
          ],
        ),
      );
}

// ─── EMPTY STATE ────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;

  /// Etichetta + azione del bottone principale: uno stato vuoto dovrebbe
  /// sempre dire come uscirne, non solo constatare che non c'e' niente.
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 32, 40, 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        kAccent.withValues(alpha: 0.16),
                        kAccent.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Icon(icon, size: 34, color: kAccent),
                ),
                const SizedBox(height: 18),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: kText,
                  height: 1.4,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.5, color: kText2, height: 1.5),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 22),
                SizedBox(
                  width: 220,
                  child: ElevatedButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}

// ─── REST PICKER ────────────────────────────────────────────────────────────
class RestPickerDialog extends StatefulWidget {
  final int? initial;
  const RestPickerDialog({super.key, this.initial});

  static Future<int?> show(BuildContext context, {int? initial}) {
    return showDialog<int?>(
      context: context,
      builder: (_) => RestPickerDialog(initial: initial),
    );
  }

  @override
  State<RestPickerDialog> createState() => _RestPickerDialogState();
}

class _RestPickerDialogState extends State<RestPickerDialog> {
  late int _total;

  @override
  void initState() {
    super.initState();
    _total = widget.initial ?? 90;
  }

  void _haptic() => HapticFeedback.selectionClick();

  void _add(int secs) {
    setState(() => _total = (_total + secs).clamp(0, 15 * 60));
    _haptic();
  }

  Widget _preset(String label, int secs) {
    final selected = _total == secs;
    return GestureDetector(
      onTap: () {
        setState(() => _total = secs);
        _haptic();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? kAccent.withValues(alpha: 0.18) : kSurface2,
          borderRadius: BorderRadius.circular(kRadiusControl),
          border: Border.all(color: selected ? kAccent : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: selected ? kAccent : kText2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _stepBtn(String label, int delta) {
    return Expanded(
      child: Material(
        color: kSurface2,
        borderRadius: BorderRadius.circular(kRadiusControl),
        child: InkWell(
          onTap: () => _add(delta),
          borderRadius: BorderRadius.circular(kRadiusControl),
          child: Container(
            height: 46,
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: delta > 0 ? kAccent : kText2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.get('set_rest')),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // display grande del tempo scelto
            Text(
              formatRest(_total),
              style: GoogleFonts.inter(
                fontSize: 52,
                fontWeight: FontWeight.w600,
                letterSpacing: -1,
                color: kAccent,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _stepBtn('-30s', -30),
                const SizedBox(width: 8),
                _stepBtn('-5s', -5),
                const SizedBox(width: 8),
                _stepBtn('+5s', 5),
                const SizedBox(width: 8),
                _stepBtn('+30s', 30),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _preset('0:30', 30),
                _preset('1:00', 60),
                _preset('1:30', 90),
                _preset('2:00', 120),
                _preset('2:30', 150),
                _preset('3:00', 180),
              ],
            ),
          ],
        ),
      ),
      actions: [
        if (widget.initial != null)
          TextButton(
            onPressed: () => Navigator.pop(context, 0),
            child: Text(S.get('remove_rest'), style: const TextStyle(color: kRed)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(S.get('cancel'), style: TextStyle(color: kText2)),
        ),
        TextButton(
          onPressed: _total == 0 ? null : () => Navigator.pop(context, _total),
          child: Text(
            S.get('confirm'),
            style: TextStyle(color: kAccent, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// ─── REST BADGE ─────────────────────────────────────────────────────────────
class RestBadge extends StatelessWidget {
  final int seconds;
  final bool inherited;
  final VoidCallback? onTap;

  const RestBadge({super.key, required this.seconds, this.inherited = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = inherited ? kText3 : kAccent;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: inherited ? kSurface2 : kAccent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              formatRest(seconds),
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CATEGORY CHIP ──────────────────────────────────────────────────────────
class CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? kAccent : kSurface2,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: selected ? Colors.white : kText2,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      );
}

// ─── MUSCLE TAG ─────────────────────────────────────────────────────────────
class MuscleTag extends StatelessWidget {
  final String label;
  final bool primary;
  const MuscleTag({super.key, required this.label, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: primary ? kAccent.withValues(alpha: 0.14) : kSurface2,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.5, color: primary ? kAccent : kText3),
      ),
    );
  }
}

// ─── CHIP GIORNO PREIMPOSTATO ───────────────────────────────────────────────
/// Da quale giorno preimpostato arriva una sessione. [dayName] null o vuoto
/// significa allenamento libero: lo si dice, non si lascia il vuoto.
class DayChip extends StatelessWidget {
  final String? dayName;
  final VoidCallback? onTap;
  final double fontSize;

  const DayChip({super.key, this.dayName, this.onTap, this.fontSize = 11.5});

  @override
  Widget build(BuildContext context) {
    final named = dayName != null && dayName!.trim().isNotEmpty;
    final color = named ? kAccent : kText3;

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: named ? kAccent.withValues(alpha: 0.12) : kSurface2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(named ? Icons.flash_on : Icons.flash_off,
              size: fontSize + 1, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              named ? dayName!.trim() : S.get('free_workout'),
              style: TextStyle(
                fontSize: fontSize,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 2),
            Icon(Icons.expand_more, size: fontSize + 3, color: color),
          ],
        ],
      ),
    );

    if (onTap == null) return chip;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: chip,
    );
  }
}

// ─── RIGA STORICO ───────────────────────────────────────────────────────────
/// Un'occorrenza passata di un esercizio: giorno di provenienza, data e serie
/// fatte. Tappabile per riusarne i valori. In allenamento libero se ne mostra
/// una per occorrenza: nessuna euristica decide quale sia "quella giusta".
class HistoryHitRow extends StatelessWidget {
  final String? dayName;
  final String dateLabel;
  final List<Series> series;
  final VoidCallback? onUse;

  /// true = riga di contorno sotto il riquadro principale: piu' piccola,
  /// piu' spenta, una riga sola.
  final bool secondary;

  const HistoryHitRow({
    super.key,
    this.dayName,
    required this.dateLabel,
    required this.series,
    this.onUse,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = secondary ? 11.5 : 12.5;
    final summary = series.map((s) => s.summary).join('   ');

    final content = Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: secondary ? 7 : 9),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: DayChip(
                        dayName: dayName,
                        fontSize: secondary ? 10.5 : 11.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateLabel,
                      style: TextStyle(fontSize: fontSize - 0.5, color: kText3),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  summary,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: secondary ? kText2 : kText,
                    fontWeight: secondary ? FontWeight.w400 : FontWeight.w500,
                  ),
                  maxLines: secondary ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onUse != null) ...[
            const SizedBox(width: 8),
            Icon(Icons.download_outlined, size: 16, color: kText3),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: kSurface2.withValues(alpha: secondary ? 0.55 : 1),
        borderRadius: BorderRadius.circular(12),
        child: onUse == null
            ? content
            : InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onUse,
                child: content,
              ),
      ),
    );
  }
}

// ─── RIGA SERIE DA FARE ─────────────────────────────────────────────────────
/// Segnaposto per una serie prevista dal giorno ma non ancora registrata.
/// Non e' un dato: e' un promemoria tappabile, cosi' lo storico resta pulito.
class PendingSeriesRow extends StatelessWidget {
  final int index;
  final VoidCallback onTap;

  const PendingSeriesRow({super.key, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: DottedBorderBox(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: kSurface2,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        color: kText3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    S.get('series_to_do'),
                    style: TextStyle(fontSize: 13, color: kText3),
                  ),
                  const Spacer(),
                  Icon(Icons.add, size: 18, color: kText3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cornice tratteggiata leggera: distingue a colpo d'occhio cio' che e' ancora
/// da fare da cio' che e' registrato.
class DottedBorderBox extends StatelessWidget {
  final Widget child;
  const DottedBorderBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(color: kSurface3),
      child: child,
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  const _DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );

    const dash = 5.0;
    const gap = 4.0;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter oldDelegate) => oldDelegate.color != color;
}

// ─── PICKER SERIE PREVISTE ──────────────────────────────────────────────────
/// Quante serie prevede il giorno preimpostato per un esercizio.
/// Ritorna il numero scelto, 0 per "nessuna indicazione", null se annulli.
class TargetSeriesDialog extends StatefulWidget {
  final int? initial;
  const TargetSeriesDialog({super.key, this.initial});

  static Future<int?> show(BuildContext context, {int? initial}) {
    return showDialog<int?>(
      context: context,
      builder: (_) => TargetSeriesDialog(initial: initial),
    );
  }

  @override
  State<TargetSeriesDialog> createState() => _TargetSeriesDialogState();
}

class _TargetSeriesDialogState extends State<TargetSeriesDialog> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial ?? 3;
  }

  Widget _option(int n) {
    final selected = _selected == n;
    return GestureDetector(
      onTap: () {
        setState(() => _selected = n);
        HapticFeedback.selectionClick();
      },
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? kAccent.withValues(alpha: 0.18) : kSurface2,
          borderRadius: BorderRadius.circular(kRadiusControl),
          border: Border.all(color: selected ? kAccent : Colors.transparent),
        ),
        child: Text(
          '$n',
          style: TextStyle(
            fontSize: 15,
            color: selected ? kAccent : kText2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.get('target_series')),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              S.get('target_series_desc'),
              style: TextStyle(fontSize: 12.5, color: kText2, height: 1.4),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (var n = 1; n <= kMaxTargetSeries; n++) _option(n),
              ],
            ),
          ],
        ),
      ),
      actions: [
        if (widget.initial != null)
          TextButton(
            onPressed: () => Navigator.pop(context, 0),
            child: Text(S.get('remove_target'),
                style: const TextStyle(color: kRed)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(S.get('cancel'), style: TextStyle(color: kText2)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: Text(
            S.get('confirm'),
            style: TextStyle(color: kAccent, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// ─── RATING BADGE ───────────────────────────────────────────────────────────
class RatingBadge extends StatelessWidget {
  final int rating;
  final double fontSize;
  const RatingBadge(this.rating, {super.key, this.fontSize = 11});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: fontSize * 0.7, vertical: fontSize * 0.35),
        decoration: BoxDecoration(
          color: kAccent.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite, color: kAccent, size: fontSize + 1),
            const SizedBox(width: 3),
            Text(
              '$rating/10',
              style: TextStyle(fontSize: fontSize, color: kAccent, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
}
