import 'package:cryptography/cryptography.dart';

import '../../core/error/failure.dart';
import '../../core/utils/result.dart';
import '../../features/onboarding/data/directory_client.dart';
import '../storage/contact_directory_store.dart';
import 'device_keys.dart';
import 'double_ratchet.dart';
import 'hex.dart';
import 'message_envelope.dart';
import 'prekey_store.dart';
import 'session_store.dart';
import 'x3dh.dart';

/// Real implementation of the two 1:1-messaging functions
/// e2e_placeholder.dart used to throw on. Orchestrates X3DH session
/// bootstrap, the Double Ratchet, and the wire envelope over
/// DirectoryClient/ContactDirectoryStore/PrekeyStore/SessionStore.
///
/// Instantiable (not a bare static class like DeviceKeys/ContentId)
/// because it genuinely needs these injected collaborators — a
/// deliberate departure from the placeholder's static-class shape.
///
/// `encryptForRecipient`/`decryptFromSender` keep their exact
/// original signatures so lib/features/voice/presentation/controllers/
/// call_controller.dart's two call sites (out of scope for this
/// change) keep compiling — see that file for the small follow-up it
/// still needs (it currently discards decryptFromSender's return
/// value entirely).
class E2eCryptoService {
  E2eCryptoService(this._directory, this._contacts, this._prekeys, this._sessions);

  final DirectoryClient _directory;
  final ContactDirectoryStore _contacts;
  final PrekeyStore _prekeys;
  final SessionStore _sessions;

  /// Encrypts [plaintext] for [recipientMailboxId]. Reuses an
  /// existing Double Ratchet session if one exists; otherwise fetches
  /// the recipient's prekey bundle and bootstraps a new one via X3DH.
  Future<List<int>> encryptForRecipient({
    required String recipientMailboxId,
    required List<int> plaintext,
  }) async {
    final RatchetState? existing = await _sessions.load(recipientMailboxId);
    if (existing != null) {
      final (RatchetHeader rh, List<int> ciphertextAndMac) =
          await DoubleRatchet.ratchetEncrypt(
        existing,
        MessageEnvelope.padPlaintext(0x01, plaintext),
        associatedData: (RatchetHeader h) => MessageEnvelope.encodeHeader(
          EnvelopeHeader(
            msgType: EnvelopeMessageType.continuing,
            ns: h.n,
            pn: h.pn,
            ratchetPubHex: h.dhPublicKeyHex,
          ),
        ),
      );
      await _sessions.save(recipientMailboxId, existing);
      return MessageEnvelope.buildEnvelope(
        EnvelopeHeader(
          msgType: EnvelopeMessageType.continuing,
          ns: rh.n,
          pn: rh.pn,
          ratchetPubHex: rh.dhPublicKeyHex,
        ),
        ciphertextAndMac,
      );
    }

    // No session yet — bootstrap via X3DH against the recipient's
    // fetched prekey bundle.
    final Result<Failure, PreKeyBundle> bundleResult =
        await _directory.fetchPrekeys(recipientMailboxId);
    final PreKeyBundle bundle = bundleResult.fold(
      (Failure f) => throw StateError(
        'Could not fetch prekey bundle for $recipientMailboxId: ${f.message}',
      ),
      (PreKeyBundle b) => b,
    );

    final bool sigOk = await X3dh.verifySignedPrekey(
      peerEd25519PublicHex: bundle.ed25519Pub,
      signedPrekeyHex: bundle.signedPrekey,
      signatureHex: bundle.signedPrekeySig,
    );
    if (!sigOk) {
      throw StateError(
        'Signed-prekey signature verification failed for '
        '$recipientMailboxId — refusing to start a session',
      );
    }

    final X3dhInitiatorResult x3dh = await X3dh.computeInitiatorSecret(
      peerX25519IdentityPublicHex: bundle.x25519Pub,
      peerSignedPrekeyPublicHex: bundle.signedPrekey,
      peerOneTimePrekeyPublicHex: bundle.oneTimePrekey,
    );

    final RatchetState state = await DoubleRatchet.initAsInitiator(
      sharedSecret: x3dh.sharedSecret,
      dh3: x3dh.dh3,
      ephemeralKeyPair: x3dh.ephemeralKeyPair,
      peerSignedPrekeyPublicHex: bundle.signedPrekey,
    );

    final String myIkX = await DeviceKeys.x25519PublicHex();
    final String myIkEd = await DeviceKeys.ed25519PublicHex();
    final String? usedOtk =
        x3dh.usedOneTimePrekey ? bundle.oneTimePrekey : null;

    final (RatchetHeader rh, List<int> ciphertextAndMac) =
        await DoubleRatchet.ratchetEncrypt(
      state,
      MessageEnvelope.padPlaintext(0x01, plaintext),
      associatedData: (RatchetHeader h) => MessageEnvelope.encodeHeader(
        EnvelopeHeader(
          msgType: EnvelopeMessageType.initial,
          ns: h.n,
          pn: h.pn,
          ratchetPubHex: h.dhPublicKeyHex,
          initiatorIkXPubHex: myIkX,
          initiatorIkEdPubHex: myIkEd,
          usedSignedPrekeyPubHex: bundle.signedPrekey,
          usedOneTimePrekeyPubHex: usedOtk,
        ),
      ),
    );
    await _sessions.save(recipientMailboxId, state);

    return MessageEnvelope.buildEnvelope(
      EnvelopeHeader(
        msgType: EnvelopeMessageType.initial,
        ns: rh.n,
        pn: rh.pn,
        ratchetPubHex: rh.dhPublicKeyHex,
        initiatorIkXPubHex: myIkX,
        initiatorIkEdPubHex: myIkEd,
        usedSignedPrekeyPubHex: bundle.signedPrekey,
        usedOneTimePrekeyPubHex: usedOtk,
      ),
      ciphertextAndMac,
    );
  }

