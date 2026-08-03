import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../utils/responsive.dart';

/// Item descriptor for [AppBottomNav].
class AppBottomNavItem {
  const AppBottomNavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

/// Custom bottom bar: 4 tabs with a raised central SOS action.
/// Stateless — the shell owns selection and callbacks.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.sosLabel,
    required this.onSos,
    super.key,
  });

  /// Exactly four tab items (SOS sits between items 1 and 2).
  final List<AppBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String sosLabel;
  final VoidCallback onSos;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    assert(items.length == 4, 'AppBottomNav expects exactly 4 items');

    Widget tab(int index) {
      final bool selected = index == currentIndex;
      final Color selectedColor = theme.colorScheme.onSurface;
      final Color unselectedColor = theme.colorScheme.onSurfaceVariant;
      final AppBottomNavItem item = items[index];

      return Expanded(
        child: Semantics(
          selected: selected,
          button: true,
          label: item.label,
          child: InkWell(
            onTap: () => onTap(index),
            child: SizedBox(
              height: 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: selected ? 1 : 0),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    builder: (BuildContext context, double t, Widget? child) {
                      return Transform.scale(
                        scale: 1 + (t * 0.12),
                        child: Icon(
                          item.icon,
                          size: 22,
                          color: Color.lerp(unselectedColor, selectedColor, t),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: theme.textTheme.labelSmall?.copyWith(
                          color: selected ? selectedColor : unselectedColor,
                          letterSpacing: 0,
                        ) ??
                        const TextStyle(),
                    child: Text(item.label),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              tab(0),
              tab(1),
              // Raised SOS action.
              Expanded(
                child: Semantics(
                  button: true,
                  label: sosLabel,
                  child: InkWell(
                    onTap: onSos,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _PulsingSosIcon(sosLabel: sosLabel),
                        const SizedBox(height: 2),
                        Text(
                          sosLabel,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(letterSpacing: 0),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              tab(2),
              tab(3),
            ],
          ),
        ),
      ),
    );
  }
}

/// A slow breathing glow around the SOS icon — draws the eye to the
/// one action that matters most in this app without being frantic
/// (long duration, subtle range). Skipped under reduced motion, same
/// convention as FadeSlideIn/SplashScreen.
class _PulsingSosIcon extends StatefulWidget {
  const _PulsingSosIcon({required this.sosLabel});

  final String sosLabel;

  @override
  State<_PulsingSosIcon> createState() => _PulsingSosIconState();
}

class _PulsingSosIconState extends State<_PulsingSosIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (!context.reduceMotion) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double t = _controller.value;
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35 + t * 0.25),
                blurRadius: 10 + t * 8,
                spreadRadius: t * 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: const Icon(
        Icons.warning_amber_rounded,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}
