import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'device_keys.dart';
import 'hex.dart';

/// X3DH (Extended Triple Diffie-Hellman) — derives the shared secret
/// that bootstraps a Double Ratchet session. Pure/stateless: callers
/// supply whatever prekey material is needed (fetched from the
/// backend, or read from PrekeyStore for the responder side); this
/// module never touches storage or the network itself.
abstract final class X3dh {
  static final X25519 _x25519 = X25519();
  static final Ed25519 _ed25519 = Ed25519();

  /// Verifies a peer's signed-prekey signature — the ONLY
  /// authentication of bundle provenance. Must be checked and must
  /// return true before [computeInitiatorSecret] is ever called with
  /// that bundle.
  static Future<bool> verifySignedPrekey({
    required String peerEd25519PublicHex,
    required String signedPrekeyHex,
    required String signatureHex,
  }) async {
    try {
      return await _ed25519.verify(
        signedPrekeyHex.codeUnits,
        signature: Signature(
          Hex.decode(signatureHex),
          publicKey: SimplePublicKey(
            Hex.decode(peerEd25519PublicHex),
            type: KeyPairType.ed25519,
          ),
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// Initiator (Alice) side: bootstraps a new session against a
  /// peer's fetched prekey bundle. Returns the X3DH secret, the fresh
  /// ephemeral keypair (its public half goes in the INITIAL
  /// envelope's `ratchet_pub`, and the Double Ratchet reuses this
  /// same keypair as its first sending-chain key — see
  /// double_ratchet.dart), and whether a one-time prekey was used.
  static Future<X3dhInitiatorResult> computeInitiatorSecret({
    required String peerX25519IdentityPublicHex,
    required String peerSignedPrekeyPublicHex,
    String? peerOneTimePrekeyPublicHex,
  }) async {
    final SimpleKeyPair ephemeral = await _x25519.newKeyPair();
    final SimplePublicKey ephemeralPublic = await ephemeral.extractPublicKey();

    // DH1 uses OUR long-term identity key — routed through
    // DeviceKeys.agree so the private scalar never leaves that class.
    final SecretKey dh1 = await DeviceKeys.agree(
      remoteX25519PublicHex: peerSignedPrekeyPublicHex,
    );
    // DH2/DH3/DH4 all use the fresh ephemeral keypair above (not the
    // device's persistent identity) — computed directly.
    final SecretKey dh2 = await _x25519.sharedSecretKey(
      keyPair: ephemeral,
      remotePublicKey: SimplePublicKey(
        Hex.decode(peerX25519IdentityPublicHex),
        type: KeyPairType.x25519,
      ),
    );
    final SecretKey dh3 = await _x25519.sharedSecretKey(
      keyPair: ephemeral,
      remotePublicKey: SimplePublicKey(
        Hex.decode(peerSignedPrekeyPublicHex),
        type: KeyPairType.x25519,
      ),
    );
    SecretKey? dh4;
    if (peerOneTimePrekeyPublicHex != null) {
      dh4 = await _x25519.sharedSecretKey(
        keyPair: ephemeral,
        remotePublicKey: SimplePublicKey(
          Hex.decode(peerOneTimePrekeyPublicHex),
          type: KeyPairType.x25519,
        ),
      );
    }

    final SecretKey sk =
        await _deriveSk(<SecretKey>[dh1, dh2, dh3, if (dh4 != null) dh4]);
    return X3dhInitiatorResult(
      sharedSecret: sk,
      dh3: dh3,
      ephemeralKeyPair: ephemeral,
      ephemeralPublicHex: Hex.encode(ephemeralPublic.bytes),
      usedOneTimePrekey: dh4 != null,
    );
  }

  /// Responder (Bob) side: mirrors the above using his own
  /// signed-prekey (and, if the INITIAL envelope says one was
  /// consumed, one-time-prekey) KEYPAIRS. These are prekey material,
  /// not the device's long-term identity, so they're passed in
  /// directly (from PrekeyStore) rather than routed through
  /// DeviceKeys — only the DH that uses our own identity key goes
  /// through DeviceKeys.agree.
  ///
  /// Unlike the initiator side, this doesn't need to expose `dh3`:
  /// double_ratchet.dart's `initAsResponder` leaves the receiving
  /// chain undeferred to the first `ratchetDecrypt` call, whose
  /// generic "new DH-ratchet key encountered" path recomputes the
  /// identical DH(signedPrekeyPair, initiatorEphemeral) value on its
  /// own — no special-cased pre-derivation needed for the responder.
  static Future<SecretKey> computeResponderSecret({
    required String initiatorX25519IdentityPublicHex,
    required String initiatorEphemeralPublicHex,
    required SimpleKeyPair ourSignedPrekeyPair,
    SimpleKeyPair? ourOneTimePrekeyPair,
  }) async {
    final SecretKey dh1 = await _x25519.sharedSecretKey(
      keyPair: ourSignedPrekeyPair,
      remotePublicKey: SimplePublicKey(
        Hex.decode(initiatorX25519IdentityPublicHex),
        type: KeyPairType.x25519,
      ),
    );
    final SecretKey dh2 = await DeviceKeys.agree(
      remoteX25519PublicHex: initiatorEphemeralPublicHex,
    );
    final SecretKey dh3 = await _x25519.sharedSecretKey(
      keyPair: ourSignedPrekeyPair,
      remotePublicKey: SimplePublicKey(
        Hex.decode(initiatorEphemeralPublicHex),
        type: KeyPairType.x25519,
      ),
    );
    SecretKey? dh4;
    if (ourOneTimePrekeyPair != null) {
      dh4 = await _x25519.sharedSecretKey(
        keyPair: ourOneTimePrekeyPair,
        remotePublicKey: SimplePublicKey(
          Hex.decode(initiatorEphemeralPublicHex),
          type: KeyPairType.x25519,
        ),
      );
    }
    return _deriveSk(<SecretKey>[dh1, dh2, dh3, if (dh4 != null) dh4]);
  }

  static Future<SecretKey> _deriveSk(List<SecretKey> dhOutputs) async {
    final BytesBuilder ikm = BytesBuilder()..add(List<int>.filled(32, 0xFF));
    for (final SecretKey dh in dhOutputs) {
      ikm.add(await dh.extractBytes());
    }
    return Hkdf(hmac: Hmac.sha256(), outputLength: 32).deriveKey(
      secretKey: SecretKey(ikm.toBytes()),
      nonce: Uint8List(32), // 32 zero bytes, per the X3DH construction
      info: utf8.encode('ProShetuX3DH-v1'),
    );
  }
}

/// Result of [X3dh.computeInitiatorSecret] — bundles the shared
/// secret with the fresh ephemeral keypair the caller needs to seed
/// the Double Ratchet and to embed in the INITIAL envelope. [dh3]
/// (ECDH of the ephemeral against the peer's signed prekey) is
/// exposed so double_ratchet.dart's initAsInitiator can reuse it
/// directly rather than recomputing the same ECDH a second time.
class X3dhInitiatorResult {
  const X3dhInitiatorResult({
    required this.sharedSecret,
    required this.dh3,
    required this.ephemeralKeyPair,
    required this.ephemeralPublicHex,
    required this.usedOneTimePrekey,
  });

  final SecretKey sharedSecret;
  final SecretKey dh3;
  final SimpleKeyPair ephemeralKeyPair;
  final String ephemeralPublicHex;
  final bool usedOneTimePrekey;
}
