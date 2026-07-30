import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../l10n/app_localizations.dart';

/// Vault contents grouped by date.
///
/// Tiles are procedural placeholders until encrypted media storage
/// lands (infrastructure/media + crypto). Layout matches the design:
/// date sections with a 3-column square grid.
class VaultGalleryScreen extends StatelessWidget {
  const VaultGalleryScreen({super.key});

  static const List<Color> _tilePalette = [
    Color(0xFF8A6E9E), Color(0xFF4F7286), Color(0xFF5F4FB3),
    Color(0xFFB08968), Color(0xFF6E8B74), Color(0xFF9E5E5E),
    Color(0xFF5E7A9E), Color(0xFF9E8A5E), Color(0xFF4E6E5E),
  ];

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    final List<(String, int)> sections = [
      (l10n.vaultToday, 3),
      ('27/07/25', 9),
      ('30/02/25', 3),
    ];

    Widget tile(int seed) {
      final Color base =
          _tilePalette[seed % _tilePalette.length];
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.smAll,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              base.withValues(alpha: 0.85),
              base.withValues(alpha: 0.45),
            ],
          ),
        ),
      );
    }

    int seed = 0;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileVault)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                for (final (String label, int count) in sections) ...[
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppSpacing.xxs,
                    crossAxisSpacing: AppSpacing.xxs,
                    children: [
                      for (int i = 0; i < count; i++) tile(seed++),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
