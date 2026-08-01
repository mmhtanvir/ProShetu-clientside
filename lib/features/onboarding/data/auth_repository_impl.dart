import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/error/failure.dart';
import '../../../core/utils/result.dart';
import '../../../infrastructure/crypto/device_keys.dart';
import '../../../infrastructure/crypto/prekey_store.dart';
import '../../../infrastructure/crypto/session_store.dart';
import '../../../infrastructure/storage/message_store.dart';
import '../domain/auth_repository.dart';
import '../domain/identity_doc_type.dart';
import 'directory_client.dart';
import 'sms_verify_client.dart';

/// Real implementation wired to the backend where the contract is
/// fully specified, and clearly documented where it is not.
///
/// The backend has NO password or server session (apps/common/auth.py
/// — identity is a signed Ed25519 challenge, nothing else). So
/// `password` here is repurposed as the passphrase that encrypts the
/// device's private key material at rest (infrastructure/crypto/
/// device_keys.dart) — a real, standard security layer, not a
/// server-side credential. `login()` is therefore fully local and
/// needs no network call, which matches this app's offline-first
/// requirement: you must be able to unlock the app with no
/// connectivity at all.
final class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this._storage,
    this._directory,
    this._sms,
    this._prekeys,
    this._sessions,
    this._messages,
  );

  final FlutterSecureStorage _storage;
  final DirectoryClient _directory;
  final SmsVerifyClient _sms;
  final PrekeyStore _prekeys;
  final SessionStore _sessions;
  final MessageStore _messages;

  static const String _pinKey = 'encryption_pin_v1';
  static const String _contactsKey = 'trusted_contacts_v1';
  static const String _sessionKey = 'session_v1';
  static const String _displayNameKey = 'display_name_v1';
  static const String _phoneKey = 'pending_phone_v1';
  static const String _verificationIdKey = 'pending_verification_id_v1';
  static const String _mailboxIdKey = 'mailbox_id_v1';
  // Recovery reuses _phoneKey/_verificationIdKey/_mailboxIdKey above —
  // recovery and signup are mutually exclusive flows on one device, so
  // there is no risk of them clobbering each other's pending state.

  @override
  Future<void> signUp({
    required String displayName,
    required String phone,
    required String password,
  }) async {
    // Create the local Ed25519/X25519 identity now; registration with
    // the backend (`/v1/register`) is deferred to verifyOtp(), because
    // a deployment with REQUIRE_SMS_VERIFICATION=1 needs a verified
    // registration_token *before* register() will succeed.
    final Result<Failure, void> created =
        await DeviceKeys.createAndUnlock(_storage, password);
    if (created is Err<Failure, void>) {
      throw StateError(created.value.message);
    }

    await _storage.write(key: _displayNameKey, value: displayName);
    await _storage.write(key: _phoneKey, value: phone);

    final Result<Failure, int> sent = await _sms.requestCode(phone);
    switch (sent) {
      case Ok<Failure, int>(:final value):
        await _storage.write(
            key: _verificationIdKey, value: value.toString());
      case Err<Failure, int>(:final value):
        throw StateError(value.message);
    }
  }

  @override
  Future<Result<Failure, void>> verifyOtp(String code) async {
    final String? verificationIdStr =
        await _storage.read(key: _verificationIdKey);
    if (verificationIdStr == null) {
      return const Err(
        UnknownFailure(message: 'No pending signup — start over.'),
      );
    }

    final Result<Failure, String> verified = await _sms.verifyCode(
      verificationId: int.parse(verificationIdStr),
      code: code,
    );
    if (verified is Err<Failure, String>) return Err(verified.value);
    final String registrationToken = (verified as Ok<Failure, String>).value;

    // Registration token in hand (or SMS gating disabled server-side,
    // in which case the token is simply ignored) — create the
    // directory identity now. On a 409 here, the backend's real
    // "This phone number is already registered" message flows through
    // in the Failure as-is (see ApiFailureMapper._detailFrom).
    final String? displayName = await _storage.read(key: _displayNameKey);
    final Result<Failure, String> registered = await _directory.register(
      registrationToken: registrationToken,
      displayName: displayName,
    );
    if (registered is Err<Failure, String>) return Err(registered.value);
    await _storage.write(
      key: _mailboxIdKey,
      value: (registered as Ok<Failure, String>).value,
    );

    // Publish a prekey bundle so peers can start an E2E session with
    // this identity later. Persist the private halves locally too
    // (first = signed prekey, rest = one-time prekeys) — without
    // this, this device could never actually complete X3DH when a
    // peer starts a session against the bundle it just published.
    final Result<Failure, List<SimpleKeyPair>> prekeys =
        await _directory.uploadPrekeys();
    if (prekeys is Ok<Failure, List<SimpleKeyPair>>) {
      final List<SimpleKeyPair> keyPairs = prekeys.value;
      if (keyPairs.isNotEmpty) {
        await _prekeys.saveSignedPrekey(keyPairs.first);
        await _prekeys.saveOneTimePrekeys(keyPairs.skip(1).toList());
      }
    }

    return const Ok(null);
  }

  @override
  Future<void> resendOtp() async {
    final String? phone = await _storage.read(key: _phoneKey);
    if (phone == null) {
      throw StateError('No pending signup — call signUp() first');
    }
    final Result<Failure, int> sent = await _sms.requestCode(phone);
    switch (sent) {
      case Ok<Failure, int>(:final value):
        await _storage.write(
            key: _verificationIdKey, value: value.toString());
      case Err<Failure, int>(:final value):
        throw StateError(value.message);
    }
  }

  @override
  Future<void> submitIdentity({
    required IdentityDocType docType,
    required List<String> imagePaths,
  }) async {
    // GENUINE CONTRACT GAP — not wired to a real endpoint.
    //
    // This screen captures PHOTOS of an NID/birth certificate. The
    // backend's only user-facing ID-verify endpoint, /v1/idv/verify,
    // does the opposite: it matches TYPED field values (full_name,
    // date_of_birth, document number, ...) against a record that an
    // authorised operator already ingested via the separately-gated
    // /v1/idv/document (requires X-Operator-Key). There is no
    // OCR-from-photo endpoint here for an end user to call — the
    // backend explicitly does not do OCR.
    //
    // Wiring this "for real" would mean inventing an OCR step that
    // doesn't exist in the provided backend, so this stays mocked
    // rather than silently pretending photo upload accomplishes
    // verification. A real fix needs either an OCR endpoint added to
    // the backend, or this screen redesigned to collect typed fields.
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  @override
  Future<void> login({required String phone, required String password}) async {
    final Result<Failure, void> unlocked =
        await DeviceKeys.unlock(_storage, password);
    if (unlocked is Err<Failure, void>) {
      throw StateError(unlocked.value.message);
    }
  }

  @override
  Future<void> startRecovery({
    required String phone,
    required String password,
  }) async {
    // Point of no return: mints a fresh keypair, overwriting the one
    // that decrypts every local message/session/prekey store. The
    // caller (recovery_confirm_controller.dart) must only reach this
    // after the user has confirmed the destructive-recovery warning.
    final Result<Failure, void> created =
        await DeviceKeys.createAndUnlock(_storage, password);
    if (created is Err<Failure, void>) {
      throw StateError(created.value.message);
    }

    // Old stores are now undecryptable garbage under the new key —
    // clear them rather than leave dead rows around. Contacts are
    // deliberately NOT touched: those pin PEERS' keys, which didn't
    // change; only this device's own identity did.
    await _messages.clearAll();
    await _sessions.clearAll();
    await _prekeys.clearAll();

    // Recovery replaces this device's identity outright, so security
    // setup (PIN + trusted contacts) must run again, same as a fresh
    // signup would require.
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _contactsKey);

    await _storage.write(key: _phoneKey, value: phone);

    final Result<Failure, int> sent =
        await _sms.requestCode(phone, purpose: 'recovery');
    switch (sent) {
      case Ok<Failure, int>(:final value):
        await _storage.write(
            key: _verificationIdKey, value: value.toString());
      case Err<Failure, int>(:final value):
        throw StateError(value.message);
    }
  }

  @override
  Future<Result<Failure, void>> verifyRecoveryOtp(String code) async {
    final String? verificationIdStr =
        await _storage.read(key: _verificationIdKey);
    if (verificationIdStr == null) {
      return const Err(
        UnknownFailure(message: 'No pending recovery — start over.'),
      );
    }

    final Result<Failure, String> verified = await _sms.verifyCode(
      verificationId: int.parse(verificationIdStr),
      code: code,
    );
    if (verified is Err<Failure, String>) return Err(verified.value);
    final String registrationToken = (verified as Ok<Failure, String>).value;

    final String? displayName = await _storage.read(key: _displayNameKey);
    final Result<Failure, String> recovered = await _directory.recover(
      registrationToken: registrationToken,
      displayName: displayName,
    );
    if (recovered is Err<Failure, String>) return Err(recovered.value);
    await _storage.write(
      key: _mailboxIdKey,
      value: (recovered as Ok<Failure, String>).value,
    );

    final Result<Failure, List<SimpleKeyPair>> prekeys =
        await _directory.uploadPrekeys();
    if (prekeys is Ok<Failure, List<SimpleKeyPair>>) {
      final List<SimpleKeyPair> keyPairs = prekeys.value;
      if (keyPairs.isNotEmpty) {
        await _prekeys.saveSignedPrekey(keyPairs.first);
        await _prekeys.saveOneTimePrekeys(keyPairs.skip(1).toList());
      }
    }

    return const Ok(null);
  }

  @override
  Future<void> resendRecoveryOtp() async {
    final String? phone = await _storage.read(key: _phoneKey);
    if (phone == null) {
      throw StateError('No pending recovery — call startRecovery() first');
    }
    final Result<Failure, int> sent =
        await _sms.requestCode(phone, purpose: 'recovery');
    switch (sent) {
      case Ok<Failure, int>(:final value):
        await _storage.write(
            key: _verificationIdKey, value: value.toString());
      case Err<Failure, int>(:final value):
        throw StateError(value.message);
    }
  }

  @override
  Future<String?> myMailboxId() => _storage.read(key: _mailboxIdKey);

  @override
  Future<String?> myDisplayName() => _storage.read(key: _displayNameKey);

  /// Despite the storage key's "_pending_" name (a holdover from
  /// before this accessor existed), this value is written once at
  /// signUp() and never deleted — it's this device's permanent phone
  /// number, not a transient signup-flow value.
  @override
  Future<String?> myPhone() => _storage.read(key: _phoneKey);

  @override
  Future<void> savePin(String pin) => _storage.write(key: _pinKey, value: pin);

  @override
  Future<bool> hasPin() async {
    try {
      return await _storage.read(key: _pinKey) != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> verifyPin(String pin) async {
    try {
      return await _storage.read(key: _pinKey) == pin;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> saveTrustedContacts(List<String> contacts) =>
      _storage.write(key: _contactsKey, value: jsonEncode(contacts));

  @override
  Future<void> saveSession() => _storage.write(key: _sessionKey, value: 'true');

  @override
  Future<bool> hasSession() async {
    try {
      return await _storage.read(key: _sessionKey) == 'true';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> clearSession() async {
    await _storage.delete(key: _sessionKey);
    DeviceKeys.lock();
  }

  @override
  Future<bool> hasCompletedSecuritySetup() async {
    try {
      final bool pin = await _storage.read(key: _pinKey) != null;
      final bool contacts = await _storage.read(key: _contactsKey) != null;
      return pin && contacts;
    } catch (_) {
      return false;
    }
  }
}
