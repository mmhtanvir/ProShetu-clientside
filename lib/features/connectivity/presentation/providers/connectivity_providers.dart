import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/mesh/ble_mesh_repository.dart';
import '../../../../infrastructure/mesh/ble_mesh_types.dart' show MeshAvailability;
import '../../../onboarding/presentation/providers/onboarding_providers.dart';
import '../../data/mesh_repository_impl.dart';
import '../../domain/mesh_peer.dart';
import '../../domain/mesh_repository.dart';

/// One shared radio for the whole app session — [BleMeshRepository]
/// ref-counts its own start()/stop() calls, so it's safe for the
/// providers below to each independently start/stop it without double
/// -managing the underlying scan/advertise state.
final _bleMeshRepositoryProvider = Provider<BleMeshRepository>((Ref ref) {
  final BleMeshRepository repo = BleMeshRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

final meshRepositoryProvider = Provider<MeshRepository>(
  (Ref ref) => MeshRepositoryImpl(ref.watch(_bleMeshRepositoryProvider)),
);

/// Whether discovery can run right now (Bluetooth off, permission
/// denied, unsupported hardware, or ready) — watched by the nearby-
/// mesh screen to show the right empty/blocked state instead of just
/// an endlessly-empty peer list.
final meshAvailabilityProvider =
    StreamProvider.autoDispose<MeshAvailability>((Ref ref) {
  final MeshRepository repo = ref.watch(meshRepositoryProvider);
  ref.onDispose(() => repo.stop());
  unawaited(repo.start());
  return repo.availability();
});

final networkStatusProvider = StreamProvider.autoDispose<NetworkStatus>((Ref ref) {
  final MeshRepository repo = ref.watch(meshRepositoryProvider);
  ref.onDispose(() => repo.stop());
  unawaited(repo.start());
  return repo.networkStatus();
});

final nearbyPeersProvider = StreamProvider.autoDispose<List<MeshPeer>>((Ref ref) {
  final MeshRepository repo = ref.watch(meshRepositoryProvider);
  ref.onDispose(() => repo.stop());
  unawaited(repo.start());
  return repo.nearbyPeers();
});

/// Signed-in user's own real display name, as entered at signup —
/// this feeds the dashboard greeting, the profile screen, and (most
/// importantly) the SOS form's name field, so it must never fall
/// back to a fabricated placeholder.
final displayNameProvider = FutureProvider<String>(
  (Ref ref) async =>
      await ref.watch(authRepositoryProvider).myDisplayName() ?? '',
);
