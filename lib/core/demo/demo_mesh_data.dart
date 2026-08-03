import '../../features/connectivity/domain/mesh_peer.dart';
import '../../infrastructure/mesh/ble_mesh_types.dart' show ProximityBucket;

/// HACKATHON DEMO DATA — stands in for real BLE mesh discovery, which
/// needs a native GATT plugin to resolve peer identity (see
/// infrastructure/mesh/README.md) and real nearby devices to show
/// anything at all. Flip [kDemoMeshMode] off once either of those
/// exists for real; every consumer already reads through the normal
/// providers, so nothing else needs to change.
const bool kDemoMeshMode = true;

final List<MeshPeer> demoMeshPeers = [
  MeshPeer(
    bleDeviceId: 'demo-ble-1',
    proximity: ProximityBucket.veryClose,
    lastSeenAt: DateTime.now(),
    mailboxId: 'demo-mesh-rafiq',
    name: 'Rafiq Hasan',
  ),
  MeshPeer(
    bleDeviceId: 'demo-ble-2',
    proximity: ProximityBucket.nearby,
    lastSeenAt: DateTime.now(),
    mailboxId: 'demo-mesh-nusrat',
    name: 'Nusrat Jahan',
  ),
  MeshPeer(
    bleDeviceId: 'demo-ble-3',
    proximity: ProximityBucket.nearby,
    lastSeenAt: DateTime.now(),
    mailboxId: 'demo-mesh-amir',
    name: 'Amir Hossain',
  ),
  MeshPeer(
    bleDeviceId: 'demo-ble-4',
    proximity: ProximityBucket.far,
    lastSeenAt: DateTime.now(),
    mailboxId: 'demo-mesh-tania',
    name: 'Tania Akter',
  ),
];

/// First incoming message shown when a demo peer's chat is opened
/// with no history yet — keyed by [MeshPeer.mailboxId].
const Map<String, String> demoMeshGreetings = {
  'demo-mesh-rafiq': "Hey, I'm right next to you on the mesh 👋",
  'demo-mesh-nusrat': 'Spotted you nearby — mesh signal looks strong.',
  'demo-mesh-amir': "Can you see this? We're connected over Bluetooth mesh.",
  'demo-mesh-tania': "I'm a bit further out but still on the mesh.",
};
