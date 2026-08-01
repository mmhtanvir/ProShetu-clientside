import '../../../infrastructure/mesh/ble_mesh_types.dart' show MeshAvailability;
import 'mesh_peer.dart';

/// Contract for real-time mesh discovery & network status. Discovery
/// is continuous, not a one-shot fetch — hence streams, with explicit
/// [start]/[stop] lifecycle tied to whichever screen(s) are actually
/// watching (see connectivity_providers.dart's `.autoDispose`).
abstract interface class MeshRepository {
  Stream<List<MeshPeer>> nearbyPeers();
  Stream<NetworkStatus> networkStatus();

  /// Whether discovery can run right now — unsupported hardware,
  /// Bluetooth off, or permission denied, distinct from simply no
  /// peers being nearby. The mock this replaces could never be in any
  /// of the non-ready states.
  Stream<MeshAvailability> availability();

  /// Safe to call from more than one independent listener — start/stop
  /// calls are reference-counted internally, so the underlying radio
  /// only actually stops once every caller has stopped.
  Future<void> start();
  Future<void> stop();
}
