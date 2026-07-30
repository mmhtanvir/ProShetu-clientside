import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/auth_repository.dart';
import '../domain/identity_doc_type.dart';

/// MOCK implementation.
///
/// The backend exists but endpoints are not wired yet, so every
/// network call succeeds after a realistic delay. Security setup
/// state persists in secure storage so app flow behaves correctly
/// across launches. Swap network calls for Dio requests here — the
/// rest of the app will not change.
///
/// TODO(backend): replace mock calls; hash the PIN (never store raw)
/// once the crypto module lands.
final class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._storage);

  final FlutterSecureStorage _storage;

  static const String _pinKey = 'encryption_pin_v1';
  static const String _contactsKey = 'trusted_contacts_v1';

  static Future<void> _network() =>
      Future<void>.delayed(const Duration(milliseconds: 600));

  @override
  Future<void> signUp({
    required String displayName,
    required String phone,
    required String password,
  }) =>
      _network();

  @override
  Future<bool> verifyOtp(String code) async {
    await _network();
    return code.length == 6; // Mock: any complete code passes.
  }

  @override
  Future<void> resendOtp() => _network();

  @override
  Future<void> submitIdentity({
    required IdentityDocType docType,
    required List<String> imagePaths,
  }) =>
      _network();

  @override
  Future<void> login({required String phone, required String password}) =>
      _network();

  @override
  Future<void> savePin(String pin) =>
      _storage.write(key: _pinKey, value: pin);

  @override
  Future<bool> hasPin() async {
    try {
      return await _storage.read(key: _pinKey) != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> saveTrustedContacts(List<String> contacts) =>
      _storage.write(key: _contactsKey, value: jsonEncode(contacts));

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
