import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'device_keys.dart';
import 'double_ratchet.dart';
import 'hex.dart';

/// Persists per-contact Double Ratchet session state between
/// messages — without this, every app restart would lose the ratchet
/// and force a brand-new X3DH session (defeating forward secrecy's
/// point, and confusing the peer with a fresh INITIAL message every
/// time).
class SessionStore {
  SessionStore(this._storage);

  final FlutterSecureStorage _storage;
  static const int _nonceLength = 12;
  static const int _macLength = 16;
  static final X25519 _x25519 = X25519();
  static final Chacha20 _aead = Chacha20.poly1305Aead();

  String _keyFor(String peerMailboxId) => 'dr_session_v1_$peerMailboxId';

  Future<void> save(String peerMailboxId, RatchetState state) async {
    final SecretKey key = await DeviceKeys.deriveDomainKey('sessions_v1');
    final List<int> plain = utf8.encode(jsonEncode(await _toJson(state)));
    final SecretBox box = await _aead.encrypt(plain, secretKey: key);
    await _storage.write(
      key: _keyFor(peerMailboxId),
      value: Hex.encode(box.concatenation()),
    );
  }

  Future<RatchetState?> load(String peerMailboxId) async {
    final String? raw = await _storage.read(key: _keyFor(peerMailboxId));
    if (raw == null) return null;
    try {
      final SecretKey key = await DeviceKeys.deriveDomainKey('sessions_v1');
      final SecretBox box = SecretBox.fromConcatenation(
        Hex.decode(raw),
        nonceLength: _nonceLength,
        macLength: _macLength,
      );
      final List<int> plain = await _aead.decrypt(box, secretKey: key);
      final Map<String, dynamic> json =
          jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
      return await _fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> delete(String peerMailboxId) =>
      _storage.delete(key: _keyFor(peerMailboxId));

  /// Wipes every stored session. Used only by account recovery
  /// (auth_repository_impl.dart) — a fresh device keypair means these
  /// ratchet states are both undecryptable (wrapped under the old
  /// domain key) and stale (they authenticated the old identity key),
  /// so peers will need a brand-new X3DH handshake regardless.
  Future<void> clearAll() async {
    final Map<String, String> all = await _storage.readAll();
    for (final String key in all.keys) {
      if (key.startsWith('dr_session_v1_')) {
        await _storage.delete(key: key);
      }
    }
  }

  Future<Map<String, dynamic>> _toJson(RatchetState s) async {
    final Map<String, String> skipped = {};
    for (final MapEntry<String, SecretKey> entry
        in s.skippedMessageKeys.entries) {
      skipped[entry.key] = Hex.encode(await entry.value.extractBytes());
    }
    return <String, dynamic>{
      'dhSendSeed':
          Hex.encode(await s.dhSendingKeyPair.extractPrivateKeyBytes()),
      'dhRecvPub': s.dhReceivingPublicKeyHex,
      'rootKey': Hex.encode(await s.rootKey.extractBytes()),
      'sendChain': s.sendingChainKey == null
          ? null
          : Hex.encode(await s.sendingChainKey!.extractBytes()),
      'recvChain': s.receivingChainKey == null
          ? null
          : Hex.encode(await s.receivingChainKey!.extractBytes()),
      'ns': s.sendingMessageNumber,
      'nr': s.receivingMessageNumber,
      'pn': s.previousSendingChainLength,
      'skipped': skipped,
    };
  }

  Future<RatchetState> _fromJson(Map<String, dynamic> json) async {
    final Map<String, dynamic> skippedJson =
        Map<String, dynamic>.from(json['skipped'] as Map);
    final Map<String, SecretKey> skipped = {
      for (final MapEntry<String, dynamic> e in skippedJson.entries)
        e.key: SecretKey(Hex.decode(e.value as String)),
    };
    return RatchetState(
      dhSendingKeyPair: await _x25519
          .newKeyPairFromSeed(Hex.decode(json['dhSendSeed'] as String)),
      dhReceivingPublicKeyHex: json['dhRecvPub'] as String?,
      rootKey: SecretKey(Hex.decode(json['rootKey'] as String)),
      sendingChainKey: json['sendChain'] == null
          ? null
          : SecretKey(Hex.decode(json['sendChain'] as String)),
      receivingChainKey: json['recvChain'] == null
          ? null
          : SecretKey(Hex.decode(json['recvChain'] as String)),
      sendingMessageNumber: json['ns'] as int,
      receivingMessageNumber: json['nr'] as int,
      previousSendingChainLength: json['pn'] as int,
      skippedMessageKeys: skipped,
    );
  }
}
