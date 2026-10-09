// lib/widgets/app_tour.dart
//
// Tour interattivo: overlay scuro con "buco" (spotlight) sull'elemento
// da spiegare, fumetto con testo e pulsanti Avanti / Salta.
// Nessuna dipendenza esterna.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final GlobalKey targetKey;
  final String title;
  final String text;

  const TourStep({
    required this.targetKey,
    required this.title,
    required this.text,
  });
}

/// Passi standard del tour (le stringhe leggono la lingua corrente).
List<TourStep> defaultTourSteps() => [
      TourStep(
        targetKey: TourKeys.addExerciseFab,
        title: S.get('tour_add_title'),
        text: S.get('tour_add_text'),
      ),
      TourStep(
        targetKey: TourKeys.templatesRow,
        title: S.get('tour_templates_title'),
        text: S.get('tour_templates_text'),
      ),
      TourStep(
        targetKey: TourKeys.newDayButton,
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
    // Tieni solo i passi il cui target è effettivamente montato.
    final valid =
        resolved.where((s) => s.targetKey.currentContext != null).toList();
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
    final ctx = key.currentContext;
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

    if (rect == null) {
      // target sparito: passa oltre
      WidgetsBinding.instance.addPostFrameCallback((_) => _next());
      return const SizedBox.shrink();
    }

    // Fumetto sopra o sotto il target, dov'e piu spazio.
    final showBelow = rect.center.dy < screen.height / 2;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // sfondo scuro con buco
          Positioned.fill(
            child: GestureDetector(
              onTap: _next,
              child: CustomPaint(
                painter: _SpotlightPainter(hole: rect),
              ),
            ),
          ),
          // fumetto
          Positioned(
            left: 24,
            right: 24,
            top: showBelow ? rect.bottom + 16 : null,
            bottom: showBelow ? null : screen.height - rect.top + 16,
            child: _bubble(step, isLast),
          ),
        ],
      ),
    );
  }

  Widget _bubble(TourStep step, bool isLast) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kAccent.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kAccent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_index + 1}/${widget.steps.length}',
                  style: TextStyle(
                      fontSize: 11,
                      color: kAccent,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  step.title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kText,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            step.text,
            style: TextStyle(fontSize: 13.5, color: kText2, height: 1.45),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              TextButton(
                onPressed: widget.onFinish,
                child: Text(S.get('skip'),
                    style: TextStyle(color: kText3, fontSize: 13)),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _next,
                style: FilledButton.styleFrom(
                  backgroundColor: kAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isLast ? S.get('tour_done') : S.get('next'),
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w600),
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
  final Rect hole;

  _SpotlightPainter({required this.hole});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Path()..addRect(Offset.zero & size);
    final cut = Path()
      ..addRRect(RRect.fromRectAndRadius(hole, const Radius.circular(16)));
    final path = Path.combine(PathOperation.difference, bg, cut);

    canvas.drawPath(
      path,
      Paint()..color = Colors.black.withValues(alpha: 0.72),
    );

    // bordo luminoso attorno al buco
    canvas.drawRRect(
      RRect.fromRectAndRadius(hole, const Radius.circular(16)),
      Paint()
        ..color = kAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.hole != hole;
}
