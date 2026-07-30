import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

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

  @override
  Widget build(BuildContext context) {
    final VoidCallback? effectiveOnPressed = isLoading ? null : onPressed;

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
      AppButtonVariant.primary =>
        FilledButton(onPressed: effectiveOnPressed, child: child),
      AppButtonVariant.danger => FilledButton(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
          ),
          child: child,
        ),
      AppButtonVariant.secondary =>
        OutlinedButton(onPressed: effectiveOnPressed, child: child),
      AppButtonVariant.ghost =>
        TextButton(onPressed: effectiveOnPressed, child: child),
    };

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
