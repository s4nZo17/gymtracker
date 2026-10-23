// lib/widgets/widgets.dart
//
// Componenti condivisi del redesign "Lista".
//
// Il principio: i contenuti stanno in blocchi grigi (Block) con le righe
// separate da una linea rientrata; sopra ogni blocco un'etichetta in
// maiuscolo (SectionTitle). L'accento solo su cio' che si tocca per agire.
// Se una schermata ha bisogno di un pezzo nuovo, va qui.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
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
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: kDashed,
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
        padding: const EdgeInsets.fromLTRB(kGapPage, 18, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text,
                      style: T.title
                          .copyWith(fontSize: 22, fontWeight: FontWeight.w700)),
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
// Tutte le schede si aprono cosi': titolo grande a sinistra e, sulla stessa
// linea di base, un dato in colore accento a destra ("23 ottobre",
// "104 allenamenti"). Sotto, eventualmente, ricerca o toggle.
class PageHeader extends StatelessWidget {
  final String title;

  /// Testo a destra del titolo, in accento.
  final String? meta;

  /// Al posto di [meta], quando a destra serve un'azione.
  final Widget? trailing;
  final Widget? bottom;

  /// Spazio tra il titolo e [bottom].
  final double bottomGap;

  const PageHeader({
    super.key,
    required this.title,
    this.meta,
    this.trailing,
    this.bottom,
    this.bottomGap = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          kGapPage, MediaQuery.of(context).padding.top + 16, kGapPage, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: T.display,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                ),
              ),
              if (trailing != null)
                trailing!
              else if (meta != null) ...[
                const SizedBox(width: 12),
                Text(meta!, style: T.displayMeta),
              ],
            ],
          ),
          if (bottom != null) ...[SizedBox(height: bottomGap), bottom!],
        ],
      ),
    );
  }
}

/// Bottone compatto ("+ Nuovo", "Crea"): grigio, o pieno in accento.
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
      color: accent ? kAccent : kSurface3,
      borderRadius: BorderRadius.circular(kRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(kRadius),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(icon != null ? 12 : 16, 10, 16, 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
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

/// Bottone quadrato con un'icona, alto come un campo di ricerca: il "+"
/// accanto alla ricerca in Progressi.
class SquareIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;
  final String? tooltip;
  final double size;

  const SquareIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: kSurface,
      borderRadius: BorderRadius.circular(kRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(kRadius),
        onTap: onTap,
        child: SizedBox(width: size, height: size, child: Center(child: icon)),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

// ─── ICONE A TRATTO ─────────────────────────────────────────────────────────
// Il "+" e il play dell'app: disegnati a tratto, con estremita' arrotondate.
// Le icone Material sono piene o col tratto sottile.

/// "+" a tratto. [stroke] e' lo spessore della linea.
class PlusIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final double stroke;
  // Non const: legge i colori del tema (vedi RowChevron).
  // ignore: prefer_const_constructors_in_immutables
  PlusIcon({super.key, this.size = 22, this.color, this.stroke = 2.4});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _PlusPainter(color ?? kAccentText, stroke),
      );
}

class _PlusPainter extends CustomPainter {
  final Color color;
  final double stroke;
  _PlusPainter(this.color, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    // Stesse proporzioni del "+" a 24: braccia da 5 a 19.
    final a = size.width * 5 / 24;
    final b = size.width * 19 / 24;
    final c = size.width / 2;
    canvas.drawLine(Offset(a, c), Offset(b, c), p);
    canvas.drawLine(Offset(c, a), Offset(c, b), p);
  }

  @override
  bool shouldRepaint(_PlusPainter old) =>
      old.color != color || old.stroke != stroke;
}

/// Triangolo del play, vuoto: solo il contorno, con gli angoli arrotondati.
class PlayIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final double stroke;
  // Non const: legge i colori del tema (vedi RowChevron).
  // ignore: prefer_const_constructors_in_immutables
  PlayIcon({super.key, this.size = 22, this.color, this.stroke = 2});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _PlayPainter(color ?? kText2, stroke),
      );
}

