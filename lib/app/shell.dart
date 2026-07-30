import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/app_bottom_nav.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';

/// Tab shell hosting Home / Chats / Map / Profile branches with the
/// raised SOS action. IndexedStack keeps tab state alive without
/// rebuilding on switch.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        items: [
          AppBottomNavItem(
              icon: Icons.home_outlined, label: l10n.navHome),
          AppBottomNavItem(
              icon: Icons.chat_bubble_outline_rounded,
              label: l10n.navChats),
          AppBottomNavItem(icon: Icons.map_outlined, label: l10n.navMap),
          AppBottomNavItem(
              icon: Icons.person_outline_rounded, label: l10n.navProfile),
        ],
        sosLabel: l10n.navSos,
        onSos: () => context.pushNamed(AppRoutes.sos),
        onTap: (int index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
