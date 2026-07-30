import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Visual variants matching the onboarding designs.
enum AmbientFieldVariant { goldWave, tealFlow, duskSwirl }

/// Decorative particle-field backdrop, generated procedurally.
///
/// Why a painter instead of bundled images: zero asset bytes, zero
/// decode memory, resolution-independent, and it repaints exactly
/// once ([shouldRepaint] is false, host wraps in [RepaintBoundary]).
/// Deliberately static — animating thousands of points would cost
/// battery and GPU on the low-end devices we target.
class AmbientFieldArt extends StatelessWidget {
  const AmbientFieldArt({required this.variant, super.key});

  final AmbientFieldVariant variant;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _AmbientFieldPainter(variant),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _AmbientFieldPainter extends CustomPainter {
  const _AmbientFieldPainter(this.variant);

  final AmbientFieldVariant variant;

  @override
  void paint(Canvas canvas, Size size) {
    switch (variant) {
      case AmbientFieldVariant.goldWave:
        _paintDotField(
          canvas,
          size,
          seed: 7,
          colors: const [Color(0xFFC9A362), Color(0xFF8A7147)],
          centerX: 0.30,
          centerY: 0.42,
        );
      case AmbientFieldVariant.tealFlow:
        _paintLineFlow(canvas, size);
      case AmbientFieldVariant.duskSwirl:
        _paintDotField(
          canvas,
          size,
          seed: 23,
          colors: const [Color(0xFFCD9668), Color(0xFF8B9BC0)],
          centerX: 0.72,
          centerY: 0.40,
        );
    }
  }

  /// Grid of dots displaced by layered sine waves, faded radially so
  /// the field dissolves into the background.
  void _paintDotField(
    Canvas canvas,
    Size size, {
    required int seed,
    required List<Color> colors,
    required double centerX,
    required double centerY,
  }) {
    final math.Random rng = math.Random(seed);
    final Paint paint = Paint()..style = PaintingStyle.fill;

    const int cols = 46;
    const int rows = 60;
    final double cw = size.width / cols;
    final double ch = (size.height * 0.85) / rows;
    final Offset focus = Offset(size.width * centerX, size.height * centerY);
    final double maxDist = size.shortestSide * 0.62;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final double baseX = c * cw;
        final double baseY = r * ch;

        // Layered sine displacement → organic wave sheets.
        final double wave = math.sin(r * 0.18 + c * 0.10) * cw * 2.2 +
            math.sin(r * 0.05 - c * 0.22) * cw * 1.4;
        final Offset p = Offset(baseX + wave, baseY + math.sin(c * 0.3) * ch);

        final double dist = (p - focus).distance;
        if (dist > maxDist) continue;

        final double fade = 1 - (dist / maxDist);
        final double jitter = rng.nextDouble();
        final Color color = Color.lerp(colors[0], colors[1], jitter)!;

        paint.color = color.withValues(alpha: (fade * fade) * 0.85);
        canvas.drawCircle(p, 0.8 + fade * 1.1, paint);
      }
    }
  }

  /// Sweeping S-curve of thin strokes — the "encryption" flow lines.
  void _paintLineFlow(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    const int lines = 52;
    const Color a = Color(0xFF5FD3C8);
    const Color b = Color(0xFF1E4E55);

    for (int i = 0; i < lines; i++) {
      final double t = i / (lines - 1);
      final double x = size.width * (0.30 + t * 0.42);

      paint.color =
          Color.lerp(a, b, t)!.withValues(alpha: 0.55 * (1 - (t - 0.5).abs()));

      final Path path = Path()
        ..moveTo(x + size.width * 0.18, size.height * 0.08)
        ..cubicTo(
          x - size.width * 0.42,
          size.height * (0.30 + t * 0.05),
          x + size.width * 0.34,
          size.height * (0.52 + t * 0.04),
          x - size.width * 0.16,
          size.height * 0.80,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientFieldPainter oldDelegate) =>
      oldDelegate.variant != variant;
}
