// lib/widgets/widgets.dart
//
// Componenti condivisi della UI minimal.
//
// Il principio e' uno: meno contenitori. Le liste sono righe piatte separate
// da una linea sottile, i badge sono testo, l'accento si usa solo per
// l'azione principale. Se una schermata ha bisogno di un pezzo nuovo, va qui.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../models/muscle_groups.dart';
import '../theme.dart';
import '../l10n/strings.dart';

// ─── BOTTOM SHEET STANDARD ──────────────────────────────────────────────────
// Tutti i fogli dell'app passano da qui: stesso raggio, stessa maniglia,
// stesso padding.
Future<R?> showAppSheet<R>(
  BuildContext context, {
  required Widget child,
  bool isScrollControlled = true,
}) {
  final media = MediaQuery.of(context);
  return showModalBottomSheet<R>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    // Il foglio non deve mai finire sotto la status bar, nemmeno con la
    // tastiera aperta: lascio sempre libera la zona di sistema + 12px.
    constraints: BoxConstraints(
      maxHeight: media.size.height - media.padding.top - 12,
    ),
    builder: (sheetContext) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: media.size.height - media.padding.top - 12,
        ),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(kRadiusSheet)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
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

/// Titolo standard dentro un bottom sheet, con un'azione opzionale a destra.
class SheetTitle extends StatelessWidget {
  final String text;
  final String? subtitle;
  final Widget? trailing;
  const SheetTitle(this.text, {super.key, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(kGapPage, 16, 12, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text, style: T.title.copyWith(fontSize: 19)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: T.meta),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

// ─── CONFERMA STANDARD ──────────────────────────────────────────────────────
// Solo per cio' che non si puo' annullare.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  String? confirmText,
  bool destructive = false,
}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: message != null ? Text(message) : null,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(S.get('cancel'), style: TextStyle(color: kText2)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(
            confirmText ?? S.get('confirm'),
            style: TextStyle(
              color: destructive ? kRed : kText,
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
  bool error = false,
}) =>
    showAppSnackOn(ScaffoldMessenger.of(context), message,
        onUndo: onUndo, error: error);

/// Come [showAppSnack], ma su un messenger preso prima di chiudere uno sheet
/// o una pagina (dopo il pop il context non e' piu' valido).
void showAppSnackOn(
  ScaffoldMessengerState messenger,
  String message, {
  VoidCallback? onUndo,
  bool error = false,
}) {
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(
          color: error ? kRed : kBg,
          fontSize: 14,
          fontWeight: error ? FontWeight.w600 : FontWeight.w500,
        ),
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
// Tutte le schede si aprono cosi': titolo grande, una riga di contesto,
// azione opzionale a destra, eventuale riga sotto (ricerca o toggle).
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Widget? trailing;
  final Widget? bottom;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.trailing,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          kGapPage, MediaQuery.of(context).padding.top + 18, kGapPage, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: T.display),
                    if (subtitleWidget != null) ...[
                      const SizedBox(height: 4),
                      subtitleWidget!,
                    ] else if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: T.meta),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (bottom != null) ...[const SizedBox(height: 16), bottom!],
        ],
      ),
    );
  }
}

