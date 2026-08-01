import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'hex.dart';

/// Header accompanying each ratchet-encrypted message: which DH-ratchet
/// public key the sender was using, and where in its sending chain
/// this message falls. This is the minimal ratchet-level header (the
/// full wire envelope in message_envelope.dart adds a version/type
/// prefix, and for INITIAL messages, X3DH identity fields, around it).
class RatchetHeader {
  const RatchetHeader({
    required this.dhPublicKeyHex,
    required this.n,
    required this.pn,
  });

  final String dhPublicKeyHex;
  final int n; // Ns (sender) / Nr (receiver), depending on direction
  final int pn; // sender's previous sending-chain length

  /// Default AAD encoding: 32-byte raw dh pubkey + 4-byte BE n + 4-byte
  /// BE pn = 40 bytes. Callers building the full wire envelope (which
  /// adds a version/msg_type prefix, and INITIAL-only identity fields)
  /// should pass their own `aad` callback to [DoubleRatchet.ratchetEncrypt]
  /// / [DoubleRatchet.ratchetDecrypt] instead of relying on this.
  List<int> toBytes() {
    final ByteData ints = ByteData(8)
      ..setUint32(0, n, Endian.big)
      ..setUint32(4, pn, Endian.big);
    return <int>[...Hex.decode(dhPublicKeyHex), ...ints.buffer.asUint8List()];
  }
}

/// Mutable Double Ratchet session state for one contact. Persisted
/// between messages via SessionStore (session_store.dart) — nothing
/// in this file touches storage itself.
class RatchetState {
  RatchetState({
    required this.dhSendingKeyPair,
    this.dhReceivingPublicKeyHex,
    required this.rootKey,
    this.sendingChainKey,
    this.receivingChainKey,
    this.sendingMessageNumber = 0,
    this.receivingMessageNumber = 0,
    this.previousSendingChainLength = 0,
    Map<String, SecretKey>? skippedMessageKeys,
  }) : skippedMessageKeys = skippedMessageKeys ?? <String, SecretKey>{};

  SimpleKeyPair dhSendingKeyPair;
  String? dhReceivingPublicKeyHex;
  SecretKey rootKey;
  SecretKey? sendingChainKey;
  SecretKey? receivingChainKey;
  int sendingMessageNumber;
  int receivingMessageNumber;
  int previousSendingChainLength;

  /// Keyed by "<dhPublicKeyHex>:<n>" — message keys for messages that
  /// arrive out of order, held until consumed or evicted once
  /// [maxSkip] is exceeded (bounds both memory and the CPU cost of a
  /// malicious/corrupted `n`).
  final Map<String, SecretKey> skippedMessageKeys;

  static const int maxSkip = 1000;
}

/// Thrown when a message can't be decrypted — either it's corrupt/
/// forged (AEAD tag mismatch), or its `n` implies skipping more than
/// [RatchetState.maxSkip] messages (bounds a malicious/corrupted `n`
/// from forcing unbounded work).
class RatchetDecryptException implements Exception {
  RatchetDecryptException(this.message);
  final String message;

  @override
  String toString() => 'RatchetDecryptException: $message';
}

abstract final class DoubleRatchet {
  static final X25519 _x25519 = X25519();
  static final Chacha20 _aead = Chacha20.poly1305Aead();

  /// Alice's (initiator's) session init. Reuses her X3DH ephemeral
  /// keypair as the first DH-ratchet sending key, and `dh3` (already
  /// computed during X3DH — `ECDH(ephemeral, peerSignedPrekey)`) to
  /// derive the first sending chain immediately, since Alice must be
  /// able to send message 0 right after this call.
  static Future<RatchetState> initAsInitiator({
    required SecretKey sharedSecret,
    required SecretKey dh3,
    required SimpleKeyPair ephemeralKeyPair,
    required String peerSignedPrekeyPublicHex,
  }) async {
    final (SecretKey rk, SecretKey cks) = await _kdfRk(sharedSecret, dh3);
    return RatchetState(
      dhSendingKeyPair: ephemeralKeyPair,
      dhReceivingPublicKeyHex: peerSignedPrekeyPublicHex,
      rootKey: rk,
      sendingChainKey: cks,
    );
  }

  /// Bob's (responder's) session init — deliberately minimal. Bob's
  /// signed-prekey keypair is reused as the initial `dhSendingKeyPair`
  /// (never again as a ratchet key once he next generates a fresh one
  /// — see the DH-ratchet step in [ratchetDecrypt]), `dhReceivingPublicKeyHex`
  /// stays null, and no chain keys are derived here: the first call
  /// to [ratchetDecrypt] against this state will see a "new" DH value
  /// (Alice's ephemeral, vs. this state's null) and run the standard
  /// DH-ratchet step, which derives BOTH the receiving chain (to
  /// decrypt Alice's first message) AND — per the Double Ratchet spec
  /// — Bob's own first sending chain, in that same step. No special
  /// casing needed here for that.
  static RatchetState initAsResponder({
    required SecretKey sharedSecret,
    required SimpleKeyPair signedPrekeyPair,
  }) {
    return RatchetState(dhSendingKeyPair: signedPrekeyPair, rootKey: sharedSecret);
  }

