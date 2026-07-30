/// Contract for onboarding persistence. The presentation layer only
/// knows this interface; storage details live in data/.
abstract interface class OnboardingRepository {
  Future<bool> hasCompletedOnboarding();
  Future<void> markOnboardingComplete();
}
