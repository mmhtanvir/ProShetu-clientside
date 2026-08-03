import 'package:flutter/material.dart';

import '../utils/responsive.dart';

/// One-shot fade + slide-up entrance. Plays once per [Key] — reuse a
/// stable key (e.g. `ValueKey(item.id)`) in a list so already-visible
/// items never replay on rebuild, only genuinely new ones animate in.
/// Skipped entirely under reduced motion (same convention as
/// SplashScreen's `context.reduceMotion`).
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    required this.child,
    this.delay = Duration.zero,
    this.beginDy = 0.08,
    super.key,
  });

  final Widget child;
  final Duration delay;

  /// Starting vertical offset as a fraction of the child's height.
  final double beginDy;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: Offset(0, widget.beginDy),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    if (context.reduceMotion) {
      _controller.value = 1;
      return;
    }
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}
