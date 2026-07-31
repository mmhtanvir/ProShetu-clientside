import 'dart:typed_data';

import 'package:crypto/crypto.dart' as pkg_crypto;

import '../crypto/hex.dart';

/// A standard Bloom filter over hex event/delta ids, matching the
/// `bloom_m` (bit count) / `bloom_k` (hash count) / `bloom_bits` (hex)
/// shape `/v1/sync` expects (README: "bloom : {m, k, bits_hex} —
/// filter of event_ids the client already holds").
///
/// This is a plain, non-cryptographic data structure — nothing here
/// is part of the unimplemented E2E seam; it's safe to use as-is.
class BloomFilter {
  BloomFilter({required this.m, required this.k}) : _bits = Uint8List((m + 7) ~/ 8);

  BloomFilter._raw(this.m, this.k, this._bits);

  /// Number of bits in the filter.
  final int m;

  /// Number of hash functions.
  final int k;

  final Uint8List _bits;

  /// A reasonable default for a device holding up to a few thousand
  /// ids with a low false-positive rate: ~10 bits/element at k=7.
  factory BloomFilter.defaultSized({int expectedElements = 2000}) {
    final int m = (expectedElements * 10).clamp(64, 65536);
    return BloomFilter(m: m, k: 7);
  }

  void add(String hexId) {
    for (final int idx in _slots(hexId)) {
      _bits[idx >> 3] |= (1 << (idx & 7));
    }
  }

  bool mightContain(String hexId) {
    for (final int idx in _slots(hexId)) {
      if (_bits[idx >> 3] & (1 << (idx & 7)) == 0) return false;
    }
    return true;
  }

  String get bitsHex => Hex.encode(_bits);

  static BloomFilter fromHex({
    required int m,
    required int k,
    required String bitsHex,
  }) =>
      BloomFilter._raw(m, k, Hex.decode(bitsHex));

  /// Double-hashing (Kirsch–Mitzenmacher): derive k independent slot
  /// indices from two SHA-256 halves rather than hashing k times.
  Iterable<int> _slots(String hexId) sync* {
    final Uint8List digest =
        Uint8List.fromList(pkg_crypto.sha256.convert(hexId.codeUnits).bytes);
    final int h1 = _readUint32(digest, 0);
    final int h2 = _readUint32(digest, 4);
    for (int i = 0; i < k; i++) {
      yield (h1 + i * h2).abs() % m;
    }
  }

  static int _readUint32(Uint8List bytes, int offset) =>
      (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
}
