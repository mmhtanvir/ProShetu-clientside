import '../../../core/error/failure.dart';
import '../../../core/utils/result.dart';
import 'identity_doc_type.dart';

/// Contract for account, verification and security setup.
/// Presentation depends only on this; transport details live in data/.
abstract interface class AuthRepository {
  Future<void> signUp({
    required String displayName,
    required String phone,
    required String password,
  });

  /// Verifies the SMS code and completes registration. Returns the
  /// real backend [Failure] on error (wrong/expired code, or the
  /// phone number already belonging to another account) so the UI can
  /// show the actual reason instead of a generic "invalid code" for
  /// every failure mode.
  Future<Result<Failure, void>> verifyOtp(String code);
  Future<void> resendOtp();

  Future<void> submitIdentity({
    required IdentityDocType docType,
    required List<String> imagePaths,
  });

  Future<void> login({required String phone, required String password});

  /// Starts account recovery for an already-registered [phone]: mints
  /// a brand-new local device keypair wrapped with [password] (this
  /// is the point of no return — the caller must already have shown
  /// and confirmed the destructive-recovery warning before calling
  /// this) and requests an SMS code with purpose='recovery'.
  Future<void> startRecovery({required String phone, required String password});

  /// Verifies the recovery SMS code and redeems it at /v1/recover
  /// (never /v1/register) to bind the new keypair from [startRecovery]
  /// to the phone's existing account, then republishes a prekey
  /// bundle. Returns the real backend [Failure] on error, same
  /// contract as [verifyOtp].
  Future<Result<Failure, void>> verifyRecoveryOtp(String code);
  Future<void> resendRecoveryOtp();

  /// This device's own registered mailbox_id, or null before signup
  /// completes. What a "my QR code" screen encodes for pairing.
  Future<String?> myMailboxId();

  /// This device's own display name, as entered at signup.
  Future<String?> myDisplayName();

  /// This device's own phone number, as entered at signup.
  Future<String?> myPhone();

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
