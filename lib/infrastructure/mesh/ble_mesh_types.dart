/// Shared constants/types for BLE mesh Phase 1 (proximity discovery
/// only — see README.md in this directory for what Phase 1 does and
/// does not do, and why).
library;

/// The one service UUID every ProShetu device advertises so other
/// instances of the app can recognize each other. Deliberately just a
/// static marker — advertising it means "a ProShetu user is nearby"
/// is visible to any BLE scanner, which is a disclosed, accepted
/// trade-off of any discoverable mesh (see README.md). It carries no
/// identity of its own.
const String kMeshServiceUuid = 'b6b5b1a0-0e6c-4e6a-9c9b-5f2a7d1e9a01';

/// Coarse, honest proximity — never a fabricated distance. Derived
/// from a smoothed RSSI reading with hysteresis on the bucket
/// boundaries (see proximity_estimator.dart) so a peer doesn't flicker
/// between buckets on every scan tick.
enum ProximityBucket { veryClose, nearby, far }

/// Whether BLE mesh discovery can currently run at all, distinct from
/// whether any peers happen to be nearby right now. The mock this
/// replaces could never be in any of the non-[ready] states, so the
/// UI previously had no way to represent them.
enum MeshAvailability { unsupported, bluetoothOff, permissionDenied, ready }

/// A nearby device seen advertising [kMeshServiceUuid]. [bleDeviceId]
/// is the OS-assigned scan-time identifier (a randomized/rotating
/// privacy address on both Android and iOS, not a stable hardware
/// address) — it is intentionally never persisted beyond the current
/// discovery session. [mailboxId]/[displayName] are always null in
/// Phase 1: resolving a scanned device to a real ProShetu identity
/// requires an authenticated exchange over a GATT connection, which
/// neither BLE plugin this app uses exposes a custom-characteristic
/// API for (see README.md). A future Phase 1.1 that adds identity
/// resolution would populate these without changing this shape.
class DiscoveredMeshPeer {
  const DiscoveredMeshPeer({
    required this.bleDeviceId,
    required this.smoothedRssi,
    required this.proximity,
    required this.lastSeenAt,
    this.mailboxId,
    this.displayName,
  });

  final String bleDeviceId;
  final double smoothedRssi;
  final ProximityBucket proximity;
  final DateTime lastSeenAt;
  final String? mailboxId;
  final String? displayName;

  DiscoveredMeshPeer copyWith({
    double? smoothedRssi,
    ProximityBucket? proximity,
    DateTime? lastSeenAt,
  }) =>
      DiscoveredMeshPeer(
        bleDeviceId: bleDeviceId,
        smoothedRssi: smoothedRssi ?? this.smoothedRssi,
        proximity: proximity ?? this.proximity,
        lastSeenAt: lastSeenAt ?? this.lastSeenAt,
        mailboxId: mailboxId,
        displayName: displayName,
      );
}
