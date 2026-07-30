import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/onboarding_providers.dart';

/// Handles onboarding completion (Skip or Confirm both land here).
class OnboardingController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> complete() async {
    state = const AsyncLoading();
    await ref.read(onboardingRepositoryProvider).markOnboardingComplete();
    state = const AsyncData(null);
  }
}

final onboardingControllerProvider =
    AsyncNotifierProvider<OnboardingController, void>(OnboardingController.new);
