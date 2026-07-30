import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/splash_controller.dart';

/// Splash: brand mark, wordmark, tagline on the app background.
///
/// Pure presentation — boot orchestration and the routing decision
/// live in [SplashController]. A single, short fade-in is the only
/// motion (skipped entirely when the OS requests reduced motion).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void initState() {
    super.initState();
    // Kick off boot exactly once, after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.reduceMotion) {
        _fade.value = 1;
      } else {
        _fade.forward();
      }
      ref.read(splashControllerProvider.notifier).boot();
    });
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;

    // Controller decides where to go; screen only reacts.
    ref.listen<SplashDestination>(splashControllerProvider,
        (SplashDestination? previous, SplashDestination next) {
      switch (next) {
        case SplashDestination.onboarding:
          context.goNamed(AppRoutes.onboarding);
        case SplashDestination.login:
          context.goNamed(AppRoutes.login);
        case SplashDestination.pending:
          break;
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Semantics(
            label: '${l10n.appName}. ${l10n.splashTagline}',
            child: ExcludeSemantics(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandMark(size: 56),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.appName,
                    style: text.headlineMedium
                        ?.copyWith(color: AppColors.textPrimaryDark),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.splashTagline,
                    textAlign: TextAlign.center,
                    style: text.labelSmall
                        ?.copyWith(color: AppColors.textSecondaryDark),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
