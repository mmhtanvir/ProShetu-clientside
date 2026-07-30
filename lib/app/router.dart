import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/app_status_view.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/onboarding/presentation/screens/splash_screen.dart';
import '../l10n/app_localizations.dart';

/// Route names & paths in one place. Screens navigate by name, never
/// by raw string, so paths can evolve safely.
abstract final class AppRoutes {
  static const String splash = 'splash';
  static const String splashPath = '/';

  static const String onboarding = 'onboarding';
  static const String onboardingPath = '/onboarding';

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
        builder: (BuildContext context, GoRouterState state) =>
            const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingPath,
        name: AppRoutes.onboarding,
        builder: (BuildContext context, GoRouterState state) =>
            const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.homePath,
        name: AppRoutes.home,
        builder: (BuildContext context, GoRouterState state) =>
            const _HomePlaceholderScreen(),
      ),
    ],
    // redirect: hook point for auth / lock-screen / emergency-wipe
    // guards. Left inert until session state exists.
  );
});

/// Temporary landing target so onboarding has somewhere to go.
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