/// Bottone testuale compatto per l'header ("Nuovo giorno", "+ Nuovo"...).
class HeaderAction extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool accent;

  const HeaderAction({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = accent ? Colors.white : kText;
    return Material(
      color: accent ? kAccent : kSurface2,
      borderRadius: BorderRadius.circular(kRadiusControl),
      child: InkWell(
        borderRadius: BorderRadius.circular(kRadiusControl),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(icon != null ? 11 : 14, 8, 14, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: fg),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── CAMPO DI RICERCA ───────────────────────────────────────────────────────
class AppSearchField extends StatefulWidget {
  final String hint;
  final String value;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  const AppSearchField({
    super.key,
    required this.hint,
    required this.value,
    required this.onChanged,
    this.autofocus = false,
  });

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  // Un controller che vive col widget: ricrearlo a ogni build spostava il
  // cursore in fondo e perdeva la selezione mentre scrivevi.
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(AppSearchField old) {
    super.didUpdateWidget(old);
    if (widget.value != _ctrl.text) {
      _ctrl.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      autofocus: widget.autofocus,
      onChanged: widget.onChanged,
      textInputAction: TextInputAction.search,
      style: TextStyle(color: kText, fontSize: 15),
      decoration: InputDecoration(
        hintText: widget.hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        prefixIcon: Icon(Icons.search, color: kText3, size: 20),
        prefixIconConstraints: const BoxConstraints(minWidth: 40),
        suffixIcon: widget.value.isEmpty
            ? null
            : IconButton(
                onPressed: () => widget.onChanged(''),
                icon: Icon(Icons.close, size: 18, color: kText3),
                visualDensity: VisualDensity.compact,
              ),
      ),
    );
  }
}

// ─── TOGGLE SEGMENTATO ──────────────────────────────────────────────────────
// Un solo componente per tutti i selettori a due o piu' voci. Monocromo: il
// segmento attivo si solleva dal binario, non si colora.
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
    final radius = compact ? 8.0 : kRadiusControl;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: kSurface2,
        borderRadius: BorderRadius.circular(radius + 2),
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: labels.asMap().entries.map((e) {
          final isSel = e.key == selected;
          final segment = GestureDetector(
            onTap: () {
              if (!isSel) HapticFeedback.selectionClick();
              onChanged(e.key);
            },
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(
                  vertical: compact ? 6 : 9, horizontal: compact ? 12 : 8),
              decoration: BoxDecoration(
                color: isSel
                    ? (isDarkTheme ? kSurface3 : Colors.white)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(radius),
                boxShadow: isSel && !isDarkTheme
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        )
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                e.value,
                style: GoogleFonts.inter(
                  fontSize: compact ? 12.5 : 13.5,
                  fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                  color: isSel ? kText : kText3,
                ),
              ),
            ),
          );
          return compact ? segment : Expanded(child: segment);
        }).toList(),
      ),
    );
  }
}

// ─── RIGA DI LISTA ──────────────────────────────────────────────────────────
// La riga piatta che sostituisce le card: titolo, riga secondaria, qualcosa
// a destra. La linea sotto separa senza incorniciare.
class ListRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool divider;
  final Color? titleColor;
  final EdgeInsetsGeometry padding;
  final int subtitleMaxLines;

  const ListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.divider = true,
    this.titleColor,
    this.padding = const EdgeInsets.symmetric(horizontal: kGapPage, vertical: 13),
    this.subtitleMaxLines = 3,
  });

  @override
  Widget build(BuildContext context) {
    final row = InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 14)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: T.body.copyWith(color: titleColor ?? kText)),
                  if (subtitleWidget != null) ...[
                    const SizedBox(height: 3),
                    subtitleWidget!,
                  ] else if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: T.meta,
                      maxLines: subtitleMaxLines,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
      ),
    );
    if (!divider) return row;
    // Linea rientrata come il testo: separa senza incorniciare.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row,
        const Divider(indent: kGapPage, endIndent: kGapPage),
      ],
    );
  }
}

/// Freccia discreta a fine riga. Costruttore non const di proposito: un
/// widget const non si ricostruisce al cambio tema e resterebbe col colore
/// vecchio (vedi la nota in MainShell).
class RowChevron extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  RowChevron({super.key});
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.chevron_right, size: 20, color: kText3);
}

