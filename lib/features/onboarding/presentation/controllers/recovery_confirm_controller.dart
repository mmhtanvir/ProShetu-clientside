import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/onboarding_providers.dart';

/// Submits the recovery form (after the destructive-recovery warning
/// has been shown and its confirmation checkbox checked). Mirrors
/// SignupController's shape — see that file — but calls
/// AuthRepository.startRecovery() instead of signUp().
class RecoveryConfirmController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> submit({
    required String phone,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).startRecovery(
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

final recoveryConfirmControllerProvider =
    AsyncNotifierProvider<RecoveryConfirmController, void>(
  RecoveryConfirmController.new,
);
