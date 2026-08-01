import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

enum AppSnackbarKind { info, success, error }

OverlayEntry? _currentEntry;

/// Single entry point for transient feedback. Renders as a banner
/// anchored to the TOP of the screen (Flutter's SnackBar/
/// ScaffoldMessenger has no top-anchor option, so this bypasses it
/// entirely via the Overlay) — matches the top-banner convention of
/// most mobile OSes instead of docking to the bottom.
void showAppSnackbar(
  BuildContext context,
  String message, {
  AppSnackbarKind kind = AppSnackbarKind.info,
}) {
  _currentEntry?.remove();
  _currentEntry = null;

  final OverlayState overlay = Overlay.of(context);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (BuildContext context) => _TopToast(
      message: message,
      kind: kind,
      onDismissed: () {
        if (identical(_currentEntry, entry)) _currentEntry = null;
        entry.remove();
      },
    ),
  );
  _currentEntry = entry;
  overlay.insert(entry);
}

class _TopToast extends StatefulWidget {
  const _TopToast({
    required this.message,
    required this.kind,
    required this.onDismissed,
  });

  final String message;
  final AppSnackbarKind kind;
  final VoidCallback onDismissed;

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    reverseDuration: const Duration(milliseconds: 160),
  );
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _autoDismissTimer = Timer(const Duration(milliseconds: 3500), _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    _autoDismissTimer?.cancel();
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = switch (widget.kind) {
      AppSnackbarKind.info => AppColors.info,
      AppSnackbarKind.success => AppColors.success,
      AppSnackbarKind.error => AppColors.danger,
    };
    final IconData icon = switch (widget.kind) {
      AppSnackbarKind.info => Icons.info_outline_rounded,
      AppSnackbarKind.success => Icons.check_circle_outline_rounded,
      AppSnackbarKind.error => Icons.error_outline_rounded,
    };
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _controller,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            )),
            child: FadeTransition(
              opacity: _controller,
              child: GestureDetector(
                onVerticalDragEnd: (DragEndDetails details) {
                  if ((details.primaryVelocity ?? 0) < 0) _dismiss();
                },
                child: Material(
                  color: isDark
                      ? AppColors.surfaceRaisedDark
                      : AppColors.textPrimaryLight,
                  borderRadius: AppRadius.mdAll,
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: accent, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? theme.colorScheme.onSurface
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
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
