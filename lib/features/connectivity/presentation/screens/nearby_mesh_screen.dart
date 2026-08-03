import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../infrastructure/location/location_providers.dart';
import '../../../../infrastructure/mesh/ble_mesh_types.dart'
    show MeshAvailability, ProximityBucket;
import '../../../../infrastructure/storage/contact_directory_store.dart';
import '../../../../infrastructure/storage/storage_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../messaging/presentation/providers/messaging_providers.dart';
import '../../domain/mesh_peer.dart';
import '../providers/connectivity_providers.dart';

String _proximityLabel(AppLocalizations l10n, ProximityBucket bucket) =>
    switch (bucket) {
      ProximityBucket.veryClose => l10n.meshProximityVeryClose,
      ProximityBucket.nearby => l10n.meshProximityNearby,
      ProximityBucket.far => l10n.meshProximityFar,
    };

/// Peers currently discoverable over Bluetooth (Phase 1: proximity
/// only, no identity resolution — see infrastructure/mesh/README.md).
/// Anonymous peers can't be messaged yet, so their chat action is
/// disabled rather than hidden — makes the current limitation visible
/// instead of silently doing nothing on tap.
class NearbyMeshScreen extends ConsumerWidget {
  const NearbyMeshScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<MeshAvailability> availabilityAsync =
        ref.watch(meshAvailabilityProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dashNearbyOnMesh)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
            child: availabilityAsync.when(
              loading: () => const AppLoading(),
              error: (_, __) =>
                  AppStatusView.error(title: l10n.errorGenericTitle),
              data: (MeshAvailability availability) => switch (availability) {
                MeshAvailability.unsupported => AppStatusView(
                    icon: Icons.bluetooth_disabled_rounded,
                    title: l10n.meshUnsupportedTitle,
                    message: l10n.meshUnsupportedMessage,
                  ),
                MeshAvailability.bluetoothOff => AppStatusView(
                    icon: Icons.bluetooth_disabled_rounded,
                    title: l10n.meshBluetoothOffTitle,
                    message: l10n.meshBluetoothOffMessage,
                    actionLabel: l10n.meshOpenSettings,
                    onAction: () => openAppSettings(),
                  ),
                MeshAvailability.permissionDenied => AppStatusView(
                    icon: Icons.bluetooth_disabled_rounded,
                    title: l10n.meshPermissionDeniedTitle,
                    message: l10n.meshPermissionDeniedMessage,
                    actionLabel: l10n.meshOpenSettings,
                    onAction: () => openAppSettings(),
                  ),
                MeshAvailability.ready => const _ReadyView(),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadyView extends ConsumerWidget {
  const _ReadyView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<MeshPeer>> peersAsync =
        ref.watch(nearbyPeersProvider);
    final int peerCount = peersAsync.valueOrNull?.length ?? 0;

    return Column(
      children: [
        const SizedBox(height: AppSpacing.lg),
        _RadarHero(peerCount: peerCount),
        const SizedBox(height: AppSpacing.sm),
        const _LocationLine(),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: peersAsync.when(
            loading: () => const AppLoading(),
            error: (_, __) =>
                AppStatusView.error(title: l10n.errorGenericTitle),
            data: (List<MeshPeer> peers) => peers.isEmpty
                ? AppStatusView.empty(
                    icon: Icons.bluetooth_searching_rounded,
                    title: l10n.meshEmptyTitle,
                    message: l10n.meshEmptyMessage,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: peers.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (BuildContext context, int i) {
                      final MeshPeer peer = peers[i];
                      final ThemeData theme = Theme.of(context);
                      final String name = peer.name ?? l10n.meshUnknownDevice;
                      return FadeSlideIn(
                        key: ValueKey(peer.bleDeviceId),
                        delay: Duration(milliseconds: i * 50),
                        child: Row(
                          children: [
                            AppAvatar(name: peer.name ?? '', online: true),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                      style: theme.textTheme.titleMedium),
                                  Text(
                                    peer.isIdentified
                                        ? _proximityLabel(l10n, peer.proximity)
                                        : '${_proximityLabel(l10n, peer.proximity)} · ${l10n.meshUnknownDeviceHint}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 20),
                              onPressed: peer.isIdentified
                                  ? () async {
                                      // Saved as a contact first (same as
                                      // add-by-number/QR) so this chat
                                      // survives leaving the screen and
                                      // shows up in the main chat list.
                                      await ref
                                          .read(contactDirectoryStoreProvider)
                                          .add(DirectoryContact(
                                            displayName: peer.name!,
                                            mailboxId: peer.mailboxId!,
                                          ));
                                      ref.invalidate(chatsProvider);
                                      if (!context.mounted) return;
                                      context.pushNamed(
                                        AppRoutes.conversation,
                                        pathParameters: {'id': peer.mailboxId!},
                                        extra: peer.name,
                                      );
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

/// Concentric pulsing rings around a center radio icon, with a peer-
/// count pill — the "actively scanning" visual. Rings only animate
/// while genuinely scanning (this widget only mounts once
/// [MeshAvailability.ready], so that's always true here).
class _RadarHero extends StatefulWidget {
  const _RadarHero({required this.peerCount});

  final int peerCount;

  @override
  State<_RadarHero> createState() => _RadarHeroState();
}

class _RadarHeroState extends State<_RadarHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _pulseRing(double t) {
    final double scale = 0.55 + t * 0.75;
    final double opacity = (1 - t) * 0.3;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withValues(alpha: opacity),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? child) => _pulseRing(
              _controller.value,
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? child) => _pulseRing(
              (_controller.value + 0.5) % 1.0,
            ),
          ),
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceRaisedDark,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            child:
                Icon(Icons.sensors_rounded, color: AppColors.primary, size: 34),
          ),
          Positioned(
            bottom: 46,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
              decoration: BoxDecoration(
                color: AppColors.primaryDeep,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                l10n.meshPeersBadge(
                    widget.peerCount.toString().padLeft(2, '0')),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Real GPS-backed location line — never a fixed/fabricated place.
/// Reverse-geocoded on-device when possible; falls back to raw
/// coordinates, then to an honest "unavailable" state (permission
/// denied, GPS off, or no fix yet), matching this codebase's existing
/// "degrade to unset, never fabricate" policy for location data.
class _LocationLine extends ConsumerWidget {
  const _LocationLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final AsyncValue<String?> placeAsync = ref.watch(currentPlaceLabelProvider);
    final AsyncValue<Position?> positionAsync =
        ref.watch(currentPositionProvider);

    String label;
    if (placeAsync.valueOrNull != null) {
      label = l10n.meshScanningNear(placeAsync.valueOrNull!);
    } else if (positionAsync.valueOrNull != null) {
      final Position pos = positionAsync.valueOrNull!;
      label = l10n.meshScanningNear(
        '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
      );
    } else if (placeAsync.isLoading || positionAsync.isLoading) {
      label = '…';
    } else {
      label = l10n.meshLocationUnavailable;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.location_on_rounded,
            size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xxs),
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
