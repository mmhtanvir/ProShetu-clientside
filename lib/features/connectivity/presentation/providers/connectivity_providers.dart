import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mesh_repository_impl.dart';
import '../../domain/mesh_peer.dart';
import '../../domain/mesh_repository.dart';

final meshRepositoryProvider =
    Provider<MeshRepository>((_) => const MeshRepositoryImpl());

final networkStatusProvider = FutureProvider<NetworkStatus>(
  (Ref ref) => ref.watch(meshRepositoryProvider).networkStatus(),
);

final nearbyPeersProvider = FutureProvider<List<MeshPeer>>(
  (Ref ref) => ref.watch(meshRepositoryProvider).nearbyPeers(),
);

/// Signed-in user's display name (mock until profile wiring).
final displayNameProvider = Provider<String>((_) => 'Alex Rivera');
