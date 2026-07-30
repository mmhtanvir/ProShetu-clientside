import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/onboarding/presentation/screens/splash_screen.dart';

/// Route names & paths in one place. Screens navigate by name, never
/// by raw string, so paths can evolve safely.
abstract final class AppRoutes {
  static const String splash = 'splash';
  static const String splashPath = '/';

  // Reserved for upcoming flows — declared now so guards, deep links
  // and hidden routes have stable anchors.
  static const String onboarding = 'onboarding';
  static const String onboardingPath = '/onboarding';
  static const String lock = 'lock';
  static const String lockPath = '/lock';
  static const String home = 'home';
  static const String homePath = '/home';
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
      // Feature routes are appended as screens are delivered.
    ],
    // redirect: hook point for auth / lock-screen / emergency-wipe
    // guards. Left inert until session state exists.
  );
});
