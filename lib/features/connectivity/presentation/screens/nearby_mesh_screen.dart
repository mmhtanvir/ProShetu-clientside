import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/mesh_peer.dart';
import '../providers/connectivity_providers.dart';

/// Peers currently reachable over the mesh.
class NearbyMeshScreen extends ConsumerWidget {
  const NearbyMeshScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final peersAsync = ref.watch(nearbyPeersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dashNearbyOnMesh)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
            child: peersAsync.when(
              loading: () => const AppLoading(),
              error: (_, __) =>
                  AppStatusView.error(title: l10n.errorGenericTitle),
              data: (List<MeshPeer> peers) => ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: peers.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (BuildContext context, int i) {
                  final MeshPeer peer = peers[i];
                  final ThemeData theme = Theme.of(context);
                  return Row(
                    children: [
                      AppAvatar(name: peer.name, online: peer.online),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(peer.name,
                                style: theme.textTheme.titleMedium),
                            Text(
                              'Distance: ${peer.distanceLabel}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color:
                                      theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline_rounded,
                            size: 20),
                        onPressed: () => context.pushNamed(
                          AppRoutes.conversation,
                          pathParameters: {'id': peer.id},
                          extra: peer.name,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