class _PlayPainter extends CustomPainter {
  final Color color;
  final double stroke;
  _PlayPainter(this.color, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 24;
    final path = Path()
      ..moveTo(7 * u, 4.5 * u)
      ..lineTo(19.5 * u, 12 * u)
      ..lineTo(7 * u, 19.5 * u)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_PlayPainter old) =>
      old.color != color || old.stroke != stroke;
}

// ─── BOTTONE TRATTEGGIATO ───────────────────────────────────────────────────
/// "Aggiungi un esercizio  +": bordo tratteggiato, fondo trasparente. Dice
/// "qui puoi aggiungere" senza pesare quanto un bottone pieno.
class DashedButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const DashedButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(kRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(kRadius),
        onTap: onTap,
        child: CustomPaint(
          painter: _DashedBorderPainter(kDashed),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: kTextSoft,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PlusIcon(size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.5),
      const Radius.circular(kRadius - 0.5),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}

/// Separatore "—— oppure ——" fra due modi di fare la stessa cosa.
class OrSeparator extends StatelessWidget {
  // Non const: legge i colori del tema (vedi RowChevron).
  // ignore: prefer_const_constructors_in_immutables
  OrSeparator({super.key});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Container(height: 1, color: kLine)),
          const SizedBox(width: 12),
          Text(
            S.get('or'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: kTextFaint,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: kLine)),
        ],
      );
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
        // Sulla pagina il campo e' un blocco come gli altri.
        fillColor: blockColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        prefixIcon: Icon(Icons.search, color: kText2, size: 20),
        prefixIconConstraints: const BoxConstraints(minWidth: 46),
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

  /// Colore del binario: kSurface sulla pagina, kSurface2 dentro un blocco.
  final Color? trackColor;

  const SegmentedToggle({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.compact = false,
    this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 34 : 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: trackColor ?? kSurface,
        borderRadius: BorderRadius.circular(kRadius),
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
              padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 8),
              decoration: BoxDecoration(
                color: isSel
                    ? (isDarkTheme ? kSurface3 : Colors.white)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(kRadius - 2),
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
                style: TextStyle(
                  fontSize: compact ? 13.5 : 14,
                  fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                  color: isSel ? kText : kText2,
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

// ─── BLOCCO ─────────────────────────────────────────────────────────────────
// Il contenitore di base: un riquadro grigio con le righe dentro, separate da
// una linea rientrata (a filo a destra, mai dopo l'ultima riga).
class Block extends StatelessWidget {
  final List<Widget> children;

  /// Margine esterno: di solito il margine di pagina ai lati.
  final EdgeInsetsGeometry margin;

  /// Rientro a sinistra delle linee fra le righe.
  final double indent;

  /// false per i blocchi che contengono un solo pezzo (grafico, mappa).
  final bool dividers;
  final EdgeInsetsGeometry padding;

  const Block({
    super.key,
    required this.children,
    this.margin = const EdgeInsets.symmetric(horizontal: kGapPage),
    this.indent = kBlockInset,
    this.dividers = true,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0 && dividers) {
        items.add(Divider(height: 1, thickness: 1, indent: indent));
      }
      items.add(children[i]);
    }
    return Padding(
      padding: margin,
      child: Material(
        color: blockColor,
        borderRadius: BorderRadius.circular(kRadius),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: items,
          ),
        ),
      ),
    );
  }
}

/// Colore dei blocchi: nel tema chiaro un grigio appena accennato, perche' il
/// fondo e kSurface sono entrambi bianchi.
Color get blockColor =>
    isDarkTheme ? kSurface : kSurface2.withValues(alpha: 0.7);

/// Un riquadro grigio senza righe: grafici, mappa del corpo, anteprime.
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
    return Material(
      color: blockColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadius),
        side: borderColor == null
            ? BorderSide.none
            : BorderSide(color: borderColor!),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}

