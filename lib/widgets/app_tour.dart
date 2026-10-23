// lib/widgets/app_tour.dart
//
// Tour interattivo: overlay scuro con "buco" (spotlight) sull'elemento
// da spiegare, fumetto con testo e pulsanti Avanti / Salta.
// Un passo puo' non avere un elemento da indicare (o non trovarlo, come
// "Finisci" al primo avvio, quando non c'e' ancora un allenamento): allora il
// fumetto sta al centro e lo sfondo e' scuro tutto.
// Nessuna dipendenza esterna.

import 'package:flutter/material.dart';
import '../theme.dart';
import '../l10n/strings.dart';

/// GlobalKey dei punti dell'app toccati dal tour.
class TourKeys {
  static final newDayButton = GlobalKey();
  static final templatesRow = GlobalKey();
  static final addExerciseFab = GlobalKey();
  static final bottomNav = GlobalKey();
}

class TourStep {
  /// Elemento da indicare; null = passo solo testo, al centro.
  final GlobalKey? targetKey;
  final String title;
  final String text;

  /// true: se l'elemento non c'e' (non montato) il passo si mostra al centro
  /// invece di essere saltato.
  final bool centerIfMissing;

  const TourStep({
    this.targetKey,
    required this.title,
    required this.text,
    this.centerIfMissing = false,
  });

  bool get isAvailable =>
      targetKey == null || centerIfMissing || targetKey!.currentContext != null;
}

/// Passi standard del tour, nell'ordine in cui si usa l'app: come si inizia
/// (giorno preimpostato o libero), come si registra, come si chiude, dove
/// sta il resto. Le stringhe leggono la lingua corrente.
List<TourStep> defaultTourSteps() => [
      TourStep(
        targetKey: TourKeys.templatesRow,
        title: S.get('tour_templates_title'),
        text: S.get('tour_templates_text'),
      ),
      TourStep(
        targetKey: TourKeys.addExerciseFab,
        title: S.get('tour_add_title'),
        text: S.get('tour_add_text'),
      ),
      TourStep(
        title: S.get('tour_series_title'),
        text: S.get('tour_series_text'),
      ),
      TourStep(
        targetKey: TourKeys.newDayButton,
        centerIfMissing: true,
        title: S.get('tour_newday_title'),
        text: S.get('tour_newday_text'),
      ),
      TourStep(
        targetKey: TourKeys.bottomNav,
        title: S.get('tour_nav_title'),
        text: S.get('tour_nav_text'),
      ),
    ];

class AppTour {
  static OverlayEntry? _entry;

  static bool get isActive => _entry != null;

  static void start(
    BuildContext context, {
    List<TourStep>? steps,
    VoidCallback? onDone,
  }) {
    if (_entry != null) return;
    final resolved = steps ?? defaultTourSteps();
    // Tieni solo i passi che si possono mostrare adesso.
    final valid = resolved.where((s) => s.isAvailable).toList();
    if (valid.isEmpty) {
      onDone?.call();
      return;
    }

    final overlay = Overlay.of(context, rootOverlay: true);
    _entry = OverlayEntry(
      builder: (_) => _TourOverlay(
        steps: valid,
        onFinish: () {
          _entry?.remove();
          _entry = null;
          onDone?.call();
        },
      ),
    );
    overlay.insert(_entry!);
  }
}

class _TourOverlay extends StatefulWidget {
  final List<TourStep> steps;
  final VoidCallback onFinish;

  const _TourOverlay({required this.steps, required this.onFinish});

  @override
  State<_TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<_TourOverlay> {
  int _index = 0;

  Rect? _targetRect() {
    final key = widget.steps[_index].targetKey;
    final ctx = key?.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return null;
    final pos = box.localToGlobal(Offset.zero);
    return (pos & box.size).inflate(6);
  }

  void _next() {
    if (_index < widget.steps.length - 1) {
      setState(() => _index++);
    } else {
      widget.onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rect = _targetRect();
    final step = widget.steps[_index];
    final screen = MediaQuery.of(context).size;
    final isLast = _index == widget.steps.length - 1;

    final centered =
        step.targetKey == null || (rect == null && step.centerIfMissing);
    if (rect == null && !centered) {
      // target sparito: passa oltre
      WidgetsBinding.instance.addPostFrameCallback((_) => _next());
      return const SizedBox.shrink();
    }

    // Fumetto sopra o sotto il target, dov'e' piu' spazio.
    final showBelow = rect != null && rect.center.dy < screen.height / 2;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // sfondo scuro con buco
          Positioned.fill(
            child: GestureDetector(
              onTap: _next,
              child: CustomPaint(
                painter: _SpotlightPainter(hole: centered ? null : rect),
              ),
            ),
          ),
          // fumetto
          if (centered)
            Positioned.fill(
              left: 24,
              right: 24,
              child: Center(child: _bubble(step, isLast)),
            )
          else
            Positioned(
              left: 24,
              right: 24,
              top: showBelow ? rect.bottom + 16 : null,
              bottom: showBelow ? null : screen.height - rect!.top + 16,
              child: _bubble(step, isLast),
            ),
        ],
      ),
    );
  }

  Widget _bubble(TourStep step, bool isLast) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 10, 8),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_index + 1} / ${widget.steps.length}',
            style: T.section,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              step.title,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: kText,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              step.text,
              style: TextStyle(fontSize: 15, color: kTextSoft, height: 1.45),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (!isLast)
                TextButton(
                  onPressed: widget.onFinish,
                  child: Text(S.get('skip'),
                      style: TextStyle(color: kText3, fontSize: 14)),
                ),
              const Spacer(),
              TextButton(
                onPressed: _next,
                style: TextButton.styleFrom(foregroundColor: kAccentText),
                child: Text(
                  isLast ? S.get('tour_done') : S.get('next'),
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  /// null = nessun buco: tutto scuro (passo al centro).
  final Rect? hole;

  _SpotlightPainter({required this.hole});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Path()..addRect(Offset.zero & size);
    final path = hole == null
        ? bg
        : Path.combine(
            PathOperation.difference,
            bg,
            Path()
              ..addRRect(RRect.fromRectAndRadius(
                  hole!, const Radius.circular(kRadius + 4))),
          );

    canvas.drawPath(
      path,
      Paint()..color = Colors.black.withValues(alpha: 0.74),
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.hole != hole;
}
