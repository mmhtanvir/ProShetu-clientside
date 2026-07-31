import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di.dart';
import '../../../../infrastructure/crypto/e2e_placeholder.dart';
import '../../data/coordination_repository_impl.dart';
import '../../domain/coordination_repository.dart';
import '../../domain/crisis_alert.dart';

final coordinationRepositoryProvider = Provider<CoordinationRepository>(
  (Ref ref) => CoordinationRepositoryImpl(ref.watch(apiClientProvider)),
);

/// REAL round-trip to /v1/coord/{geohash} for a shard. Currently
/// always returns an empty list: every delta's ciphertext hits
/// [E2ePlaceholder.decryptFromShard], which throws until the
/// session/CRDT-merge scheme is implemented (see that file's doc
/// comment). The map screen still shows mock pins
/// ([mapMarkersProvider] below) for now — swap it to this provider
/// once decryption is real.
final liveCoordinationDeltasProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
  (Ref ref, String geohash) async {
    final List<CoordDelta> deltas = await ref
        .watch(coordinationRepositoryProvider)
        .fetchDeltas(geohash: geohash);
    final List<Map<String, dynamic>> decoded = [];
    for (final CoordDelta delta in deltas) {
      try {
        final List<int> plaintext =
            await E2ePlaceholder.decryptFromShard(delta.ciphertext);
        decoded.add({'deltaId': delta.deltaId, 'plaintext': plaintext});
      } on UnimplementedError {
        // Expected today — see E2ePlaceholder doc comment. Skip this
        // delta rather than crash the whole fetch.
        continue;
      }
    }
    return decoded;
  },
);

/// MOCK active alerts until the coordination backend is wired.
final activeAlertsProvider = Provider<List<CrisisAlert>>((_) => const [
      CrisisAlert(
        id: 'a1',
        title: 'Flash Flood Warning — Downtown Area',
        body:
            'Avoid Dhanmondi Rd, Gulshan Ave. Shelters are available at Dhaka Community Center camp; National Museum.',
        ageLabel: '15m ago',
      ),
      CrisisAlert(
        id: 'a2',
        title: 'Road Closure — Mirpur Rd',
        body: 'Mirpur Rd closed near Science Lab. Use Panthapath as detour.',
        ageLabel: '32m ago',
      ),
      CrisisAlert(
        id: 'a3',
        title: 'Medical Camp Open — Ramna Park',
        body: 'Free medical support at Ramna Park north gate until 6 PM.',
        ageLabel: '1h ago',
      ),
    ]);
