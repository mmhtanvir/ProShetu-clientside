/// Group-encryption + CRDT-merge scheme for coordination shard deltas
/// — out of scope for the 1:1 messaging E2E work (see
/// e2e_crypto_service.dart, which replaced e2e_placeholder.dart for
/// the 1:1 case). This is a separate, harder problem (group keying,
/// CRDT-aware merge-then-decrypt) that remains unspecified, so these
/// two functions still throw [UnimplementedError] on purpose rather
/// than silently treating plaintext as if it were encrypted — see
/// panic_repository_impl.dart / coordination_providers.dart, the
/// only two call sites.
///
/// DO NOT "fix" this by base64-encoding plaintext here. Replace it
/// with a real group-encryption scheme once that design exists, and
/// delete this file.
abstract final class ShardCryptoPlaceholder {
  static const String reason =
      'Coordination shard group-encryption is not implemented: the '
      'group-keying/CRDT-merge scheme is unspecified. See '
      'ShardCryptoPlaceholder doc comment.';

  /// Would group-encrypt a coordination CRDT delta for [geohash]'s
  /// shard so any peer subscribed to that shard (not just one
  /// recipient) can decrypt and merge it.
  static Future<List<int>> encryptForShard({
    required String geohash,
    required List<int> plaintext,
  }) {
    throw UnimplementedError(reason);
  }

  /// Would decrypt + CRDT-merge a coordination delta fetched from a
  /// shard.
  static Future<List<int>> decryptFromShard(List<int> ciphertext) {
    throw UnimplementedError(reason);
  }
}
