import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/ambient_field_art.dart';
import '../widgets/onboarding_page_view.dart';

/// First-run onboarding carousel (3 pages).
///
/// The [PageController] is the single source of truth for the page
/// index; only the button row listens to it, so swiping never
/// rebuilds the art or copy of other pages.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int get _currentPage =>
      _pageController.hasClients ? (_pageController.page ?? 0).round() : 0;

  void _goTo(int page) {
    if (context.reduceMotion) {
      _pageController.jumpToPage(page);
    } else {
      _pageController.animateToPage(
        page,
        duration: AppDurations.normal,
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _finish() async {
    await ref.read(onboardingControllerProvider.notifier).complete();
    if (mounted) context.goNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    final List<OnboardingPageData> pages = [
      OnboardingPageData(
        title: l10n.onboardingMeshTitle,
        body: l10n.onboardingMeshBody,
        variant: AmbientFieldVariant.goldWave,
      ),
      OnboardingPageData(
        title: l10n.onboardingEncryptionTitle,
        body: l10n.onboardingEncryptionBody,
        variant: AmbientFieldVariant.tealFlow,
      ),
      OnboardingPageData(
        title: l10n.onboardingMapsTitle,
        body: l10n.onboardingMapsBody,
        variant: AmbientFieldVariant.duskSwirl,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Skip — always available; same action as Confirm.
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: AppButton(
                  label: l10n.commonSkip,
                  variant: AppButtonVariant.ghost,
                  expanded: false,
                  onPressed: _finish,
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                itemBuilder: (BuildContext context, int index) =>
                    OnboardingPageView(data: pages[index]),
              ),
            ),
            // Button row — the only part that rebuilds on swipe.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Breakpoints.contentMaxWidth,
                ),
                child: ListenableBuilder(
                  listenable: _pageController,
                  builder: (BuildContext context, _) {
                    final int page = _currentPage;
                    final bool isFirst = page == 0;
                    final bool isLast = page == pages.length - 1;

                    return Row(
                      children: [
                        if (!isFirst && !isLast) ...[
                          Expanded(
                            child: AppButton(
                              label: l10n.commonPrevious,
                              variant: AppButtonVariant.secondary,
                              pill: true,
                              onPressed: () => _goTo(page - 1),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                        ],
                        Expanded(
                          child: AppButton(
                            label: isLast
                                ? l10n.commonConfirm
                                : l10n.commonNext,
                            variant: AppButtonVariant.inverse,
                            pill: true,
                            onPressed:
                                isLast ? _finish : () => _goTo(page + 1),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
