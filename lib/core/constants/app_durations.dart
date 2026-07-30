/// Motion tokens. Short and purposeful — animation costs battery.
abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  /// Minimum time the splash brand is visible before routing on.
  static const Duration splashMinimum = Duration(milliseconds: 1200);
}
