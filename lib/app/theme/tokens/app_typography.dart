import 'package:flutter/material.dart';

/// Type scale for ProShetu.
///
/// Manrope: geometric, high x-height, excellent legibility at small sizes
/// and under stress — and it renders Latin + Bengali fallback cleanly.
/// Bundled as a variable-weight asset (assets/fonts/Manrope-Variable.ttf,
/// declared in pubspec.yaml) rather than fetched via google_fonts: this is
/// a crisis app and must render its first frame with zero network calls.
/// Colors are applied by the theme, not here.
abstract final class AppTypography {
  static const String _family = 'Manrope';

  static TextTheme textTheme(TextTheme base) {
    final TextTheme manrope = base.apply(fontFamily: _family);
    return manrope.copyWith(
      displaySmall: manrope.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      headlineMedium: manrope.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      headlineSmall:
          manrope.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: manrope.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: manrope.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: manrope.bodyLarge?.copyWith(height: 1.45),
      bodyMedium: manrope.bodyMedium?.copyWith(height: 1.45),
      labelLarge: manrope.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      labelSmall: manrope.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 2.4,
      ),
    );
  }
}
