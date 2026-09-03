import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/utils/responsive.dart';

/// Visual variants matching the onboarding designs.
enum AmbientFieldVariant { goldWave, tealFlow, duskSwirl }

/// Decorative particle-field backdrop, generated procedurally.
///
/// Why a painter instead of bundled images: zero asset bytes, zero
/// decode memory, resolution-independent, and it repaints inside its
/// own [RepaintBoundary] so the drift below never invalidates the
/// rest of the onboarding page.
///
/// Drifts slowly and continuously (a phase offset feeds the same
/// sine displacement the static version used) — requested explicitly
/// ("those dots & designs should move"). Kept cheap: one slow-period
/// [AnimationController] per page, long duration so it reads as an
/// ambient current rather than a busy redraw, and skipped entirely
/// under the OS "reduce motion" setting, same convention as
/// FadeSlideIn/SplashScreen/AppBottomNav's SOS pulse.
class AmbientFieldArt extends StatefulWidget {
  const AmbientFieldArt({required this.variant, super.key});

  final AmbientFieldVariant variant;

  @override
  State<AmbientFieldArt> createState() => _AmbientFieldArtState();
}

class _AmbientFieldArtState extends State<AmbientFieldArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 26),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!context.reduceMotion && !_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            return CustomPaint(
              painter: _AmbientFieldPainter(
                widget.variant,
                phase: _controller.value * math.pi * 2,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class _AmbientFieldPainter extends CustomPainter {
  const _AmbientFieldPainter(this.variant, {required this.phase});

  final AmbientFieldVariant variant;

  /// 0 → 2π, looping. Fed into the wave/flow math below as a slow
  /// drift offset so the field never has a visible seam or reset.
  final double phase;

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

        // Layered sine displacement → organic wave sheets, drifting
        // with `phase` so the sheets slowly roll rather than sit still.
        final double wave =
            math.sin(r * 0.18 + c * 0.10 + phase) * cw * 2.2 +
                math.sin(r * 0.05 - c * 0.22 - phase * 0.6) * cw * 1.4;
        final Offset p = Offset(
          baseX + wave,
          baseY + math.sin(c * 0.3 + phase * 0.4) * ch,
        );

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

    // Gentle horizontal breathing so the whole sheaf of lines sways,
    // rather than each line independently — reads as one current.
    final double sway = math.sin(phase) * size.width * 0.02;

    for (int i = 0; i < lines; i++) {
      final double t = i / (lines - 1);
      final double x = size.width * (0.30 + t * 0.42) + sway;

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
      oldDelegate.variant != variant || oldDelegate.phase != phase;
}