// ─── RIGA SERIE ─────────────────────────────────────────────────────────────
// Stessa riga in Oggi e nello Storico: tocca per modificare, scorri per
// eliminare (con annulla).
class SeriesRow extends StatelessWidget {
  final int index;
  final Series series;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const SeriesRow({
    super.key,
    required this.index,
    required this.series,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(
          'series-$index-${series.weight}-${series.reps}-${series.type}-${identityHashCode(series)}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        onDelete();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 4),
        child: const Icon(Icons.delete_outline, color: kRed, size: 20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              SizedBox(
                width: 26,
                child: Text(
                  '${index + 1}',
                  style: T.label.copyWith(
                    fontSize: 14,
                    fontFeatures: kTabular,
                  ),
                ),
              ),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${formatWeight(series.weight)} kg × ${series.reps}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: kText,
                        letterSpacing: -0.2,
                        fontFeatures: kTabular,
                      ),
                    ),
                    SeriesBadge(series.type),
                    if (series.type == SeriesType.drop &&
                        series.drops.isNotEmpty)
                      DropsDisplay(series.drops),
                  ],
                ),
              ),
            ],
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
  final EdgeInsetsGeometry padding;
  const SectionTitle(
    this.text, {
    super.key,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(kGapPage, 22, kGapPage, 6),
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Row(
          children: [
            Expanded(child: Text(text, style: T.label)),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

// ─── BLOCCO ─────────────────────────────────────────────────────────────────
// Un riquadro tenue, senza bordo: per i pochi casi in cui serve raggruppare
// (grafico, mappa del corpo, anteprime).
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
        color: isDarkTheme ? kSurface : kSurface2.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
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

// ─── TIPO SERIE ─────────────────────────────────────────────────────────────
// Solo testo colorato: l'unico colore semantico che resta nella lista.
class SeriesBadge extends StatelessWidget {
  final SeriesType type;
  const SeriesBadge(this.type, {super.key});

  @override
  Widget build(BuildContext context) {
    if (type == SeriesType.normal) return const SizedBox.shrink();
    final isHelp = type == SeriesType.help;
    return Text(
      isHelp ? '* ${S.get('help_short')}' : 'drop',
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: isHelp ? kOrange : kBlue,
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
    return Text(
      drops.map((d) => '→ ${formatWeight(d.weight)}×${d.reps}').join('  '),
      style: TextStyle(fontSize: 13, color: kText2, fontFeatures: kTabular),
    );
  }
}

// ─── ULTIMA VOLTA / RECORD ──────────────────────────────────────────────────
// Contesto dentro lo sheet serie: due viste (ultima sessione, record) scelte
// con un toggle esplicito. Testo su fondo tenue, niente cornici colorate.
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
  bool get _hasBest =>
      widget.bestSeries != null && widget.bestSeries!.isNotEmpty;

  /// Il toggle serve solo se ci sono davvero due viste: passando una lista di
  /// serie vuota la card diventa la sola vista "record".
  bool get _canToggle => _hasLast && _hasBest;

  @override
  Widget build(BuildContext context) {
    final showBest = _hasBest && (_page == 1 || !_hasLast);
    final list = showBest ? widget.bestSeries! : widget.series;
    final onUse = showBest ? widget.onUseBestSeries : widget.onUseSeries;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: kSurface2,
        borderRadius: BorderRadius.circular(kRadiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  showBest
                      ? S.get('best_ever_sub')
                      : (_canToggle
                          ? widget.date
                          : '${S.get('last_time')} · ${widget.date}'),
                  style: T.label.copyWith(fontSize: 12.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_canToggle)
                SegmentedToggle(
                  compact: true,
                  labels: [S.get('tab_last'), S.get('tab_best')],
                  selected: _page,
                  onChanged: (i) => setState(() => _page = i),
                ),
              if (!_canToggle) const SizedBox(width: 6),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Wrap(
              spacing: 14,
              runSpacing: 4,
              children: list.asMap().entries.map((e) {
                final current = !showBest && e.key == widget.currentSeriesIndex;
                return Text(
                  e.value.summary,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: current ? FontWeight.w600 : FontWeight.w400,
                    color: current ? kText : kText2,
                    fontFeatures: kTabular,
                  ),
                );
              }).toList(),
            ),
          ),
          if (onUse != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onUse,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 34),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: kAccent,
                ),
                child: Text(
                  showBest
                      ? S.get('use_best_values')
                      : S.get('use_same_values'),
                  style: const TextStyle(fontSize: 13.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── METRICA ────────────────────────────────────────────────────────────────
/// Un numero con la sua etichetta, senza riquadro.
class Metric extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;

  const Metric(
      {super.key, required this.value, required this.label, this.valueColor});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: T.number.copyWith(
                  fontSize: 24, color: valueColor ?? kText),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label, style: T.label.copyWith(fontSize: 12)),
        ],
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
                Icon(icon, size: 28, color: kText3),
                const SizedBox(height: 14),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: T.title.copyWith(height: 1.35),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: T.meta.copyWith(height: 1.5),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 22),
                HeaderAction(
                  label: actionLabel!,
                  icon: Icons.add,
                  onTap: onAction!,
                ),
              ],
            ],
          ),
        ),
      );
}

