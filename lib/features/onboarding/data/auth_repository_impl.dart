import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/error/failure.dart';
import '../../../core/utils/result.dart';
import '../../../infrastructure/crypto/device_keys.dart';
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
  AuthRepositoryImpl(this._storage, this._directory, this._sms);

  final FlutterSecureStorage _storage;
  final DirectoryClient _directory;
  final SmsVerifyClient _sms;

  static const String _pinKey = 'encryption_pin_v1';
  static const String _contactsKey = 'trusted_contacts_v1';
  static const String _sessionKey = 'session_v1';
  static const String _displayNameKey = 'display_name_v1';
  static const String _phoneKey = 'pending_phone_v1';
  static const String _verificationIdKey = 'pending_verification_id_v1';
  static const String _mailboxIdKey = 'mailbox_id_v1';

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
  Future<bool> verifyOtp(String code) async {
    final String? verificationIdStr =
        await _storage.read(key: _verificationIdKey);
    if (verificationIdStr == null) return false;

    final Result<Failure, String> verified = await _sms.verifyCode(
      verificationId: int.parse(verificationIdStr),
      code: code,
    );
    if (verified is Err<Failure, String>) return false;
    final String registrationToken = (verified as Ok<Failure, String>).value;

    // Registration token in hand (or SMS gating disabled server-side,
    // in which case the token is simply ignored) — create the
    // directory identity now.
    final String? displayName = await _storage.read(key: _displayNameKey);
    final Result<Failure, String> registered = await _directory.register(
      registrationToken: registrationToken,
      displayName: displayName,
    );
    if (registered is Err<Failure, String>) return false;
    await _storage.write(
      key: _mailboxIdKey,
      value: (registered as Ok<Failure, String>).value,
    );

    // Publish a prekey bundle so peers can start an E2E session with
    // this identity later (upload is real; actually consuming a
    // fetched bundle still needs the unimplemented session/ratchet —
    // see infrastructure/crypto/e2e_placeholder.dart).
    await _directory.uploadPrekeys();

    return true;
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
  Future<String?> myMailboxId() => _storage.read(key: _mailboxIdKey);

  @override
  Future<String?> myDisplayName() => _storage.read(key: _displayNameKey);

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
