import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Elevation tokens. Kept subtle: heavy shadows cost GPU on low-end
/// devices and read poorly on near-black surfaces.
abstract final class AppShadows {
  static const List<BoxShadow> none = [];

  static const List<BoxShadow> low = [
    BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> medium = [
    BoxShadow(color: Color(0x4D000000), blurRadius: 16, offset: Offset(0, 6)),
  ];

  /// Soft brand glow, used sparingly (e.g. splash logo, panic button).
  static const List<BoxShadow> brandGlow = [
    BoxShadow(color: Color(0x407B7FF2), blurRadius: 32, spreadRadius: 2),
  ];

  /// Convenience: glow derived from [AppColors.danger] for panic surfaces.
  static const List<BoxShadow> dangerGlow = [
    BoxShadow(color: Color(0x40EF4B55), blurRadius: 32, spreadRadius: 2),
  ];
}
