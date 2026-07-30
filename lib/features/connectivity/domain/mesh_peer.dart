import 'package:equatable/equatable.dart';

/// A device/person reachable over the Bluetooth mesh.
class MeshPeer extends Equatable {
  const MeshPeer({
    required this.id,
    required this.name,
    required this.distanceLabel,
    this.online = true,
  });

  final String id;
  final String name;

  /// Human-readable proximity, e.g. "0.3 km to Central Park".
  final String distanceLabel;
  final bool online;

  @override
  List<Object?> get props => [id, name, distanceLabel, online];
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
