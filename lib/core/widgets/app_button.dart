import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

enum AppButtonVariant {
  primary,
  secondary,
  ghost,
  danger,

  /// High-contrast against the current background (white pill on the
  /// dark theme). Used for hero CTAs like onboarding.
  inverse,
}

/// The one button used across the app.
///
/// Wraps Material buttons so every CTA shares sizing, radius, loading
/// behaviour and touch-target rules. Prefer this over raw buttons.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expanded = true,
    this.pill = false,
    super.key,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;

  /// Full-width by default (stress-friendly targets).
  final bool expanded;

  /// Fully rounded ends instead of the default [AppRadius.lg].
  final bool pill;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final VoidCallback? effectiveOnPressed = isLoading ? null : onPressed;

    final RoundedRectangleBorder? shape = pill
        ? const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
          )
        : null;

    final Widget child = isLoading
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final Widget button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(shape: shape),
          child: child,
        ),
      AppButtonVariant.inverse => FilledButton(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            backgroundColor:
                isDark ? Colors.white : AppColors.textPrimaryLight,
            foregroundColor:
                isDark ? AppColors.backgroundDark : Colors.white,
            shape: shape,
          ),
          child: child,
        ),
      AppButtonVariant.danger => FilledButton(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            shape: shape,
          ),
          child: child,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(shape: shape),
          child: child,
        ),
      AppButtonVariant.ghost => TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(shape: shape),
          child: child,
        ),
    };

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