  /// Decrypts an envelope delivered from the sync fabric. Returns
  /// `[0x01, ...16-byte mailbox_id, ...plaintext]` — the sender
  /// identity is resolved structurally (never transmitted on the
  /// wire for CONTINUING messages — see the plan's sealed-sender
  /// design notes) and prefixed locally, matching the original
  /// placeholder's doc comment: "plaintext and the sealed sender
  /// identity it contains."
  Future<List<int>> decryptFromSender(List<int> ciphertext) async {
    final (EnvelopeHeader header, List<int> aeadBytes) =
        MessageEnvelope.splitEnvelope(ciphertext);
    final List<int> aad = MessageEnvelope.encodeHeader(header);

    if (header.msgType == EnvelopeMessageType.initial) {
      return _decryptInitial(header, aeadBytes, aad);
    }
    return _decryptContinuing(header, aeadBytes, aad);
  }

  Future<List<int>> _decryptInitial(
    EnvelopeHeader header,
    List<int> aeadBytes,
    List<int> aad,
  ) async {
    // No "message request from a stranger" UI exists in this app —
    // an INITIAL message from an identity we haven't paired with (QR
    // pairing pins the sender's keys) is dropped rather than
    // inventing one; see the plan's disclosed scope decision.
    final DirectoryContact? contact =
        await _contacts.byX25519Pub(header.initiatorIkXPubHex!);
    if (contact == null) {
      throw StateError(
        'INITIAL message from an unrecognized identity — dropping',
      );
    }

    final SimpleKeyPair? maybeSignedPrekeyPair =
        await _prekeys.findSignedPrekey(header.usedSignedPrekeyPubHex!);
    if (maybeSignedPrekeyPair == null) {
      throw StateError(
        'No matching signed prekey on file — cannot complete session',
      );
    }
    final SimpleKeyPair signedPrekeyPair = maybeSignedPrekeyPair;
    final SimpleKeyPair? otkPair = header.usedOneTimePrekeyPubHex != null
        ? await _prekeys.takeOneTimePrekey(header.usedOneTimePrekeyPubHex!)
        : null;

    final SecretKey sk = await X3dh.computeResponderSecret(
      initiatorX25519IdentityPublicHex: header.initiatorIkXPubHex!,
      initiatorEphemeralPublicHex: header.ratchetPubHex,
      ourSignedPrekeyPair: signedPrekeyPair,
      ourOneTimePrekeyPair: otkPair,
    );

    final RatchetState state = DoubleRatchet.initAsResponder(
      sharedSecret: sk,
      signedPrekeyPair: signedPrekeyPair,
    );
    final List<int> padded = await DoubleRatchet.ratchetDecrypt(
      state,
      header.ratchetHeader,
      aeadBytes,
      associatedData: (_) => aad,
    );
    await _sessions.save(contact.mailboxId, state);

    final (int _, List<int> content) = MessageEnvelope.unpadPlaintext(padded);
    return <int>[0x01, ..._uuidToBytes(contact.mailboxId), ...content];
  }

  Future<List<int>> _decryptContinuing(
    EnvelopeHeader header,
    List<int> aeadBytes,
    List<int> aad,
  ) async {
    for (final DirectoryContact contact in await _contacts.all()) {
      final RatchetState? state = await _sessions.load(contact.mailboxId);
      if (state == null) continue;
      try {
        final List<int> padded = await DoubleRatchet.ratchetDecrypt(
          state,
          header.ratchetHeader,
          aeadBytes,
          associatedData: (_) => aad,
        );
        await _sessions.save(contact.mailboxId, state);
        final (int _, List<int> content) =
            MessageEnvelope.unpadPlaintext(padded);
        return <int>[0x01, ..._uuidToBytes(contact.mailboxId), ...content];
      } on RatchetDecryptException {
        continue;
      }
    }
    throw StateError('No matching session found for this message');
  }

  static List<int> _uuidToBytes(String uuid) =>
      Hex.decode(uuid.replaceAll('-', ''));
}
