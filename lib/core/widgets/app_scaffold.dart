import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../utils/responsive.dart';

/// Screen shell: safe area + horizontal padding + tablet width clamp.
/// Use for standard content screens so layout rules live in one place.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.body,
    this.appBar,
    this.bottomBar,
    this.clampWidth = true,
    this.padded = true,
    super.key,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomBar;
  final bool clampWidth;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    Widget content = body;

    if (padded) {
      content = Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        child: content,
      );
    }

    if (clampWidth) {
      content = Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
          child: content,
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: SafeArea(child: content),
      bottomNavigationBar: bottomBar,
    );
  }
}
