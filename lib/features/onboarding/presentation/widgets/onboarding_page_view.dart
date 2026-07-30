import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import 'ambient_field_art.dart';

/// Immutable content model for one onboarding page.
@immutable
class OnboardingPageData {
  const OnboardingPageData({
    required this.title,
    required this.body,
    required this.variant,
  });

  final String title;
  final String body;
  final AmbientFieldVariant variant;
}

/// One page: full-bleed ambient art with bottom-anchored copy.
/// Buttons live in the parent screen (they're shared across pages).
class OnboardingPageView extends StatelessWidget {
  const OnboardingPageView({required this.data, super.key});

  final OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        AmbientFieldArt(variant: data.variant),
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: text.displaySmall
                      ?.copyWith(color: AppColors.textPrimaryDark),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  data.body,
                  style: text.bodyLarge
                      ?.copyWith(color: AppColors.textSecondaryDark),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
