import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/error/failure.dart';
import '../../core/utils/result.dart';
import 'hex.dart';

/// The device's Ed25519 (signing) + X25519 (key agreement) identity.
///
/// This is the ONLY credential the backend knows: there is no
/// password or session on the server (see apps/common/auth.py). The
/// private key material never leaves the device and is additionally
/// encrypted at rest with a key derived from the user's password/PIN
/// via Argon2id — so even if platform secure-storage were somehow
/// read, the raw private keys aren't recoverable without that
/// password. This wrapping is real, standard, well-specified crypto,
/// same as the sealed-sender payload encryption built on top of it —
/// see e2e_crypto_service.dart.
abstract final class DeviceKeys {
  static const String _wrappedKey = 'device_identity_wrapped_v1';
  static const String _saltKey = 'device_identity_salt_v1';
  static const int _nonceLength = 12; // Chacha20.poly1305Aead nonce size
  static const int _macLength = 16; // Poly1305 tag size

  static final Ed25519 _ed25519 = Ed25519();
  static final X25519 _x25519 = X25519();
  static final Argon2id _kdf = Argon2id(
    memory: 19456, // ~19 MB — OWASP-recommended floor for Argon2id
    parallelism: 1,
    iterations: 2,
    hashLength: 32,
  );
  static final Chacha20 _aead = Chacha20.poly1305Aead();
  static final Random _secureRandom = Random.secure();

  /// Cached in memory only after [unlock]/[createAndUnlock] succeed;
  /// never persisted unwrapped.
  static SimpleKeyPair? _ed25519KeyPair;
  static SimpleKeyPair? _x25519KeyPair;

  /// Derived from the wrap key (one more HKDF step) alongside the
  /// keypairs above — never persisted, cleared in [lock]. Backs
  /// [deriveDomainKey] so PrekeyStore/SessionStore/MessageStore each
  /// get an independent at-rest key without a second password prompt.
  static SecretKey? _localStorageKey;

  static bool get isUnlocked => _ed25519KeyPair != null;

  /// True once a wrapped identity exists on this device (registered
  /// with the backend or not — this only reflects local key material).
  static Future<bool> exists(FlutterSecureStorage storage) async {
    try {
      return await storage.read(key: _wrappedKey) != null;
    } catch (_) {
      return false;
    }
  }

  /// Creates a brand-new Ed25519 + X25519 identity and wraps it with
  /// [password]. Overwrites any existing local identity — callers
  /// must confirm this is really a fresh signup, not a returning user.
  static Future<Result<Failure, void>> createAndUnlock(
    FlutterSecureStorage storage,
    String password,
  ) async {
    try {
      final SimpleKeyPair ed = await _ed25519.newKeyPair();
      final SimpleKeyPair x = await _x25519.newKeyPair();
      final SecretKey wrapKey = await _persistWrapped(storage, password, ed, x);
      _ed25519KeyPair = ed;
      _x25519KeyPair = x;
      _localStorageKey = await _deriveLocalStorageKey(wrapKey);
      return const Ok(null);
    } catch (e) {
      return Err(CryptoFailure(message: 'Could not create identity', cause: e));
    }
  }

  /// Unwraps the existing on-device identity with [password]. Returns
  /// a [CryptoFailure] if the password is wrong or nothing is stored.
  static Future<Result<Failure, void>> unlock(
    FlutterSecureStorage storage,
    String password,
  ) async {
    try {
      final String? wrappedHex = await storage.read(key: _wrappedKey);
      final String? saltHex = await storage.read(key: _saltKey);
      if (wrappedHex == null || saltHex == null) {
        return const Err(CryptoFailure(message: 'No identity on this device'));
      }
      final SecretKey wrapKey = await _kdf.deriveKeyFromPassword(
        password: password,
        nonce: Hex.decode(saltHex),
      );
      final SecretBox box = SecretBox.fromConcatenation(
        Hex.decode(wrappedHex),
        nonceLength: _nonceLength,
        macLength: _macLength,
      );
      final List<int> plain = await _aead.decrypt(box, secretKey: wrapKey);
      final _SeedPair seeds = _SeedPair.decode(plain);
      _ed25519KeyPair = await _ed25519.newKeyPairFromSeed(seeds.edSeed);
      _x25519KeyPair = await _x25519.newKeyPairFromSeed(seeds.xSeed);
      _localStorageKey = await _deriveLocalStorageKey(wrapKey);
      return const Ok(null);
    } on SecretBoxAuthenticationError catch (e) {
      return Err(CryptoFailure(message: 'Incorrect password', cause: e));
    } catch (e) {
      return Err(CryptoFailure(message: 'Could not unlock identity', cause: e));
    }
  }