// ─── PICKER A PASTIGLIE ─────────────────────────────────────────────────────
/// Una pastiglia selezionabile: piena (testo invertito) se scelta.
class Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? color;

  const Pill({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final active = color ?? kText;
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? active : kSurface2,
          borderRadius: BorderRadius.circular(kRadiusControl),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected
                ? (color == null ? kBg : Colors.white)
                : (onTap == null ? kText3 : kText2),
            fontFeatures: kTabular,
          ),
        ),
      ),
    );
  }
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

  void _add(int secs) {
    setState(() => _total = (_total + secs).clamp(0, 15 * 60));
    HapticFeedback.selectionClick();
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
            Row(
              children: [
                StepButton(label: '−15', onTap: () => _add(-15)),
                Expanded(
                  child: Text(
                    formatRest(_total),
                    textAlign: TextAlign.center,
                    style: T.number.copyWith(fontSize: 44, letterSpacing: -1.5),
                  ),
                ),
                StepButton(label: '+15', onTap: () => _add(15)),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final s in const [30, 60, 90, 120, 150, 180])
                  Pill(
                    label: formatRest(s),
                    selected: _total == s,
                    onTap: () => setState(() => _total = s),
                  ),
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
          child: Text(S.get('confirm')),
        ),
      ],
    );
  }
}