// ─── RIGA DI LISTA ──────────────────────────────────────────────────────────
// La riga di un blocco: titolo, riga secondaria, qualcosa a destra. Le linee
// fra le righe le disegna il Block.
class ListRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? titleColor;

  /// Stile del titolo: di default [T.title]; le righe di impostazioni usano
  /// il piu' leggero [T.body].
  final TextStyle? titleStyle;
  final EdgeInsetsGeometry padding;
  final int subtitleMaxLines;
  final double minHeight;

  const ListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.titleColor,
    this.titleStyle,
    this.padding = const EdgeInsets.fromLTRB(kBlockInset, 14, 12, 14),
    this.subtitleMaxLines = 3,
    this.minHeight = 56,
  });

  @override
  Widget build(BuildContext context) {
    final style = titleStyle ?? T.title;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Padding(
          padding: padding,
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 16)],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: style.copyWith(color: titleColor ?? style.color),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitleWidget != null) ...[
                      const SizedBox(height: 5),
                      subtitleWidget!,
                    ] else if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 5),
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
      ),
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
      Icon(Icons.chevron_right, size: 22, color: kTextFaint);
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
        color: kRed.withValues(alpha: 0.12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        child: const Icon(Icons.delete_outline, color: kRed, size: 20),
      ),
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 46),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(kBlockInset, 10, 12, 10),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: kText2,
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: kText,
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
      ),
    );
  }
}

