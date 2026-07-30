import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

enum AppSnackbarKind { info, success, error }

/// Single entry point for transient feedback.
void showAppSnackbar(
  BuildContext context,
  String message, {
  AppSnackbarKind kind = AppSnackbarKind.info,
}) {
  final Color accent = switch (kind) {
    AppSnackbarKind.info => AppColors.info,
    AppSnackbarKind.success => AppColors.success,
    AppSnackbarKind.error => AppColors.danger,
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              switch (kind) {
                AppSnackbarKind.info => Icons.info_outline_rounded,
                AppSnackbarKind.success => Icons.check_circle_outline_rounded,
                AppSnackbarKind.error => Icons.error_outline_rounded,
              },
              color: accent,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
