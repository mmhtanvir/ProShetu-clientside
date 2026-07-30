import '../domain/mesh_peer.dart';
import '../domain/mesh_repository.dart';

/// MOCK mesh data until infrastructure/mesh lands.
final class MeshRepositoryImpl implements MeshRepository {
  const MeshRepositoryImpl();

  static const List<MeshPeer> _peers = [
    MeshPeer(id: 'p1', name: 'Emily Tran', distanceLabel: '0.3 km to Central Park'),
    MeshPeer(id: 'p2', name: 'Michael Lee', distanceLabel: '0.3 km to Riverside Cafe'),
    MeshPeer(id: 'p3', name: 'Ava Patel', distanceLabel: '0.3 km to the nearest bus stop'),
    MeshPeer(id: 'p4', name: 'James Kim', distanceLabel: '0.3 km to the library'),
    MeshPeer(id: 'p5', name: 'Olivia Wong', distanceLabel: '0.3 km to the community center'),
    MeshPeer(id: 'p6', name: 'Liam Johnson', distanceLabel: '0.3 km to the grocery store'),
  ];

  @override
  Future<NetworkStatus> networkStatus() async => NetworkStatus(
        meshDeviceCount: _peers.length,
        internetOnline: false,
        gpsLocked: true,
      );

  @override
  Future<List<MeshPeer>> nearbyPeers() async => _peers;
}
