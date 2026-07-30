import 'package:flutter/widgets.dart';

/// Breakpoint helpers. Content-width clamping keeps phone layouts
/// readable on tablets and in landscape without per-screen work.
abstract final class Breakpoints {
  static const double tablet = 600;
  static const double desktop = 1024;

  /// Max width for single-column reading/forms content.
  static const double contentMaxWidth = 560;
}

extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);
  bool get isTablet => screenSize.shortestSide >= Breakpoints.tablet;
  bool get isLandscape =>
      MediaQuery.orientationOf(this) == Orientation.landscape;

  /// Honor the OS "reduce motion" accessibility setting.
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);
}
