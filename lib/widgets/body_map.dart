// lib/widgets/body_map.dart

import 'package:flutter/material.dart';
import '../models/muscle_groups.dart';
import '../theme.dart';

/// Colore di un livello di stimolo: l'accento a tre intensita'. Un solo
/// colore che si scurisce/schiarisce si legge piu' in fretta del semaforo
/// verde/giallo/rosso, e non suggerisce che "rosso" sia un errore.
Color stimulationColor(StimulationLevel level) {
  switch (level) {
    case StimulationLevel.none:
      return kSurface3;
    case StimulationLevel.low:
      return kAccent.withValues(alpha: 0.35);
    case StimulationLevel.medium:
      return kAccent.withValues(alpha: 0.65);
    case StimulationLevel.high:
      return kAccent;
  }
}

/// A single body view (front or back) with colored muscle regions.
class BodyMapView extends StatelessWidget {
  final bool isFront;
  final Map<String, double> stimulationData; // muscleId -> effective sets
  final String? label;

  const BodyMapView({
    super.key,
    required this.isFront,
    required this.stimulationData,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label!,
              style: TextStyle(fontSize: 12, color: kText3, fontWeight: FontWeight.w500),
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _BodyMapPainter(
                  isFront: isFront,
                  stimulationData: stimulationData,
                  outlineColor: kSurface3,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Compact body map for exercise picker (shows only targeted muscles).
class MiniBodyMap extends StatelessWidget {
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final double size;

  const MiniBodyMap({
    super.key,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    // Build stimulation data: primary = high color, secondary = medium color
    final data = <String, double>{};
    for (final m in primaryMuscles) {
      data[m] = 15; // high
    }
    for (final m in secondaryMuscles) {
      if (!data.containsKey(m)) data[m] = 8; // medium
    }

    // Determine if we need front, back, or both
    final needsFront = data.keys.any((id) {
      final m = getMuscleGroup(id);
      return m != null && m.visibleFront;
    });
    final needsBack = data.keys.any((id) {
      final m = getMuscleGroup(id);
      return m != null && m.visibleBack;
    });

    if (needsFront && needsBack) {
      return SizedBox(
        width: size * 1.6,
        height: size,
        child: Row(
          children: [
            Expanded(
              child: CustomPaint(
                painter: _BodyMapPainter(isFront: true, stimulationData: data, outlineColor: kSurface3),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: CustomPaint(
                painter: _BodyMapPainter(isFront: false, stimulationData: data, outlineColor: kSurface3),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: size * 0.7,
      height: size,
      child: CustomPaint(
        painter: _BodyMapPainter(
          isFront: needsFront || !needsBack,
          stimulationData: data,
          outlineColor: kSurface3,
        ),
      ),
    );
  }
}

// ─── PAINTER ─────────────────────────────────────────────────────────────────

class _BodyMapPainter extends CustomPainter {
  final bool isFront;
  final Map<String, double> stimulationData;
  final Color outlineColor;

  _BodyMapPainter({
    required this.isFront,
    required this.stimulationData,
    required this.outlineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // We work in a 100x210 virtual space, then scale to fit
    const vw = 100.0;
    const vh = 210.0;

    final scaleX = size.width / vw;
    final scaleY = size.height / vh;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final offsetX = (size.width - vw * scale) / 2;
    final offsetY = (size.height - vh * scale) / 2;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);

    // Draw body silhouette
    _drawSilhouette(canvas);

    // Draw muscle regions
    if (isFront) {
      _drawFrontMuscles(canvas);
    } else {
      _drawBackMuscles(canvas);
    }

    canvas.restore();
  }

  void _drawSilhouette(Canvas canvas) {
    // La sagoma era quasi invisibile sul fondo scuro: senza corpo di
    // riferimento le zone colorate "galleggiavano" nel vuoto.
    final paint = Paint()
      ..color = outlineColor.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    // Head
    canvas.drawOval(Rect.fromCenter(center: const Offset(50, 18), width: 28, height: 32), paint);

    // Neck
    canvas.drawRect(const Rect.fromLTWH(43, 33, 14, 10), paint);

    // Torso
    final torso = Path()
      ..moveTo(25, 43)
      ..lineTo(75, 43)
      ..lineTo(78, 50)
      ..lineTo(76, 70)
      ..lineTo(72, 108)
      ..lineTo(68, 118)
      ..lineTo(32, 118)
      ..lineTo(28, 108)
      ..lineTo(24, 70)
      ..lineTo(22, 50)
      ..close();
    canvas.drawPath(torso, paint);

    // Left arm
    final leftArm = Path()
      ..moveTo(22, 46)
      ..lineTo(14, 50)
      ..lineTo(8, 70)
      ..lineTo(4, 90)
      ..lineTo(2, 112)
      ..lineTo(8, 114)
      ..lineTo(12, 92)
      ..lineTo(16, 72)
      ..lineTo(22, 56)
      ..close();
    canvas.drawPath(leftArm, paint);

    // Right arm
    final rightArm = Path()
      ..moveTo(78, 46)
      ..lineTo(86, 50)
      ..lineTo(92, 70)
      ..lineTo(96, 90)
      ..lineTo(98, 112)
      ..lineTo(92, 114)
      ..lineTo(88, 92)
      ..lineTo(84, 72)
      ..lineTo(78, 56)
      ..close();
    canvas.drawPath(rightArm, paint);

    // Left leg
    final leftLeg = Path()
      ..moveTo(32, 118)
      ..lineTo(28, 140)
      ..lineTo(26, 165)
      ..lineTo(25, 190)
      ..lineTo(23, 205)
      ..lineTo(35, 205)
      ..lineTo(36, 190)
      ..lineTo(38, 165)
      ..lineTo(42, 140)
      ..lineTo(46, 118)
      ..close();
    canvas.drawPath(leftLeg, paint);

    // Right leg
    final rightLeg = Path()
      ..moveTo(54, 118)
      ..lineTo(58, 140)
      ..lineTo(62, 165)
      ..lineTo(64, 190)
      ..lineTo(65, 205)
      ..lineTo(77, 205)
      ..lineTo(75, 190)
      ..lineTo(74, 165)
      ..lineTo(72, 140)
      ..lineTo(68, 118)
      ..close();
    canvas.drawPath(rightLeg, paint);
  }

  Paint _musclePaint(String muscleId) {
    final sets = stimulationData[muscleId] ?? 0;
    final level = stimulationFromSets(sets);
    final color = stimulationColor(level);
    return Paint()
      ..color = level == StimulationLevel.none
          ? color.withValues(alpha: 0.55)
          : color
      ..style = PaintingStyle.fill;
  }

  void _drawFrontMuscles(Canvas canvas) {
    // Shoulders (delts)
    _drawOval(canvas, 'shoulders', const Rect.fromLTWH(18, 42, 16, 14));
    _drawOval(canvas, 'shoulders', const Rect.fromLTWH(66, 42, 16, 14));

    // Chest
    final chestL = Path()
      ..moveTo(34, 46)
      ..quadraticBezierTo(34, 58, 38, 68)
      ..lineTo(49, 68)
      ..lineTo(49, 46)
      ..close();
    final chestR = Path()
      ..moveTo(66, 46)
      ..quadraticBezierTo(66, 58, 62, 68)
      ..lineTo(51, 68)
      ..lineTo(51, 46)
      ..close();
    canvas.drawPath(chestL, _musclePaint('chest'));
    canvas.drawPath(chestR, _musclePaint('chest'));

    // Biceps
    _drawRRect(canvas, 'biceps', const Rect.fromLTWH(10, 56, 12, 24), 5);
    _drawRRect(canvas, 'biceps', const Rect.fromLTWH(78, 56, 12, 24), 5);

    // Forearms
    _drawRRect(canvas, 'forearms', const Rect.fromLTWH(5, 82, 11, 26), 4);
    _drawRRect(canvas, 'forearms', const Rect.fromLTWH(84, 82, 11, 26), 4);

    // Abs
    _drawRRect(canvas, 'abs', const Rect.fromLTWH(36, 70, 28, 38), 6);

    // Quads
    _drawRRect(canvas, 'quads', const Rect.fromLTWH(28, 120, 18, 40), 6);
    _drawRRect(canvas, 'quads', const Rect.fromLTWH(54, 120, 18, 40), 6);

    // Calves (front)
    _drawRRect(canvas, 'calves', const Rect.fromLTWH(26, 166, 12, 30), 5);
    _drawRRect(canvas, 'calves', const Rect.fromLTWH(62, 166, 12, 30), 5);
  }

  void _drawBackMuscles(Canvas canvas) {
    // Shoulders (rear delts)
    _drawOval(canvas, 'shoulders', const Rect.fromLTWH(18, 42, 16, 14));
    _drawOval(canvas, 'shoulders', const Rect.fromLTWH(66, 42, 16, 14));

    // Upper back (traps/rhomboids)
    _drawRRect(canvas, 'upper_back', const Rect.fromLTWH(32, 43, 36, 20), 6);

    // Lats
    final latL = Path()
      ..moveTo(28, 58)
      ..quadraticBezierTo(26, 80, 32, 100)
      ..lineTo(48, 100)
      ..lineTo(48, 64)
      ..lineTo(34, 58)
      ..close();
    final latR = Path()
      ..moveTo(72, 58)
      ..quadraticBezierTo(74, 80, 68, 100)
      ..lineTo(52, 100)
      ..lineTo(52, 64)
      ..lineTo(66, 58)
      ..close();
    canvas.drawPath(latL, _musclePaint('lats'));
    canvas.drawPath(latR, _musclePaint('lats'));

    // Triceps
    _drawRRect(canvas, 'triceps', const Rect.fromLTWH(10, 56, 12, 24), 5);
    _drawRRect(canvas, 'triceps', const Rect.fromLTWH(78, 56, 12, 24), 5);

    // Forearms (back)
    _drawRRect(canvas, 'forearms', const Rect.fromLTWH(5, 82, 11, 26), 4);
    _drawRRect(canvas, 'forearms', const Rect.fromLTWH(84, 82, 11, 26), 4);

    // Glutes
    _drawOval(canvas, 'glutes', const Rect.fromLTWH(30, 106, 18, 16));
    _drawOval(canvas, 'glutes', const Rect.fromLTWH(52, 106, 18, 16));

    // Hamstrings
    _drawRRect(canvas, 'hamstrings', const Rect.fromLTWH(28, 124, 18, 38), 6);
    _drawRRect(canvas, 'hamstrings', const Rect.fromLTWH(54, 124, 18, 38), 6);

    // Calves (back)
    _drawRRect(canvas, 'calves', const Rect.fromLTWH(26, 166, 12, 30), 5);
    _drawRRect(canvas, 'calves', const Rect.fromLTWH(62, 166, 12, 30), 5);
  }

  void _drawOval(Canvas canvas, String muscleId, Rect rect) {
    canvas.drawOval(rect, _musclePaint(muscleId));
  }

  void _drawRRect(Canvas canvas, String muscleId, Rect rect, double radius) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      _musclePaint(muscleId),
    );
  }

  @override
  bool shouldRepaint(covariant _BodyMapPainter oldDelegate) {
    return oldDelegate.isFront != isFront ||
        oldDelegate.stimulationData != stimulationData;
  }
}
