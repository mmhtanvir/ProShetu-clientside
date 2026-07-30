import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/mesh_peer.dart';

/// Dark hero card: peer avatar cluster, device count, Connect CTA.
class MeshStatusCard extends StatelessWidget {
  const MeshStatusCard({
    required this.status,
    required this.peers,
    required this.onConnect,
    super.key,
  });

  final NetworkStatus status;
  final List<MeshPeer> peers;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final List<MeshPeer> shown = peers.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaisedDark,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          // Overlapping avatar cluster.
          SizedBox(
            height: 40,
            width: 40.0 + (shown.length - 1) * 24.0,
            child: Stack(
              children: [
                for (int i = 0; i < shown.length; i++)
                  Positioned(
                    left: i * 24.0,
                    child: AppAvatar(
                      name: shown[i].name,
                      online: shown[i].online,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  l10n.dashDevicesCount(
                    status.meshDeviceCount.toString().padLeft(2, '0'),
                  ),
                  style: theme.textTheme.headlineSmall,
                ),
                Text(
                  l10n.dashNearbyOnMesh,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.xs),
                AppButton(
                  label: l10n.dashConnect,
                  variant: AppButtonVariant.inverse,
                  pill: true,
                  expanded: false,
                  onPressed: onConnect,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
