import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_durations.dart';
import '../providers/onboarding_providers.dart';

/// Where the app should go after boot.
enum SplashDestination { pending, onboarding, login, home }

/// Orchestrates app boot: minimum brand time + first-run check.
/// Session, lock-state and wipe-flag checks slot in here later.
class SplashController extends Notifier<SplashDestination> {
  @override
  SplashDestination build() => SplashDestination.pending;

  Future<void> boot() async {
    final Stopwatch sw = Stopwatch()..start();

    final bool completed = await ref
        .read(onboardingRepositoryProvider)
        .hasCompletedOnboarding();
    final bool signedIn =
        await ref.read(authRepositoryProvider).hasSession();

    final Duration remaining = AppDurations.splashMinimum - sw.elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }

    state = signedIn
        ? SplashDestination.home
        : completed
            ? SplashDestination.login
            : SplashDestination.onboarding;
  }
}

final splashControllerProvider =
    NotifierProvider<SplashController, SplashDestination>(
  SplashController.new,
);
