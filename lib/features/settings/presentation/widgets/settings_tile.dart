import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// One row in the profile settings lists.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    required this.icon,
    required this.title,
    this.trailingLabel,
    this.onTap,
    this.danger = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? trailingLabel;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color fg =
        danger ? AppColors.danger : theme.colorScheme.onSurface;

    return Material(
      color: danger
          ? AppColors.danger.withValues(alpha: 0.08)
          : theme.colorScheme.surface,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(color: fg),
                ),
              ),
              if (trailingLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.smAll,
                    border:
                        Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Text(
                    trailingLabel!,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10),
                  ),
                ),
              if (onTap != null && !danger) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.chevron_right_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
