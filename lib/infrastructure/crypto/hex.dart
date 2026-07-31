import 'dart:typed_data';

/// Hex codec for keys/nonces/signatures — the backend expects every
/// binary field (public keys, nonces, signatures) as lowercase hex.
abstract final class Hex {
  static String encode(List<int> bytes) {
    final StringBuffer buf = StringBuffer();
    for (final int b in bytes) {
      buf.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return buf.toString();
  }

  static Uint8List decode(String hex) {
    final String clean = hex.trim();
    if (clean.length.isOdd) {
      throw FormatException('Hex string must have an even length', clean);
    }
    final Uint8List out = Uint8List(clean.length ~/ 2);
    for (int i = 0; i < out.length; i++) {
      out[i] = int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }
}
