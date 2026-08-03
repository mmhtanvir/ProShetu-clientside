import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../utils/responsive.dart';

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
            backgroundColor: isDark ? Colors.white : AppColors.textPrimaryLight,
            foregroundColor: isDark ? AppColors.backgroundDark : Colors.white,
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

    final Widget sized =
        expanded ? SizedBox(width: double.infinity, child: button) : button;
    return _PressScale(enabled: effectiveOnPressed != null, child: sized);
  }
}

/// Subtle tap-down shrink on top of Material's own ripple/state-layer
/// feedback — a [Listener] rather than a gesture detector so it never
/// competes with the wrapped button for the actual tap. Skipped under
/// reduced motion, same convention as FadeSlideIn/SplashScreen.
class _PressScale extends StatefulWidget {
  const _PressScale({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );

  bool get _animatable => widget.enabled && !context.reduceMotion;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        if (_animatable) _controller.forward();
      },
      onPointerUp: (_) {
        if (_animatable) _controller.reverse();
      },
      onPointerCancel: (_) {
        if (_animatable) _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) => Transform.scale(
          scale: 1 - (_controller.value * 0.04),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