  /// Clears the in-memory keypair. The wrapped copy on disk is
  /// untouched; call [unlock] again to resume.
  static void lock() {
    _ed25519KeyPair = null;
    _x25519KeyPair = null;
    _localStorageKey = null;
  }

  /// Permanently deletes the local identity (panic wipe / logout with
  /// key destruction). This does NOT tell the backend to forget the
  /// registered public key — the directory record is inert without
  /// the private key and simply ages out.
  static Future<void> destroy(FlutterSecureStorage storage) async {
    lock();
    await storage.delete(key: _wrappedKey);
    await storage.delete(key: _saltKey);
  }

  static Future<String> ed25519PublicHex() async {
    final SimpleKeyPair? kp = _ed25519KeyPair;
    if (kp == null) throw StateError('DeviceKeys not unlocked');
    final SimplePublicKey pub = await kp.extractPublicKey();
    return Hex.encode(pub.bytes);
  }

  static Future<String> x25519PublicHex() async {
    final SimpleKeyPair? kp = _x25519KeyPair;
    if (kp == null) throw StateError('DeviceKeys not unlocked');
    final SimplePublicKey pub = await kp.extractPublicKey();
    return Hex.encode(pub.bytes);
  }

  /// Signs [nonceHex]'s raw UTF-8 bytes exactly as apps/common/auth.py
  /// verifies them server-side (`verify_key.verify(nonce.encode(), signature)`).
  static Future<String> signNonceHex(String nonceHex) async {
    final SimpleKeyPair? kp = _ed25519KeyPair;
    if (kp == null) throw StateError('DeviceKeys not unlocked');
    final Signature sig = await _ed25519.sign(nonceHex.codeUnits, keyPair: kp);
    return Hex.encode(sig.bytes);
  }

  static Future<SecretKey> _persistWrapped(
    FlutterSecureStorage storage,
    String password,
    SimpleKeyPair ed,
    SimpleKeyPair x,
  ) async {
    final List<int> edSeed = await ed.extractPrivateKeyBytes();
    final List<int> xSeed = await x.extractPrivateKeyBytes();
    final Uint8List plain = _SeedPair(edSeed, xSeed).encode();

    final Uint8List salt = _randomBytes(16);
    final SecretKey wrapKey = await _kdf.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
    final SecretBox box = await _aead.encrypt(plain, secretKey: wrapKey);

    await storage.write(
        key: _wrappedKey, value: Hex.encode(box.concatenation()));
    await storage.write(key: _saltKey, value: Hex.encode(salt));
    return wrapKey;
  }

  /// One more HKDF step past the Argon2id wrap key — never reuse the
  /// wrap key's raw bytes directly for anything else.
  static Future<SecretKey> _deriveLocalStorageKey(SecretKey wrapKey) =>
      Hkdf(hmac: Hmac.sha256(), outputLength: 32).deriveKey(
        secretKey: wrapKey,
        info: utf8.encode('ProShetuLocalStorage-v1'),
      );

  /// Derives a domain-separated local-storage key from this device's
  /// wrap key, for [PrekeyStore]/[SessionStore]/message-history
  /// storage — each domain gets its own independent key, and all of
  /// them become unreadable the instant [lock] runs, matching the
  /// existing security model (nothing decrypted survives past
  /// lock/logout).
  static Future<SecretKey> deriveDomainKey(String domain) async {
    final SecretKey? key = _localStorageKey;
    if (key == null) throw StateError('DeviceKeys not unlocked');
    return Hkdf(hmac: Hmac.sha256(), outputLength: 32)
        .deriveKey(secretKey: key, info: utf8.encode(domain));
  }

  /// ECDH with a peer's X25519 public key. Returns only the shared
  /// secret — the private scalar never leaves this class, consistent
  /// with every other method here.
  static Future<SecretKey> agree({required String remoteX25519PublicHex}) {
    final SimpleKeyPair? kp = _x25519KeyPair;
    if (kp == null) throw StateError('DeviceKeys not unlocked');
    return _x25519.sharedSecretKey(
      keyPair: kp,
      remotePublicKey: SimplePublicKey(
        Hex.decode(remoteX25519PublicHex),
        type: KeyPairType.x25519,
      ),
    );
  }