/// Bottone quadrato per gli stepper (−2.5 / +1 / −15...).
class StepButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double size;
  const StepButton(
      {super.key, required this.label, required this.onTap, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kSurface2,
      borderRadius: BorderRadius.circular(kRadiusControl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kRadiusControl),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kText2,
                fontFeatures: kTabular,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── REST LABEL ─────────────────────────────────────────────────────────────
/// Tempo di recupero come testo tappabile. [inherited] = preso dall'ultima
/// volta, non impostato oggi: piu' spento.
class RestBadge extends StatelessWidget {
  final int? seconds;
  final bool inherited;
  final VoidCallback? onTap;

  const RestBadge(
      {super.key, required this.seconds, this.inherited = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = seconds == null || inherited ? kText3 : kText2;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 15, color: color),
            if (seconds != null) ...[
              const SizedBox(width: 3),
              Text(
                formatRest(seconds!),
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontFeatures: kTabular,
                ),
              ),
            ],
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

  const CategoryChip(
      {super.key,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) =>
      Pill(label: label, selected: selected, onTap: onTap);
}

/// Riga di filtri per categoria a scorrimento orizzontale.
class CategoryFilterBar extends StatelessWidget {
  final List<String> categories;
  final String selected; // '' = tutte
  final ValueChanged<String> onChanged;

  const CategoryFilterBar({
    super.key,
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: kGapPage),
        children: [
          CategoryChip(
            label: S.get('all'),
            selected: selected.isEmpty,
            onTap: () => onChanged(''),
          ),
          for (final c in categories) ...[
            const SizedBox(width: 6),
            CategoryChip(
              label: c,
              selected: selected == c,
              onTap: () => onChanged(selected == c ? '' : c),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── MUSCOLI ────────────────────────────────────────────────────────────────
/// I muscoli di un esercizio in una riga di testo: "Petto · Tricipiti, Spalle".
/// I primari prima, i secondari dopo e piu' spenti nel contenuto, non nel
/// colore: non servono tag colorati per dire una cosa cosi' semplice.
String muscleSummary(LibraryExercise ex) {
  String names(List<String> ids) => ids
      .map(getMuscleGroup)
      .whereType<MuscleGroup>()
      .map((m) => m.name(S.lang))
      .join(', ');
  final p = names(ex.primaryMuscles);
  final s = names(ex.secondaryMuscles);
  if (p.isEmpty) return s;
  if (s.isEmpty) return p;
  return '$p · $s';
}

// ─── CHIP GIORNO PREIMPOSTATO ───────────────────────────────────────────────
/// Da quale giorno preimpostato arriva una sessione. [dayName] null o vuoto
/// significa allenamento libero: lo si dice, non si lascia il vuoto.
class DayChip extends StatelessWidget {
  final String? dayName;
  final VoidCallback? onTap;
  final double fontSize;

  const DayChip({super.key, this.dayName, this.onTap, this.fontSize = 13});

  @override
  Widget build(BuildContext context) {
    final named = dayName != null && dayName!.trim().isNotEmpty;
    final label = Text(
      named ? dayName!.trim() : S.get('free_workout'),
      style: TextStyle(
        fontSize: fontSize,
        color: named ? kText : kText3,
        fontWeight: FontWeight.w500,
      ),
      overflow: TextOverflow.ellipsis,
    );

    if (onTap == null) return label;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: label),
          Icon(Icons.expand_more, size: fontSize + 4, color: kText3),
        ],
      ),
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

  /// true = riga di contorno sotto il riquadro principale: piu' spenta.
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
    final summary = series.map((s) => s.summary).join('   ');
    final day = (dayName != null && dayName!.trim().isNotEmpty)
        ? dayName!.trim()
        : S.get('free_workout');

    return InkWell(
      onTap: onUse,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$day · $dateLabel',
                      style: T.label.copyWith(fontSize: 12.5)),
                  const SizedBox(height: 2),
                  Text(
                    summary,
                    style: TextStyle(
                      fontSize: 14.5,
                      color: secondary ? kText2 : kText,
                      fontFeatures: kTabular,
                    ),
                    maxLines: secondary ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onUse != null) ...[
              const SizedBox(width: 8),
              Text(S.get('use'),
                  style: TextStyle(
                      fontSize: 13,
                      color: kAccent,
                      fontWeight: FontWeight.w600)),
            ],
          ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Text(
                '${index + 1}',
                style: T.label.copyWith(
                  fontSize: 14,
                  color: kText3.withValues(alpha: 0.6),
                  fontFeatures: kTabular,
                ),
              ),
            ),
            Text(
              '— ${S.get('series_to_do')}',
              style: TextStyle(fontSize: 15, color: kText3),
            ),
          ],
        ),
      ),
    );
  }
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.get('target_series')),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.get('target_series_desc'), style: T.meta.copyWith(height: 1.4)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var n = 1; n <= kMaxTargetSeries; n++)
                  Pill(
                    label: '$n',
                    selected: _selected == n,
                    onTap: () => setState(() => _selected = n),
                  ),
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
          child: Text(S.get('confirm')),
        ),
      ],
    );
  }
}

// ─── COM'E' ANDATA (VOTO 1-5) ───────────────────────────────────────────────
/// Faccina per un voto da 1 (malissimo) a 5 (benissimo).
IconData moodIcon(int mood) => switch (mood.clamp(1, 5)) {
      1 => Icons.sentiment_very_dissatisfied_outlined,
      2 => Icons.sentiment_dissatisfied_outlined,
      3 => Icons.sentiment_neutral_outlined,
      4 => Icons.sentiment_satisfied_outlined,
      _ => Icons.sentiment_very_satisfied_outlined,
    };

/// Etichetta per un voto da 1 a 5.
String moodLabel(int mood) => S.get('mood_${mood.clamp(1, 5)}');

/// Voto della sessione: la faccina, e se serve l'etichetta accanto.
class RatingBadge extends StatelessWidget {
  final int rating;
  final double fontSize;
  final bool showLabel;
  const RatingBadge(this.rating,
      {super.key, this.fontSize = 13, this.showLabel = true});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(moodIcon(rating), color: kText2, size: fontSize + 5),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              moodLabel(rating),
              style: TextStyle(
                  fontSize: fontSize,
                  color: kText2,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ],
      );
}