  /// Encrypts [plaintext], advancing the sending chain by one message.
  /// [associatedData] lets the caller bind the AEAD to the full wire
  /// envelope header (recommended) rather than just the bare ratchet
  /// header; defaults to [RatchetHeader.toBytes] if omitted (used by
  /// this file's own unit tests).
  static Future<(RatchetHeader, List<int>)> ratchetEncrypt(
    RatchetState state,
    List<int> plaintext, {
    List<int> Function(RatchetHeader header)? associatedData,
  }) async {
    final SecretKey? cks = state.sendingChainKey;
    if (cks == null) {
      throw StateError(
        'No sending chain yet — a responder session must decrypt the '
        "initiator's first message before it has anything to send.",
      );
    }
    final (SecretKey nextCks, SecretKey messageKey) = await _kdfCk(cks);
    state.sendingChainKey = nextCks;

    final SimplePublicKey dhsPublic =
        await state.dhSendingKeyPair.extractPublicKey();
    final RatchetHeader header = RatchetHeader(
      dhPublicKeyHex: Hex.encode(dhsPublic.bytes),
      n: state.sendingMessageNumber,
      pn: state.previousSendingChainLength,
    );
    state.sendingMessageNumber += 1;

    final List<int> aad =
        associatedData != null ? associatedData(header) : header.toBytes();
    final List<int> ciphertext =
        await _encryptWithMessageKey(messageKey, plaintext, aad);
    return (header, ciphertext);
  }

  /// Decrypts a message given its [header], advancing/ratcheting state
  /// as needed. Throws [RatchetDecryptException] on a bad AEAD tag or
  /// an [header.n] implying more than [RatchetState.maxSkip] skipped
  /// messages.
  static Future<List<int>> ratchetDecrypt(
    RatchetState state,
    RatchetHeader header,
    List<int> ciphertext, {
    List<int> Function(RatchetHeader header)? associatedData,
  }) async {
    final List<int> aad =
        associatedData != null ? associatedData(header) : header.toBytes();

    // 1. Try an already-cached skipped key first (out-of-order delivery).
    final String skipKey = '${header.dhPublicKeyHex}:${header.n}';
    final SecretKey? skipped = state.skippedMessageKeys[skipKey];
    if (skipped != null) {
      state.skippedMessageKeys.remove(skipKey);
      return _decryptWithMessageKey(skipped, ciphertext, aad);
    }

    // 2. New DH-ratchet key on the wire? Archive skipped keys from the
    //    OLD receiving chain up to header.pn, then ratchet.
    if (header.dhPublicKeyHex != state.dhReceivingPublicKeyHex) {
      await _skipMessageKeys(state, header.pn);
      await _dhRatchetStep(state, header.dhPublicKeyHex);
    }

    // 3. Archive any skipped keys on the (possibly just-ratcheted)
    //    current receiving chain up to header.n, then derive this
    //    message's key.
    await _skipMessageKeys(state, header.n);
    final SecretKey? ckr = state.receivingChainKey;
    if (ckr == null) {
      throw RatchetDecryptException('No receiving chain established');
    }
    final (SecretKey nextCkr, SecretKey messageKey) = await _kdfCk(ckr);
    state.receivingChainKey = nextCkr;
    state.receivingMessageNumber = header.n + 1;

    return _decryptWithMessageKey(messageKey, ciphertext, aad);
  }

  /// Archives message keys for chain positions [state.receivingMessageNumber, until)
  /// into [RatchetState.skippedMessageKeys], so a message that arrives
  /// out of order (or after a multi-day gap — this app's `/v1/sync`
  /// TTLs run up to 7 days) can still be decrypted later.
  static Future<void> _skipMessageKeys(RatchetState state, int until) async {
    if (state.receivingMessageNumber + RatchetState.maxSkip < until) {
      throw RatchetDecryptException(
        'Refusing to skip more than ${RatchetState.maxSkip} messages',
      );
    }
    final SecretKey? ckr = state.receivingChainKey;
    if (ckr == null) return;
    SecretKey chain = ckr;
    final String? dhr = state.dhReceivingPublicKeyHex;
    while (state.receivingMessageNumber < until) {
      final (SecretKey nextChain, SecretKey messageKey) = await _kdfCk(chain);
      state.skippedMessageKeys['$dhr:${state.receivingMessageNumber}'] =
          messageKey;
      chain = nextChain;
      state.receivingMessageNumber += 1;
    }
    state.receivingChainKey = chain;
  }

