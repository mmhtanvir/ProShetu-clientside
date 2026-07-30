import 'mesh_peer.dart';

/// Contract for mesh discovery & network status.
/// Real implementation will live on infrastructure/mesh.
abstract interface class MeshRepository {
  Future<NetworkStatus> networkStatus();
  Future<List<MeshPeer>> nearbyPeers();
}
