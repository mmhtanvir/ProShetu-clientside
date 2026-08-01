import 'dart:typed_data';

import 'double_ratchet.dart';
import 'hex.dart';

/// Wire framing for an encrypted message event. Two subtypes share a
/// common header; INITIAL additionally carries the X3DH identity
/// fields a new session bootstrap needs (see the E2E encryption plan
/// for the full construction and the accepted, disclosed
/// metadata-privacy tradeoff this implies for a session's first
/// message only).
enum EnvelopeMessageType { initial, continuing }

/// Mirrors the backend's `PLATFORM["SIZE_BUCKETS"]` (config/settings.py)
/// — padding to these exact values keeps ciphertext lengths from
/// leaking finer-grained content-size information than the server's
/// own bucketing already does.
const List<int> sizeBuckets = <int>[512, 2048, 8192, 32768, 131072, 1048576];

class EnvelopeHeader {
  const EnvelopeHeader({
    required this.msgType,
    required this.ns,
    required this.pn,
    required this.ratchetPubHex,
    this.initiatorIkXPubHex,
    this.initiatorIkEdPubHex,
    this.usedSignedPrekeyPubHex,
    this.usedOneTimePrekeyPubHex,
  });

  static const int version = 1;

  final EnvelopeMessageType msgType;
  final int ns;
  final int pn;
  final String ratchetPubHex;

  // INITIAL-only — null for CONTINUING.
  final String? initiatorIkXPubHex;
  final String? initiatorIkEdPubHex;
  final String? usedSignedPrekeyPubHex;
  final String? usedOneTimePrekeyPubHex;

  RatchetHeader get ratchetHeader =>
      RatchetHeader(dhPublicKeyHex: ratchetPubHex, n: ns, pn: pn);
}

/// Binary encode/decode of [EnvelopeHeader] plus the padded-plaintext
/// framing. Deliberately a fixed binary layout (not JSON) — every
/// other crypto primitive in this codebase is byte-oriented with
/// fixed-length fields, and a fixed layout makes the size-bucket
/// padding math exact.
abstract final class MessageEnvelope {
  /// Encodes a header to its wire bytes. Also used as-is as the AEAD
  /// associated data (binds the header to the ciphertext, so a
  /// malicious relay can't splice a header from one event onto
  /// ciphertext from another).
  static List<int> encodeHeader(EnvelopeHeader header) {
    final BytesBuilder out = BytesBuilder();
    out.addByte(EnvelopeHeader.version);
    out.addByte(header.msgType == EnvelopeMessageType.initial ? 0x01 : 0x02);
    out.add(_uint32be(header.ns));
    out.add(_uint32be(header.pn));
    out.add(Hex.decode(header.ratchetPubHex));
    if (header.msgType == EnvelopeMessageType.initial) {
      out.add(Hex.decode(header.initiatorIkXPubHex!));
      out.add(Hex.decode(header.initiatorIkEdPubHex!));
      out.add(Hex.decode(header.usedSignedPrekeyPubHex!));
      final String? otk = header.usedOneTimePrekeyPubHex;
      out.addByte(otk != null ? 0x01 : 0x00);
      if (otk != null) out.add(Hex.decode(otk));
    }
    return out.toBytes();
  }

  /// Decodes a header from the front of [bytes]; returns the header
  /// plus how many bytes it consumed, so the caller knows where the
  /// AEAD ciphertext begins.
  static (EnvelopeHeader, int) decodeHeader(List<int> bytes) {
    final Uint8List b = Uint8List.fromList(bytes);
    final ByteData view = ByteData.sublistView(b);
    final int version = b[0];
    if (version != EnvelopeHeader.version) {
      throw FormatException('Unsupported envelope version: $version');
    }
    final EnvelopeMessageType msgType =
        b[1] == 0x01 ? EnvelopeMessageType.initial : EnvelopeMessageType.continuing;
    final int ns = view.getUint32(2, Endian.big);
    final int pn = view.getUint32(6, Endian.big);
    final String ratchetPubHex = Hex.encode(b.sublist(10, 42));

    if (msgType == EnvelopeMessageType.continuing) {
      return (
        EnvelopeHeader(
          msgType: msgType,
          ns: ns,
          pn: pn,
          ratchetPubHex: ratchetPubHex,
        ),
        42,
      );
    }

    final String ikX = Hex.encode(b.sublist(42, 74));
    final String ikEd = Hex.encode(b.sublist(74, 106));
    final String spk = Hex.encode(b.sublist(106, 138));
    final bool hasOtk = b[138] == 0x01;
    String? otk;
    int consumed = 139;
    if (hasOtk) {
      otk = Hex.encode(b.sublist(139, 171));
      consumed = 171;
    }
    return (
      EnvelopeHeader(
        msgType: msgType,
        ns: ns,
        pn: pn,
        ratchetPubHex: ratchetPubHex,
        initiatorIkXPubHex: ikX,
        initiatorIkEdPubHex: ikEd,
        usedSignedPrekeyPubHex: spk,
        usedOneTimePrekeyPubHex: otk,
      ),
      consumed,
    );
  }

  /// Builds the padded plaintext that gets AEAD-encrypted:
  /// content_type(1) + content_length(2 BE) + content + zero padding
  /// out to the nearest [sizeBuckets] value.
  static List<int> padPlaintext(int contentType, List<int> content) {
    const int headerLen = 3;
    final int rawLen = headerLen + content.length;
    final int bucket = sizeBuckets.firstWhere(
      (int b) => b >= rawLen,
      orElse: () => sizeBuckets.last,
    );
    final BytesBuilder out = BytesBuilder();
    out.addByte(contentType);
    out.add(_uint16be(content.length));
    out.add(content);
    if (bucket > rawLen) out.add(List<int>.filled(bucket - rawLen, 0));
    return out.toBytes();
  }

  static (int contentType, List<int> content) unpadPlaintext(
    List<int> padded,
  ) {
    final Uint8List b = Uint8List.fromList(padded);
    final int contentType = b[0];
    final int length = ByteData.sublistView(b).getUint16(1, Endian.big);
    return (contentType, b.sublist(3, 3 + length));
  }

  /// Assembles the full wire envelope: header bytes + AEAD
  /// ciphertext-and-tag.
  static List<int> buildEnvelope(
    EnvelopeHeader header,
    List<int> ciphertextAndMac,
  ) =>
      <int>[...encodeHeader(header), ...ciphertextAndMac];

  static (EnvelopeHeader, List<int> ciphertextAndMac) splitEnvelope(
    List<int> envelope,
  ) {
    final (EnvelopeHeader header, int consumed) = decodeHeader(envelope);
    return (header, envelope.sublist(consumed));
  }

  static List<int> _uint32be(int v) => (ByteData(4)..setUint32(0, v, Endian.big))
      .buffer
      .asUint8List();

  static List<int> _uint16be(int v) => (ByteData(2)..setUint16(0, v, Endian.big))
      .buffer
      .asUint8List();
}
