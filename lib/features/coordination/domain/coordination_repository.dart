import 'package:equatable/equatable.dart';

/// One raw delta as the backend stores it — ciphertext only. Turning
/// this into a [MapMarker] needs real decryption
/// (infrastructure/crypto/e2e_placeholder.dart), so this type
/// deliberately stops at "opaque bytes plus routing metadata", the
/// same boundary the backend itself keeps.
class CoordDelta extends Equatable {
  const CoordDelta({
    required this.deltaId,
    required this.geohash,
    required this.ciphertext,
    required this.createdAt,
    required this.expiresAt,
  });

  final String deltaId;
  final String geohash;
  final List<int> ciphertext;
  final DateTime createdAt;
  final DateTime expiresAt;

  @override
  List<Object?> get props => [deltaId, geohash, createdAt, expiresAt];
}

/// Contract for apps/coordination (map/SOS pins). Transport details
/// live in data/; presentation depends only on this interface.
abstract interface class CoordinationRepository {
  /// POST /v1/coord/{geohash}/publish
  Future<String> publishDelta({
    required String geohash,
    required int ttlSeconds,
    required List<int> ciphertext,
  });

  /// GET /v1/coord/{geohash}
  Future<List<CoordDelta>> fetchDeltas({
    required String geohash,
    DateTime? since,
  });
}
