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
/// password. This wrapping is real, standard, well-specified crypto
/// (unlike the sealed-sender payload encryption, which is
/// intentionally left unimplemented — see e2e_placeholder.dart).
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
      await _persistWrapped(storage, password, ed, x);
      _ed25519KeyPair = ed;
      _x25519KeyPair = x;
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

  static Future<void> _persistWrapped(
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
