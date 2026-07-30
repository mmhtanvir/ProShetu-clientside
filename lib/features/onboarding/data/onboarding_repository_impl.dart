import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/onboarding_repository.dart';

/// Secure-storage backed implementation.
///
/// Uses the existing secure store rather than adding a preferences
/// package for one flag. Read failures fail *open* (returns `false`)
/// so a storage error can never lock a user out of the app — they
/// just see onboarding again.
final class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl(this._storage);

  final FlutterSecureStorage _storage;

  static const String _key = 'onboarding_complete_v1';

  @override
  Future<bool> hasCompletedOnboarding() async {
    try {
      return await _storage.read(key: _key) == 'true';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> markOnboardingComplete() async {
    try {
      await _storage.write(key: _key, value: 'true');
    } catch (_) {
      // Non-fatal: worst case the user sees onboarding once more.
    }
  }
}
