import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/onboarding_providers.dart';

/// Persists the encryption PIN and trusted contacts during first-run
/// security setup. Screens own the transient input state; this
/// controller owns the writes.
class SecuritySetupController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> savePin(String pin) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).savePin(pin);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> saveTrustedContacts(List<String> contacts) async {
    final List<String> cleaned = contacts
        .map((String c) => c.trim())
        .where((String c) => c.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) return false;

    state = const AsyncLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.saveTrustedContacts(cleaned);
      // Setup complete = signed in; no login step after signup.
      await repo.saveSession();
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final securitySetupControllerProvider =
    AsyncNotifierProvider<SecuritySetupController, void>(
  SecuritySetupController.new,
);
