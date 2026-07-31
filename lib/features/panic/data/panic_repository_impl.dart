import 'dart:convert';

import 'package:geolocator/geolocator.dart';

import '../../../core/utils/geohash.dart';
import '../../../infrastructure/crypto/e2e_placeholder.dart';
import '../../coordination/domain/coordination_repository.dart';
import '../domain/panic_repository.dart';
import '../domain/sos_alert.dart';

/// Real implementation: an SOS alert IS a coordination delta
/// (apps/coordination) — the same encrypted, geohash-sharded fan-out
/// the Map tab reads from, per the backend's own data model. Position
/// is required to pick a shard; per the design spec (§7: never gate
/// distress/SOS), a location failure here should surface plainly
/// rather than silently drop the alert or fabricate a location — a
/// panic screen must not lie about whether help was actually sent.
///
/// The actual payload encryption is the intentionally-unimplemented
/// E2E seam (infrastructure/crypto/e2e_placeholder.dart): this method
/// will throw until that lands. That's correct behaviour, not a bug —
/// see that file's doc comment.
final class PanicRepositoryImpl implements PanicRepository {
  const PanicRepositoryImpl(this._coordination);

  final CoordinationRepository _coordination;

  static const int _highPriorityTtlSeconds = 6 * 3600; // 6h, matches distress class

  @override
  Future<void> createSosAlert(SosDraft draft) async {
    final Position position = await Geolocator.getCurrentPosition();
    final String geohash = Geohash.encode(
      position.latitude,
      position.longitude,
      precision: 5,
    );

    final Map<String, dynamic> payload = {
      'type': draft.type.name,
      'name': draft.name,
      'number': draft.number,
      'location': draft.location,
      if (draft.lookingFor.isNotEmpty) 'lookingFor': draft.lookingFor,
      if (draft.description.isNotEmpty) 'description': draft.description,
    };
    final List<int> plaintext = utf8.encode(jsonEncode(payload));

    // Throws (UnimplementedError) until the group-encryption scheme
    // for coordination shards is specified and implemented.
    final List<int> ciphertext = await E2ePlaceholder.encryptForShard(
      geohash: geohash,
      plaintext: plaintext,
    );

    await _coordination.publishDelta(
      geohash: geohash,
      ttlSeconds: _highPriorityTtlSeconds,
      ciphertext: ciphertext,
    );
  }
}
