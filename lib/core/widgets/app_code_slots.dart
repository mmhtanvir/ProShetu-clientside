import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Row of code entry slots (OTP boxes, PIN dots). Display-only:
/// input handling belongs to the host screen.
class AppCodeSlots extends StatelessWidget {
  const AppCodeSlots({
    required this.length,
    required this.value,
    this.obscure = false,
    super.key,
  });

  final int length;
  final String value;

  /// Show a dot instead of the digit (PIN entry).
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextStyle? digitStyle = Theme.of(context).textTheme.titleLarge;
    final int active = value.length.clamp(0, length - 1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(length, (int i) {
        final bool filled = i < value.length;
        final bool isActive = i == active && value.length < length;

        return Container(
          width: 44,
          height: 52,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: isActive ? AppColors.primary : scheme.outline,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: filled
              ? (obscure
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: scheme.onSurface,
                        shape: BoxShape.circle,
                      ),
                    )
                  : Text(value[i], style: digitStyle))
              : null,
        );
      }),
    );
  }
}
