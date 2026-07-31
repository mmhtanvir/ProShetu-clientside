import 'identity_doc_type.dart';

/// Contract for account, verification and security setup.
/// Presentation depends only on this; transport details live in data/.
abstract interface class AuthRepository {
  Future<void> signUp({
    required String displayName,
    required String phone,
    required String password,
  });

  Future<bool> verifyOtp(String code);
  Future<void> resendOtp();

  Future<void> submitIdentity({
    required IdentityDocType docType,
    required List<String> imagePaths,
  });

  Future<void> login({required String phone, required String password});

  /// This device's own registered mailbox_id, or null before signup
  /// completes. What a "my QR code" screen encodes for pairing.
  Future<String?> myMailboxId();

  /// This device's own display name, as entered at signup.
  Future<String?> myDisplayName();

  Future<void> savePin(String pin);
  Future<bool> hasPin();
  Future<bool> verifyPin(String pin);

  Future<void> saveTrustedContacts(List<String> contacts);
  Future<bool> hasCompletedSecuritySetup();

  /// Persistent session: users stay signed in across launches until
  /// an explicit logout or emergency wipe.
  Future<void> saveSession();
  Future<bool> hasSession();
  Future<void> clearSession();
}