// ─── ETICHETTA DI SEZIONE ───────────────────────────────────────────────────
/// "GIORNI PREIMPOSTATI": maiuscolo, piccolo, spaziato. A destra un'azione o
/// un dato (che resta in minuscolo).
class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;

  /// Accanto al testo (per esempio una freccia ▾ o una faccina).
  final Widget? after;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const SectionTitle(
    this.text, {
    super.key,
    this.trailing,
    this.after,
    this.onTap,
    this.padding = const EdgeInsets.fromLTRB(kGapPage, 24, kGapPage, 8),
  });

  @override
  Widget build(BuildContext context) {
    Widget label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            text.toUpperCase(),
            style: T.section,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (after != null) ...[const SizedBox(width: 4), after!],
      ],
    );
    if (onTap != null) {
      label = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: label,
      );
    }
    return Padding(
      padding: padding,
      child: SizedBox(
        height: 32,
        child: Row(
          children: [
            Expanded(
              child: Align(alignment: Alignment.centerLeft, child: label),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// Dato a destra di un'etichetta di sezione ("7 allenamenti").
class SectionMeta extends StatelessWidget {
  final String text;
  const SectionMeta(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: kText2,
          fontFeatures: kTabular,
        ),
      );
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

// ─── ULTIMA VOLTA ───────────────────────────────────────────────────────────
// Contesto dentro lo sheet serie: le serie dell'ultima volta (nello stesso
// giorno preimpostato), con quella che stai per fare in evidenza.
class LastSessionCard extends StatelessWidget {
  final String date;
  final List<Series> series;
  final VoidCallback? onUseSeries;
  final int currentSeriesIndex;

  const LastSessionCard({
    super.key,
    required this.date,
    required this.series,
    this.onUseSeries,
    this.currentSeriesIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      decoration: BoxDecoration(
        color: kSurface2,
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(S.get('last_time').toUpperCase(), style: T.section),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  date,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 13, color: kText2),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: series.asMap().entries.map((e) {
              final current = e.key == currentSeriesIndex;
              return Text(
                e.value.summary,
                style: TextStyle(
                  fontSize: 17,
                  letterSpacing: 0.2,
                  fontWeight: current ? FontWeight.w700 : FontWeight.w400,
                  color: current ? kText : kText2,
                  fontFeatures: kTabular,
                ),
              );
            }).toList(),
          ),
          if (onUseSeries != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onUseSeries,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 42),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: kAccentText,
                ),
                child: Text(
                  S.get('use_same_values'),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            )
          else
            const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ─── METRICHE ───────────────────────────────────────────────────────────────
/// Un numero con la sua etichetta in maiuscolo.
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
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: valueColor ?? kText,
                fontFeatures: kTabular,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: T.section.copyWith(fontSize: 11, letterSpacing: 1.1)),
        ],
      );
}

/// Piu' metriche affiancate in un blocco, separate da linee verticali.
class StatsBlock extends StatelessWidget {
  final List<Metric> metrics;
  const StatsBlock({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[];
    for (var i = 0; i < metrics.length; i++) {
      if (i > 0) cells.add(Container(width: 1, color: kLine));
      cells.add(Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
          child: metrics[i],
        ),
      ));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kGapPage),
      child: Material(
        color: blockColor,
        borderRadius: BorderRadius.circular(kRadius),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cells,
          ),
        ),
      ),
    );
  }
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
/// Una pastiglia selezionabile. Scelta: grigio un po' piu' chiaro con un
/// bordino, non un blocco bianco pieno che grida piu' del resto.
/// [color] colora il testo della pastiglia scelta (tipo serie speciale).
class Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? color;

  /// Fondo quando non e' scelta: kSurface2 negli sheet, kSurface sulla pagina.
  final Color? background;

  const Pill({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.color,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected
              ? (isDarkTheme ? kSurface3 : Colors.white)
              : (background ?? kSurface2),
          borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(
            color: selected ? kDashed : Colors.transparent,
            width: 1,
          ),
        ),
        // widthFactor 1: centrata in altezza senza allargarsi a tutta riga
        // dentro i Wrap (con alignment sul Container succedeva).
        child: Align(
          widthFactor: 1,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected
                  ? (color ?? kText)
                  : (onTap == null ? kText3 : kTextSoft),
              fontFeatures: kTabular,
            ),
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
            child:
                Text(S.get('remove_rest'), style: const TextStyle(color: kRed)),
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
              style: TextStyle(
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
      borderRadius: BorderRadius.circular(kRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 16, color: color),
            if (seconds != null) ...[
              const SizedBox(width: 5),
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
  Widget build(BuildContext context) => Pill(
        label: label,
        selected: selected,
        onTap: onTap,
        background: blockColor,
      );
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
      height: 36,
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
            const SizedBox(width: 8),
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

  const DayChip({super.key, this.dayName, this.onTap, this.fontSize = 14});

  @override
  Widget build(BuildContext context) {
    final named = dayName != null && dayName!.trim().isNotEmpty;
    final label = Text(
      named ? dayName!.trim() : S.get('free_workout'),
      style: TextStyle(
        fontSize: fontSize,
        color: named ? kTextSoft : kText2,
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
          Icon(Icons.expand_more, size: fontSize + 4, color: kText2),
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
      borderRadius: BorderRadius.circular(kRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$day · $dateLabel',
                      style: TextStyle(fontSize: 13, color: kText2)),
                  const SizedBox(height: 4),
                  Text(
                    summary,
                    style: TextStyle(
                      fontSize: 15,
                      letterSpacing: 0.2,
                      color: secondary ? kTextSoft : kText,
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
                      fontSize: 15,
                      color: kAccentText,
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 46),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(kBlockInset, 10, 12, 10),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: kTextFaint,
                    fontFeatures: kTabular,
                  ),
                ),
              ),
              Text(
                S.get('series_to_do'),
                style: TextStyle(fontSize: 16, color: kTextFaint),
              ),
            ],
          ),
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
            Text(S.get('target_series_desc'),
                style: T.meta.copyWith(height: 1.4)),
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

/// Colore della faccina: dal rosso (malissimo) al verde (benissimo). Si legge
/// l'umore di una sessione a colpo d'occhio, nello Storico e a fine
/// allenamento.
Color moodColor(int mood) => switch (mood.clamp(1, 5)) {
      1 => kRed,
      2 => kOrange,
      3 => const Color(0xFFFACC15),
      4 => const Color(0xFFA3E635),
      _ => kGreen,
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
          Icon(moodIcon(rating), color: moodColor(rating), size: fontSize + 7),
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
      builder: (_) => RatingDialog(initial: initial, confirmText: confirmText),
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
                color: moodColor(_selected),
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
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: moodColor(_selected),
                thumbColor: moodColor(_selected),
              ),
              child: Slider(
                min: 1,
                max: 5,
                divisions: 4,
                value: _selected.toDouble(),
                onChanged: (v) => _set(v.round()),
              ),
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
                      size: 22,
                      color: i == _selected ? moodColor(i) : kText3,
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
            Text(previous, style: T.meta.copyWith(fontStyle: FontStyle.italic)),
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
                      horizontal: kGapPage, vertical: 15),
                  child: Row(
                    children: [
                      Icon(a.icon,
                          size: 22, color: a.destructive ? kRed : kText2),
                      const SizedBox(width: 18),
                      Text(
                        a.label,
                        style: T.body
                            .copyWith(color: a.destructive ? kRed : kText),
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
