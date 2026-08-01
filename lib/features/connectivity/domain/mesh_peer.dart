import 'package:equatable/equatable.dart';

import '../../../infrastructure/mesh/ble_mesh_types.dart';

/// A device reachable over the Bluetooth mesh right now. [mailboxId]/
/// [name] are null in Phase 1 — see infrastructure/mesh/README.md for
/// why identity resolution over BLE isn't possible with the plugins
/// this app uses. [bleDeviceId] is an OS-rotated scan-time id, not a
/// stable identifier — never used as a storage key.
class MeshPeer extends Equatable {
  const MeshPeer({
    required this.bleDeviceId,
    required this.proximity,
    required this.lastSeenAt,
    this.mailboxId,
    this.name,
  });

  factory MeshPeer.fromDiscovered(DiscoveredMeshPeer peer) => MeshPeer(
        bleDeviceId: peer.bleDeviceId,
        proximity: peer.proximity,
        lastSeenAt: peer.lastSeenAt,
        mailboxId: peer.mailboxId,
        name: peer.displayName,
      );

  final String bleDeviceId;
  final ProximityBucket proximity;
  final DateTime lastSeenAt;
  final String? mailboxId;
  final String? name;

  bool get isIdentified => mailboxId != null;

  @override
  List<Object?> get props =>
      [bleDeviceId, proximity, lastSeenAt, mailboxId, name];
}

/// Snapshot of connectivity shown on the dashboard.
class NetworkStatus extends Equatable {
  const NetworkStatus({
    required this.meshDeviceCount,
    required this.internetOnline,
    required this.gpsLocked,
  });

  final int meshDeviceCount;
  final bool internetOnline;
  final bool gpsLocked;

  @override
  List<Object?> get props => [meshDeviceCount, internetOnline, gpsLocked];
}
