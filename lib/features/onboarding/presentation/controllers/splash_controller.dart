import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_durations.dart';

/// Where the app should go after boot.
enum SplashDestination { pending, onboarding, lock, home }

/// Orchestrates app boot: minimum brand time + (later) session,
/// lock-state and wipe-flag checks — all off the UI thread.
class SplashController extends Notifier<SplashDestination> {
  @override
  SplashDestination build() => SplashDestination.pending;

  Future<void> boot() async {
    final Stopwatch sw = Stopwatch()..start();

    // Future: read secure storage session, key material presence,
    // emergency-wipe flag. Kept empty until those layers exist.

    final Duration remaining = AppDurations.splashMinimum - sw.elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }

    // No session layer yet → onboarding is the only destination.
    state = SplashDestination.onboarding;
  }
}

final splashControllerProvider =
    NotifierProvider<SplashController, SplashDestination>(
  SplashController.new,
);