  /// Encrypts the CURRENTLY UNLOCKED identity's key material under
  /// [encryptionId] — a secret the user chooses themselves, separate
  /// from the local unlock password, whose only purpose is restoring
  /// this SAME identity on a different device via POST /v1/backup.
  /// The server only ever sees the resulting opaque bytes.
  static Future<Result<Failure, Uint8List>> exportEncrypted(
    String encryptionId,
  ) async {
    final SimpleKeyPair? ed = _ed25519KeyPair;
    final SimpleKeyPair? x = _x25519KeyPair;
    if (ed == null || x == null) {
      return const Err(CryptoFailure(message: 'DeviceKeys not unlocked'));
    }
    try {
      final List<int> edSeed = await ed.extractPrivateKeyBytes();
      final List<int> xSeed = await x.extractPrivateKeyBytes();
      final Uint8List plain = _SeedPair(edSeed, xSeed).encode();

      final Uint8List salt = _randomBytes(16);
      final SecretKey wrapKey = await _kdf.deriveKeyFromPassword(
        password: encryptionId,
        nonce: salt,
      );
      final SecretBox box = await _aead.encrypt(plain, secretKey: wrapKey);
      return Ok(Uint8List.fromList([...salt, ...box.concatenation()]));
    } catch (e) {
      return Err(CryptoFailure(message: 'Could not export identity', cause: e));
    }
  }

  /// Decrypts a blob from [exportEncrypted] with [encryptionId] and
  /// installs it as this device's identity, wrapped locally under
  /// [localPassword] — same end state as [createAndUnlock]/[unlock],
  /// just sourced from a restored backup rather than fresh generation
  /// or existing local storage. Overwrites any identity already on
  /// this device, same caveat as [createAndUnlock].
  static Future<Result<Failure, void>> importFromBackup(
    FlutterSecureStorage storage,
    Uint8List blob,
    String encryptionId,
    String localPassword,
  ) async {
    try {
      if (blob.length <= 16) {
        return const Err(CryptoFailure(message: 'Malformed backup'));
      }
      final Uint8List salt = blob.sublist(0, 16);
      final Uint8List rest = blob.sublist(16);
      final SecretKey wrapKey = await _kdf.deriveKeyFromPassword(
        password: encryptionId,
        nonce: salt,
      );
      final SecretBox box = SecretBox.fromConcatenation(
        rest,
        nonceLength: _nonceLength,
        macLength: _macLength,
      );
      final List<int> plain = await _aead.decrypt(box, secretKey: wrapKey);
      final _SeedPair seeds = _SeedPair.decode(plain);
      final SimpleKeyPair ed = await _ed25519.newKeyPairFromSeed(seeds.edSeed);
      final SimpleKeyPair x = await _x25519.newKeyPairFromSeed(seeds.xSeed);
      final SecretKey localWrapKey =
          await _persistWrapped(storage, localPassword, ed, x);
      _ed25519KeyPair = ed;
      _x25519KeyPair = x;
      _localStorageKey = await _deriveLocalStorageKey(localWrapKey);
      return const Ok(null);
    } on SecretBoxAuthenticationError catch (e) {
      return Err(CryptoFailure(message: 'Incorrect Encryption ID', cause: e));
    } catch (e) {
      return Err(CryptoFailure(message: 'Could not restore identity', cause: e));
    }
  }

  static Uint8List _randomBytes(int length) =>
      Uint8List.fromList(List<int>.generate(length, (_) => _secureRandom.nextInt(256)));
}

/// Encodes/decodes the two 32-byte seeds as one 64-byte payload.
class _SeedPair {
  _SeedPair(this.edSeed, this.xSeed);

  final List<int> edSeed;
  final List<int> xSeed;

  Uint8List encode() => Uint8List.fromList([...edSeed, ...xSeed]);

  static _SeedPair decode(List<int> bytes) {
    if (bytes.length != 64) {
      throw const FormatException('Malformed wrapped identity payload');
    }
    return _SeedPair(bytes.sublist(0, 32), bytes.sublist(32, 64));
  }
}
