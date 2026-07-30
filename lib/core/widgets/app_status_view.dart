import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../utils/responsive.dart';
import 'app_button.dart';

/// Shared layout for error and empty states: icon, title, message,
/// optional action. Keeps every "nothing to show" screen consistent.
class AppStatusView extends StatelessWidget {
  const AppStatusView({
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    super.key,
  });

  /// Error-state convenience constructor.
  const AppStatusView.error({
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  })  : icon = Icons.error_outline_rounded,
        iconColor = AppColors.danger;

  /// Empty-state convenience constructor.
  const AppStatusView.empty({
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.inbox_outlined,
    super.key,
  }) : iconColor = null;

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 48,
                color: iconColor ?? theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message!,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  expanded: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
