import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

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
      final Color color = selected
          ? theme.colorScheme.onSurface
          : theme.colorScheme.onSurfaceVariant;
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
                  Icon(item.icon, size: 22, color: color),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    style:
                        theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      letterSpacing: 0,
                    ),
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
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            gradient: AppColors.brandGradient,
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.brandGlow,
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
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
