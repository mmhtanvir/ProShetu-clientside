import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/onboarding_providers.dart';

/// Post-login destination, decided by security setup state.
enum PostLoginDestination { setPin, home }

class LoginController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<PostLoginDestination?> submit({
    required String phone,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.login(phone: phone, password: password);
      await repo.saveSession(); // Stay signed in across launches.
      final bool done = await repo.hasCompletedSecuritySetup();
      state = const AsyncData(null);
      return done ? PostLoginDestination.home : PostLoginDestination.setPin;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}

final loginControllerProvider =
    AsyncNotifierProvider<LoginController, void>(
  LoginController.new,
);
