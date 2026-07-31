import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'hex.dart';

/// Content-addressing hash used everywhere the backend derives an id
/// from ciphertext: `event_id = BLAKE2b-128(ciphertext)` (sync),
/// `delta_id = BLAKE2b-128(ciphertext)` (coordination). Matching this
/// exactly matters — the server recomputes it and rejects a mismatch.
abstract final class ContentId {
  static final Blake2b _hasher = Blake2b(hashLengthInBytes: 16);

  static Future<String> ofBytes(Uint8List data) async {
    final Hash digest = await _hasher.hash(data);
    return Hex.encode(digest.bytes);
  }
}
