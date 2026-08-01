import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'device_keys.dart';
import 'hex.dart';

/// Persists this device's own prekey PRIVATE material — the gap
/// DirectoryClient.uploadPrekeys() left open (it generates a fresh
/// signed prekey + one-time-prekey pool and hands the keypairs back,
/// but nothing used to save them). Without this, this device could
/// never complete X3DH when a peer starts a session against a bundle
/// it already published to the backend.
///
/// Wrapped at rest via DeviceKeys.deriveDomainKey — unreadable the
/// instant the app locks, same as everything else DeviceKeys backs.
class PrekeyStore {
  PrekeyStore(this._storage);

  final FlutterSecureStorage _storage;
  static const String _key = 'prekey_store_v1';
  static const int _nonceLength = 12;
  static const int _macLength = 16;
  static final X25519 _x25519 = X25519();
  static final Chacha20 _aead = Chacha20.poly1305Aead();

  /// Additive: a signed prekey rotated in by a later uploadPrekeys()
  /// call must still be found here if a peer fetched the OLD bundle
  /// and hasn't messaged yet (this app tolerates multi-day offline
  /// gaps) — never wholesale-replace this map on a new upload.
  Future<void> saveSignedPrekey(SimpleKeyPair keyPair) async {
    final _PrekeyData data = await _read();
    final SimplePublicKey pub = await keyPair.extractPublicKey();
    final List<int> seed = await keyPair.extractPrivateKeyBytes();
    data.signedPrekeys[Hex.encode(pub.bytes)] = Hex.encode(seed);
    await _write(data);
  }

  Future<void> saveOneTimePrekeys(List<SimpleKeyPair> keyPairs) async {
    final _PrekeyData data = await _read();
    for (final SimpleKeyPair kp in keyPairs) {
      final SimplePublicKey pub = await kp.extractPublicKey();
      final List<int> seed = await kp.extractPrivateKeyBytes();
      data.oneTimePrekeys[Hex.encode(pub.bytes)] = Hex.encode(seed);
    }
    await _write(data);
  }

  Future<SimpleKeyPair?> findSignedPrekey(String publicHex) async {
    final _PrekeyData data = await _read();
    final String? seedHex = data.signedPrekeys[publicHex];
    if (seedHex == null) return null;
    return _x25519.newKeyPairFromSeed(Hex.decode(seedHex));
  }

  /// Removes the one-time prekey after returning it — single-use,
  /// forward-secrecy hygiene (matches the server popping it too).
  Future<SimpleKeyPair?> takeOneTimePrekey(String publicHex) async {
    final _PrekeyData data = await _read();
    final String? seedHex = data.oneTimePrekeys.remove(publicHex);
    if (seedHex == null) return null;
    await _write(data);
    return _x25519.newKeyPairFromSeed(Hex.decode(seedHex));
  }

  /// Wipes this device's stored prekey private halves. Used only by
  /// account recovery (auth_repository_impl.dart) — encrypted under
  /// the old domain key, so undecryptable once a fresh keypair
  /// replaces it; a fresh bundle is uploaded right after recovery
  /// completes anyway.
  Future<void> clearAll() => _storage.delete(key: _key);

  Future<_PrekeyData> _read() async {
    final String? raw = await _storage.read(key: _key);
    if (raw == null) return _PrekeyData({}, {});
    try {
      final SecretKey key = await DeviceKeys.deriveDomainKey('prekeys_v1');
      final SecretBox box = SecretBox.fromConcatenation(
        Hex.decode(raw),
        nonceLength: _nonceLength,
        macLength: _macLength,
      );
      final List<int> plain = await _aead.decrypt(box, secretKey: key);
      final Map<String, dynamic> json =
          jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
      return _PrekeyData(
        Map<String, String>.from(json['signed'] as Map),
        Map<String, String>.from(json['oneTime'] as Map),
      );
    } catch (_) {
      return _PrekeyData({}, {});
    }
  }

  Future<void> _write(_PrekeyData data) async {
    final SecretKey key = await DeviceKeys.deriveDomainKey('prekeys_v1');
    final List<int> plain = utf8.encode(jsonEncode(<String, dynamic>{
      'signed': data.signedPrekeys,
      'oneTime': data.oneTimePrekeys,
    }));
    final SecretBox box = await _aead.encrypt(plain, secretKey: key);
    await _storage.write(key: _key, value: Hex.encode(box.concatenation()));
  }
}

class _PrekeyData {
  _PrekeyData(this.signedPrekeys, this.oneTimePrekeys);
  final Map<String, String> signedPrekeys;
  final Map<String, String> oneTimePrekeys;
}