/// Dialog "Com'e' andata?": una faccina grande che cambia, l'etichetta e uno
/// slider a 5 scatti. Cinque voti invece di dieci: fra "bene" e "benissimo"
/// si sceglie al volo, fra 7 e 8 no.
class RatingDialog extends StatefulWidget {
  final int? initial;
  final String? confirmText;
  const RatingDialog({super.key, this.initial, this.confirmText});

  /// Ritorna il voto (1-5), 0 se l'utente salta, null se chiude il dialog.
  static Future<int?> show(BuildContext context,
      {int? initial, String? confirmText}) {
    return showDialog<int>(
      context: context,
      builder: (_) =>
          RatingDialog(initial: initial, confirmText: confirmText),
    );
  }

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late int _selected = (widget.initial ?? 3).clamp(1, 5);

  void _set(int value) {
    if (value == _selected) return;
    HapticFeedback.selectionClick();
    setState(() => _selected = value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.get('rate_workout')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          // Toccare la faccina fa avanzare il voto (5 → torna a 1).
          GestureDetector(
            onTap: () => _set(_selected == 5 ? 1 : _selected + 1),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                moodIcon(_selected),
                key: ValueKey(_selected),
                size: 84,
                color: kText,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(moodLabel(_selected), style: T.title.copyWith(fontSize: 20)),
          const SizedBox(height: 8),
          // Rientro di 20: gli scatti dello slider cadono esattamente sopra
          // le cinque faccine piccole.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Slider(
              min: 1,
              max: 5,
              divisions: 4,
              value: _selected.toDouble(),
              onChanged: (v) => _set(v.round()),
            ),
          ),
          Padding(
            // 20 del rientro + 4 di margine interno dello slider − 10 di
            // mezza faccina: ogni faccina sta sotto il suo scatto.
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 1; i <= 5; i++)
                  GestureDetector(
                    onTap: () => _set(i),
                    child: Icon(
                      moodIcon(i),
                      size: 20,
                      color: i == _selected ? kText : kText3,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 0),
          child: Text(S.get('skip'), style: TextStyle(color: kText2)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: Text(widget.confirmText ?? S.get('confirm')),
        ),
      ],
    );
  }
}

// ─── NOTA ───────────────────────────────────────────────────────────────────
/// Unico editor di note, per Oggi e Storico. Ritorna il testo (anche vuoto =
/// cancella) o null se annulli.
Future<String?> showNoteEditor(
  BuildContext context, {
  String? current,
  String? previous,
}) {
  final controller = TextEditingController(text: current ?? '');
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(S.get('note')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (previous != null && (current == null || current.isEmpty)) ...[
            Text(S.get('previous_note'), style: T.label.copyWith(fontSize: 12)),
            const SizedBox(height: 4),
            Text(previous,
                style: T.meta.copyWith(fontStyle: FontStyle.italic)),
            const SizedBox(height: 14),
          ],
          TextField(
            controller: controller,
            style: TextStyle(color: kText),
            maxLines: 4,
            minLines: 2,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: S.get('add_note_hint')),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(S.get('cancel'), style: TextStyle(color: kText2)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, controller.text),
          child: Text(S.get('save')),
        ),
      ],
    ),
  );
}

// ─── MENU AZIONI ────────────────────────────────────────────────────────────
/// Una voce di un menu a foglio.
class SheetAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  const SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });
}

/// Menu a foglio: titolo e un elenco di azioni. Sostituisce le file di
/// icone minuscole: ogni azione ha il suo nome scritto.
Future<void> showActionSheet(
  BuildContext context, {
  required String title,
  String? subtitle,
  required List<SheetAction> actions,
}) {
  return showAppSheet(
    context,
    child: SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetTitle(title, subtitle: subtitle),
          const SizedBox(height: 4),
          for (final a in actions)
            Builder(
              builder: (itemContext) => InkWell(
                onTap: () {
                  Navigator.pop(itemContext);
                  a.onTap();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: kGapPage, vertical: 14),
                  child: Row(
                    children: [
                      Icon(a.icon,
                          size: 21, color: a.destructive ? kRed : kText2),
                      const SizedBox(width: 16),
                      Text(
                        a.label,
                        style: T.body.copyWith(
                            color: a.destructive ? kRed : kText),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
