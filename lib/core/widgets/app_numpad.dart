import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_theme.dart';

/// On-screen numeric keypad: 1–9, backspace, 0, submit.
/// Pure input surface; the host owns the entered value.
class AppNumpad extends StatelessWidget {
  const AppNumpad({
    required this.onDigit,
    required this.onBackspace,
    required this.onSubmit,
    this.submitEnabled = false,
    super.key,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;
  final bool submitEnabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final List<String> row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final String d in row)
                _Key(
                  child: Text(d),
                  onTap: () => onDigit(d),
                  semanticLabel: d,
                ),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Key(
              child: const Icon(Icons.backspace_outlined, size: 22),
              onTap: onBackspace,
              semanticLabel:
                  MaterialLocalizations.of(context).deleteButtonTooltip,
            ),
            _Key(
              child: const Text('0'),
              onTap: () => onDigit('0'),
              semanticLabel: '0',
            ),
            _Key(
              child: const Icon(Icons.arrow_forward_rounded, size: 22),
              onTap: submitEnabled ? onSubmit : null,
              filled: true,
              semanticLabel:
                  MaterialLocalizations.of(context).okButtonLabel,
            ),
          ],
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.child,
    required this.onTap,
    required this.semanticLabel,
    this.filled = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String semanticLabel;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final bool enabled = onTap != null;

    final Color fg = filled
        ? (isDark ? AppColors.backgroundDark : Colors.white)
        : theme.colorScheme.onSurface;

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Material(
          color: filled
              ? (enabled
                  ? (isDark ? Colors.white : AppColors.textPrimaryLight)
                  : theme.colorScheme.outline)
              : Colors.transparent,
          borderRadius: AppRadius.mdAll,
          child: InkWell(
            borderRadius: AppRadius.mdAll,
            onTap: onTap == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onTap!();
                  },
            child: SizedBox(
              width: 76,
              height: AppSpacing.minTouchTarget,
              child: Center(
                child: DefaultTextStyle(
                  style: theme.textTheme.titleMedium!.copyWith(color: fg),
                  child: IconTheme(
                    data: IconThemeData(color: fg, size: 22),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
