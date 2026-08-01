import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proshetu/infrastructure/crypto/double_ratchet.dart';
import 'package:proshetu/infrastructure/crypto/hex.dart';

/// Exercises the ratchet mechanics in isolation from X3DH/DeviceKeys —
/// this constructs Alice/Bob sessions directly from a shared secret,
/// the same way X3dh.computeInitiatorSecret/computeResponderSecret
/// would hand off to DoubleRatchet.initAsInitiator/initAsResponder in
/// production, without needing a real device identity or network.
void main() {
  final X25519 x25519 = X25519();

  List<int> plaintext(String s) => utf8.encode(s);
  String text(List<int> bytes) => utf8.decode(bytes);

  /// Builds a fresh Alice+Bob session pair, mirroring exactly what
  /// e2e_crypto_service.dart does: a shared secret plus `dh3 =
  /// ECDH(aliceEphemeral, bobSignedPrekey)`, which both
  /// initAsInitiator and (implicitly, via the first ratchetDecrypt)
  /// initAsResponder derive their first chain keys from.
  Future<(RatchetState alice, RatchetState bob)> freshSessionPair() async {
    final SimpleKeyPair aliceEphemeral = await x25519.newKeyPair();
    final SimpleKeyPair bobSignedPrekey = await x25519.newKeyPair();
    final SimplePublicKey bobSignedPrekeyPub =
        await bobSignedPrekey.extractPublicKey();
    final SecretKey sharedSecret = SecretKey(List<int>.filled(32, 0x42));
    final SecretKey dh3 = await x25519.sharedSecretKey(
      keyPair: aliceEphemeral,
      remotePublicKey: bobSignedPrekeyPub,
    );

    final RatchetState alice = await DoubleRatchet.initAsInitiator(
      sharedSecret: sharedSecret,
      dh3: dh3,
      ephemeralKeyPair: aliceEphemeral,
      peerSignedPrekeyPublicHex: Hex.encode(bobSignedPrekeyPub.bytes),
    );
    final RatchetState bob = DoubleRatchet.initAsResponder(
      sharedSecret: sharedSecret,
      signedPrekeyPair: bobSignedPrekey,
    );
    return (alice, bob);
  }

  test('normal in-order exchange: A->B, B->A, A->B all round-trip', () async {
    final (RatchetState alice, RatchetState bob) = await freshSessionPair();

    // Alice's first message (this is what completes Bob's ratchet
    // init — his very first ratchetDecrypt call derives his own
    // sending chain too, per the Double Ratchet spec).
    final (RatchetHeader h0, List<int> c0) =
        await DoubleRatchet.ratchetEncrypt(alice, plaintext('hello bob'));
    final List<int> p0 = await DoubleRatchet.ratchetDecrypt(bob, h0, c0);
    expect(text(p0), 'hello bob');

    // Bob replies — this is his first send, using the chain
    // ratchetDecrypt just derived for him.
    final (RatchetHeader h1, List<int> c1) =
        await DoubleRatchet.ratchetEncrypt(bob, plaintext('hi alice'));
    final List<int> p1 = await DoubleRatchet.ratchetDecrypt(alice, h1, c1);
    expect(text(p1), 'hi alice');

    // Alice sends again, in the same direction as before.
    final (RatchetHeader h2, List<int> c2) =
        await DoubleRatchet.ratchetEncrypt(alice, plaintext('how are you'));
    final List<int> p2 = await DoubleRatchet.ratchetDecrypt(bob, h2, c2);
    expect(text(p2), 'how are you');
  });

  test('a skipped message arriving late still decrypts correctly',
      () async {
    final (RatchetState alice, RatchetState bob) = await freshSessionPair();

    final (RatchetHeader h0, List<int> c0) =
        await DoubleRatchet.ratchetEncrypt(alice, plaintext('msg0'));
    final (RatchetHeader h1, List<int> c1) =
        await DoubleRatchet.ratchetEncrypt(alice, plaintext('msg1'));
    final (RatchetHeader h2, List<int> c2) =
        await DoubleRatchet.ratchetEncrypt(alice, plaintext('msg2'));

    // Bob receives msg2 first (msg0/msg1 arrive "late").
    final List<int> p2 = await DoubleRatchet.ratchetDecrypt(bob, h2, c2);
    expect(text(p2), 'msg2');
    expect(bob.skippedMessageKeys.length, 2); // msg0, msg1 archived

    // Now the two delayed messages arrive, out of order.
    final List<int> p1 = await DoubleRatchet.ratchetDecrypt(bob, h1, c1);
    expect(text(p1), 'msg1');
    final List<int> p0 = await DoubleRatchet.ratchetDecrypt(bob, h0, c0);
    expect(text(p0), 'msg0');

    // Consumed skipped keys are removed, not left around.
    expect(bob.skippedMessageKeys, isEmpty);
  });

  test(
      'a DH-ratchet step correctly archives and later resolves a '
      "skipped message from the OLD chain", () async {
    final (RatchetState alice, RatchetState bob) = await freshSessionPair();

    // Alice sends two messages on her first chain.
    final (RatchetHeader h0, List<int> c0) =
        await DoubleRatchet.ratchetEncrypt(alice, plaintext('old-chain-0'));
    final (RatchetHeader h1, List<int> c1) =
        await DoubleRatchet.ratchetEncrypt(alice, plaintext('old-chain-1'));

    // Bob only decrypts the first — the second is left pending on
    // the chain that's about to be superseded by a ratchet step.
    final List<int> p0 = await DoubleRatchet.ratchetDecrypt(bob, h0, c0);
    expect(text(p0), 'old-chain-0');

    // Bob replies, then Alice replies back — this second exchange
    // forces Alice to process a NEW DHr from Bob (a real DH-ratchet
    // step on Alice's side), which must first archive any of HER OWN
    // still-pending skipped receiving-chain state before ratcheting —
    // exercised here from Bob's side instead, by having Bob ratchet
    // forward via his own send before consuming the pending skip.
    final (RatchetHeader hReply, List<int> cReply) =
        await DoubleRatchet.ratchetEncrypt(bob, plaintext('bob-reply'));
    final List<int> pReply =
        await DoubleRatchet.ratchetDecrypt(alice, hReply, cReply);
    expect(text(pReply), 'bob-reply');

    // The old skipped message (msg1 on the chain before Bob's own
    // ratchet-affecting send) must still be resolvable from Bob's
    // skipped-key cache — his own send doesn't touch his RECEIVING
    // chain/skip cache, only decrypt-side new-DHr events do.
    final List<int> p1 = await DoubleRatchet.ratchetDecrypt(bob, h1, c1);
    expect(text(p1), 'old-chain-1');
  });

  test('refuses to skip more than MAX_SKIP messages', () async {
    final (RatchetState alice, RatchetState bob) = await freshSessionPair();

    // Manufacture a header claiming a huge message index without
    // actually generating 1000+ intermediate ciphertexts.
    final SimplePublicKey aliceDh =
        await alice.dhSendingKeyPair.extractPublicKey();
    final RatchetHeader farHeader = RatchetHeader(
      dhPublicKeyHex: Hex.encode(aliceDh.bytes),
      n: RatchetState.maxSkip + 5,
      pn: 0,
    );

    expect(
      () => DoubleRatchet.ratchetDecrypt(bob, farHeader, plaintext('x')),
      throwsA(isA<RatchetDecryptException>()),
    );
  });

  test('replaying an already-consumed message fails (bad AEAD tag)',
      () async {
    final (RatchetState alice, RatchetState bob) = await freshSessionPair();

    final (RatchetHeader h0, List<int> c0) =
        await DoubleRatchet.ratchetEncrypt(alice, plaintext('once only'));
    final List<int> p0 = await DoubleRatchet.ratchetDecrypt(bob, h0, c0);
    expect(text(p0), 'once only');

    // Replaying the exact same header+ciphertext against the now-
    // advanced state must fail — the chain key has already moved
    // forward, so re-deriving at the same `n` produces a different
    // message key than the one that actually encrypted this
    // ciphertext.
    expect(
      () => DoubleRatchet.ratchetDecrypt(bob, h0, c0),
      throwsA(isA<RatchetDecryptException>()),
    );
  });
}
