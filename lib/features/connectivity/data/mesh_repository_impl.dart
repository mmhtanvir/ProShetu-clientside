import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';

import '../../../infrastructure/mesh/ble_mesh_repository.dart';
import '../../../infrastructure/mesh/ble_mesh_types.dart' show DiscoveredMeshPeer, MeshAvailability;
import '../domain/mesh_peer.dart';
import '../domain/mesh_repository.dart';

/// Real mesh discovery, backed by [BleMeshRepository]. Replaces the
/// previous hardcoded 6-person list — every field here now reflects
/// an actually-observed device or a real OS check, not a fixture.
final class MeshRepositoryImpl implements MeshRepository {
  MeshRepositoryImpl(this._ble);

  final BleMeshRepository _ble;

  @override
  Stream<List<MeshPeer>> nearbyPeers() => _ble.peers.map(
        (List<DiscoveredMeshPeer> peers) =>
            peers.map(MeshPeer.fromDiscovered).toList(growable: false),
      );

  @override
  Stream<NetworkStatus> networkStatus() async* {
    await for (final List<DiscoveredMeshPeer> peers in _ble.peers) {
      yield NetworkStatus(
        meshDeviceCount: peers.length,
        internetOnline: await _isInternetOnline(),
        gpsLocked: await _isGpsLocked(),
      );
    }
  }

  @override
  Stream<MeshAvailability> availability() => _ble.availability;

  @override
  Future<void> start() => _ble.start();

  @override
  Future<void> stop() => _ble.stop();

  Future<bool> _isInternetOnline() async {
    final List<ConnectivityResult> results =
        await Connectivity().checkConnectivity();
    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }

  Future<bool> _isGpsLocked() async {
    try {
      final LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }
      return await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      return false;
    }
  }
}
