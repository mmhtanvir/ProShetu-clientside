import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/app_status_view.dart';
import '../features/onboarding/presentation/screens/identity_capture_screen.dart';
import '../features/onboarding/presentation/screens/identity_choice_screen.dart';
import '../features/onboarding/presentation/screens/identity_success_screen.dart';
import '../features/onboarding/presentation/screens/login_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/onboarding/presentation/screens/set_pin_screen.dart';
import '../features/onboarding/presentation/screens/signup_screen.dart';
import '../features/onboarding/presentation/screens/splash_screen.dart';
import '../features/onboarding/presentation/screens/trusted_contacts_screen.dart';
import '../features/onboarding/presentation/screens/verify_phone_screen.dart';
import '../l10n/app_localizations.dart';

/// Route names & paths in one place. Screens navigate by name, never
/// by raw string, so paths can evolve safely.
abstract final class AppRoutes {
  static const String splash = 'splash';
  static const String splashPath = '/';

  static const String onboarding = 'onboarding';
  static const String onboardingPath = '/onboarding';

  static const String signup = 'signup';
  static const String signupPath = '/signup';
  static const String verifyPhone = 'verify-phone';
  static const String verifyPhonePath = '/signup/verify-phone';
  static const String identityChoice = 'identity-choice';
  static const String identityChoicePath = '/signup/identity';
  static const String identityCapture = 'identity-capture';
  static const String identityCapturePath = '/signup/identity/capture';
  static const String identitySuccess = 'identity-success';
  static const String identitySuccessPath = '/signup/identity/success';

  static const String login = 'login';
  static const String loginPath = '/login';
  static const String setPin = 'set-pin';
  static const String setPinPath = '/setup/pin';
  static const String trustedContacts = 'trusted-contacts';
  static const String trustedContactsPath = '/setup/trusted-contacts';

  static const String home = 'home';
  static const String homePath = '/home';

  // Reserved for upcoming flows.
  static const String lock = 'lock';
  static const String lockPath = '/lock';
}

/// Router provider. Riverpod-owned so redirects can later read auth,
/// lock and wipe state reactively.
final routerProvider = Provider<GoRouter>((Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.splashPath,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoutes.splashPath,
        name: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingPath,
        name: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.signupPath,
        name: AppRoutes.signup,
        builder: (_, __) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyPhonePath,
        name: AppRoutes.verifyPhone,
        builder: (BuildContext context, GoRouterState state) =>
            VerifyPhoneScreen(phone: state.extra as String? ?? ''),
      ),
      GoRoute(
        path: AppRoutes.identityChoicePath,
        name: AppRoutes.identityChoice,
        builder: (_, __) => const IdentityChoiceScreen(),
      ),
      GoRoute(
        path: AppRoutes.identityCapturePath,
        name: AppRoutes.identityCapture,
        builder: (_, __) => const IdentityCaptureScreen(),
      ),
      GoRoute(
        path: AppRoutes.identitySuccessPath,
        name: AppRoutes.identitySuccess,
        builder: (_, __) => const IdentitySuccessScreen(),
      ),
      GoRoute(
        path: AppRoutes.loginPath,
        name: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.setPinPath,
        name: AppRoutes.setPin,
        builder: (_, __) => const SetPinScreen(),
      ),
      GoRoute(
        path: AppRoutes.trustedContactsPath,
        name: AppRoutes.trustedContacts,
        builder: (_, __) => const TrustedContactsScreen(),
      ),
      GoRoute(
        path: AppRoutes.homePath,
        name: AppRoutes.home,
        builder: (_, __) => const _HomePlaceholderScreen(),
      ),
    ],
    // redirect: hook point for auth / lock-screen / emergency-wipe
    // guards. Left inert until session state exists.
  );
});

/// Temporary landing target so the setup flow has somewhere to go.
/// Replaced by the real home screen when its design arrives.
class _HomePlaceholderScreen extends StatelessWidget {
  const _HomePlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: AppStatusView.empty(
          icon: Icons.shield_outlined,
          title: l10n.homePlaceholderTitle,
          message: l10n.homePlaceholderMessage,
        ),
      ),
    );
  }
}
