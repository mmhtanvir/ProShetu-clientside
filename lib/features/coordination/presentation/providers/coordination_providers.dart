import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di.dart';
import '../../../../infrastructure/crypto/shard_crypto_placeholder.dart';
import '../../data/coordination_repository_impl.dart';
import '../../domain/coordination_repository.dart';

final coordinationRepositoryProvider = Provider<CoordinationRepository>(
  (Ref ref) => CoordinationRepositoryImpl(ref.watch(apiClientProvider)),
);

/// REAL round-trip to /v1/coord/{geohash} for a shard. Currently
/// always returns an empty list: every delta's ciphertext hits
/// [ShardCryptoPlaceholder.decryptFromShard], which throws until the
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
            await ShardCryptoPlaceholder.decryptFromShard(delta.ciphertext);
        decoded.add({'deltaId': delta.deltaId, 'plaintext': plaintext});
      } on UnimplementedError {
        // Expected today — see ShardCryptoPlaceholder doc comment. Skip this
        // delta rather than crash the whole fetch.
        continue;
      }
    }
    return decoded;
  },
);
