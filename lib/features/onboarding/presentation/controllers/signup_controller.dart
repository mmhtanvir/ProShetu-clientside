import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/onboarding_providers.dart';

/// Submits the signup form. Returns success so the screen can route.
class SignupController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> submit({
    required String displayName,
    required String phone,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signUp(
            displayName: displayName,
            phone: phone,
            password: password,
          );
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final signupControllerProvider =
    AsyncNotifierProvider<SignupController, void>(
  SignupController.new,
);
