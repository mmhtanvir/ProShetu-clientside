import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import 'app_button.dart';

/// Standard confirmation dialog. Returns `true` when confirmed.
Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = false,
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actionsPadding: const EdgeInsets.all(AppSpacing.md),
      actions: [
        AppButton(
          label: cancelLabel,
          variant: AppButtonVariant.ghost,
          expanded: false,
          onPressed: () => Navigator.of(ctx).pop(false),
        ),
        AppButton(
          label: confirmLabel,
          variant:
              destructive ? AppButtonVariant.danger : AppButtonVariant.primary,
          expanded: false,
          onPressed: () => Navigator.of(ctx).pop(true),
        ),
      ],
    ),
  );
  return result ?? false;
}
