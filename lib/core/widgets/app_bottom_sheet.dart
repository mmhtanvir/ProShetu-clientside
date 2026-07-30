import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../utils/responsive.dart';

/// Standard modal bottom sheet: safe-area aware, keyboard aware,
/// width-clamped on tablets.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    constraints:
        const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
    builder: (BuildContext ctx) => Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: MediaQuery.viewInsetsOf(ctx).bottom + AppSpacing.md,
      ),
      child: builder(ctx),
    ),
  );
}
