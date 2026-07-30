import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// The ProShetu shield + bolt brand mark.
///
/// Painted with a lightweight CustomPainter instead of an SVG asset:
/// zero asset decode cost, crisp at any size, and it tints correctly
/// from the shared brand gradient tokens.
class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 64, this.withGlow = false, super.key});

  final double size;
  final bool withGlow;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        decoration: withGlow
            ? const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: AppShadows.brandGlow,
              )
            : null,
        child: CustomPaint(
          size: Size.square(size),
          painter: const _ShieldBoltPainter(),
        ),
      ),
    );
  }
}

class _ShieldBoltPainter extends CustomPainter {
  const _ShieldBoltPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Shield body.
    final Path shield = Path()
      ..moveTo(w * 0.5, h * 0.04)
      ..lineTo(w * 0.92, h * 0.20)
      ..lineTo(w * 0.92, h * 0.52)
      ..cubicTo(w * 0.92, h * 0.76, w * 0.72, h * 0.90, w * 0.5, h * 0.98)
      ..cubicTo(w * 0.28, h * 0.90, w * 0.08, h * 0.76, w * 0.08, h * 0.52)
      ..lineTo(w * 0.08, h * 0.20)
      ..close();

    final Paint shieldPaint = Paint()
      ..shader = AppColors.brandGradient
          .createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(shield, shieldPaint);

    // Lightning bolt cutout.
    final Path bolt = Path()
      ..moveTo(w * 0.56, h * 0.18)
      ..lineTo(w * 0.30, h * 0.55)
      ..lineTo(w * 0.47, h * 0.55)
      ..lineTo(w * 0.42, h * 0.82)
      ..lineTo(w * 0.70, h * 0.44)
      ..lineTo(w * 0.52, h * 0.44)
      ..close();

    final Paint boltPaint = Paint()..color = AppColors.backgroundDark;
    canvas.drawPath(bolt, boltPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