  /// The standard Double Ratchet DH-ratchet step: derives the new
  /// receiving chain from the OLD sending keypair against the NEW
  /// peer public key, then immediately generates a fresh sending
  /// keypair and derives a new sending chain against that same peer
  /// key — both chains rotate together on every ratchet step, per the
  /// spec (not deferred to whenever the caller next wants to send).
  static Future<void> _dhRatchetStep(
    RatchetState state,
    String newDhReceivingPublicHex,
  ) async {
    state.previousSendingChainLength = state.sendingMessageNumber;
    state.sendingMessageNumber = 0;
    state.receivingMessageNumber = 0;
    state.dhReceivingPublicKeyHex = newDhReceivingPublicHex;

    final SecretKey dhOutRecv = await _x25519.sharedSecretKey(
      keyPair: state.dhSendingKeyPair,
      remotePublicKey: SimplePublicKey(
        Hex.decode(newDhReceivingPublicHex),
        type: KeyPairType.x25519,
      ),
    );
    final (SecretKey rk1, SecretKey ckr) = await _kdfRk(state.rootKey, dhOutRecv);

    final SimpleKeyPair newSendingKeyPair = await _x25519.newKeyPair();
    final SecretKey dhOutSend = await _x25519.sharedSecretKey(
      keyPair: newSendingKeyPair,
      remotePublicKey: SimplePublicKey(
        Hex.decode(newDhReceivingPublicHex),
        type: KeyPairType.x25519,
      ),
    );
    final (SecretKey rk2, SecretKey cks) = await _kdfRk(rk1, dhOutSend);

    state.dhSendingKeyPair = newSendingKeyPair;
    state.rootKey = rk2;
    state.receivingChainKey = ckr;
    state.sendingChainKey = cks;
  }

  static Future<(SecretKey, SecretKey)> _kdfRk(
    SecretKey rootKey,
    SecretKey dhOutput,
  ) async {
    final List<int> ikm = await dhOutput.extractBytes();
    final List<int> salt = await rootKey.extractBytes();
    final SecretKeyData out = await Hkdf(hmac: Hmac.sha256(), outputLength: 64)
        .deriveKey(
      secretKey: SecretKey(ikm),
      nonce: salt,
      info: utf8.encode('ProShetuDR-root-v1'),
    );
    final List<int> bytes = await out.extractBytes();
    return (SecretKey(bytes.sublist(0, 32)), SecretKey(bytes.sublist(32, 64)));
  }

  static Future<(SecretKey, SecretKey)> _kdfCk(SecretKey chainKey) async {
    final Mac messageKeyMac =
        await Hmac.sha256().calculateMac(<int>[0x01], secretKey: chainKey);
    final Mac nextChainMac =
        await Hmac.sha256().calculateMac(<int>[0x02], secretKey: chainKey);
    return (SecretKey(nextChainMac.bytes), SecretKey(messageKeyMac.bytes));
  }

  static Future<(SecretKey, List<int>)> _expandMessageKey(
    SecretKey messageKey,
  ) async {
    final SecretKeyData expanded = await Hkdf(
      hmac: Hmac.sha256(),
      outputLength: 44,
    ).deriveKey(secretKey: messageKey, info: utf8.encode('ProShetuDR-msgkey-v1'));
    final List<int> bytes = await expanded.extractBytes();
    return (SecretKey(bytes.sublist(0, 32)), bytes.sublist(32, 44));
  }

  static Future<List<int>> _encryptWithMessageKey(
    SecretKey messageKey,
    List<int> plaintext,
    List<int> aad,
  ) async {
    final (SecretKey aeadKey, List<int> nonce) =
        await _expandMessageKey(messageKey);
    final SecretBox box = await _aead.encrypt(
      plaintext,
      secretKey: aeadKey,
      nonce: nonce,
      aad: aad,
    );
    return <int>[...box.cipherText, ...box.mac.bytes];
  }

  static Future<List<int>> _decryptWithMessageKey(
    SecretKey messageKey,
    List<int> ciphertextAndMac,
    List<int> aad,
  ) async {
    if (ciphertextAndMac.length < 16) {
      throw RatchetDecryptException('Ciphertext too short to contain a MAC');
    }
    final (SecretKey aeadKey, List<int> nonce) =
        await _expandMessageKey(messageKey);
    final int split = ciphertextAndMac.length - 16;
    final SecretBox box = SecretBox(
      ciphertextAndMac.sublist(0, split),
      nonce: nonce,
      mac: Mac(ciphertextAndMac.sublist(split)),
    );
    try {
      return await _aead.decrypt(box, secretKey: aeadKey, aad: aad);
    } on SecretBoxAuthenticationError {
      throw RatchetDecryptException('AEAD authentication failed');
    }
  }
}
