/// The backend (apps/sync, apps/coordination, apps/calling) is a
/// zero-knowledge relay: every `ciphertext` field it stores is opaque
/// to it. Producing and consuming that ciphertext — the actual
/// end-to-end encryption — is the client's job, and the concrete
/// scheme (X3DH session establishment from the uploaded prekeys, the
/// ongoing ratchet/session cipher for 1:1 events, the group-encryption
/// + CRDT-merge scheme for coordination deltas, size-bucket padding)
/// is **not specified** anywhere in the backend repo or docs
/// available when this integration was built — the backend's own
/// README points to `crisis-platform-architecture.md` for it, which
/// wasn't provided.
///
/// Every call site in this codebase that needs to produce or consume
/// a `ciphertext` field routes through the two functions below. They
/// throw [UnimplementedError] on purpose rather than silently
/// treating plaintext as if it were encrypted — for an app whose
/// users include protesters, disaster victims, and missing-person
/// reporters, a fake "encrypted" field is actively dangerous: it
/// would look secure in the code while providing none.
///
/// DO NOT "fix" this by base64-encoding plaintext here. Replace it
/// with a real implementation of the session/ratchet scheme once
/// that design exists, and delete this file.
abstract final class E2ePlaceholder {
  static const String reason =
      'End-to-end payload encryption is not implemented: the session/'
      'ratchet scheme is unspecified in the materials available for '
      'this integration. See E2ePlaceholder doc comment.';

  /// Would encrypt [plaintext] for [recipientMailboxId] (1:1 sync
  /// events, call signals) using a session derived from their X3DH
  /// prekey bundle.
  static Future<List<int>> encryptForRecipient({
    required String recipientMailboxId,
    required List<int> plaintext,
  }) {
    throw UnimplementedError(reason);
  }

  /// Would decrypt an event delivered from the fabric back into its
  /// plaintext (and the sealed sender identity it contains).
  static Future<List<int>> decryptFromSender(List<int> ciphertext) {
    throw UnimplementedError(reason);
  }

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
