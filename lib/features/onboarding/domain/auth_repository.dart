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

  /// Encrypts the CURRENT device's identity under a user-chosen
  /// [encryptionId] and uploads it (POST /v1/backup) — the non-
  /// destructive alternative to [startRecovery]/[verifyRecoveryOtp]:
  /// this is what makes [verifyBackupRestoreOtp] able to restore the
  /// SAME identity (contacts stay trusted) on a different device,
  /// instead of minting a new one. Requires SMS-verified registration
  /// (a phone-linked account) to have something to key the backup by.
  Future<Result<Failure, void>> setEncryptionId(String encryptionId);

  /// Starts a non-destructive restore for an already-registered
  /// [phone]: requests an SMS code with purpose='recovery'. Unlike
  /// [startRecovery], this does NOT touch local key material yet —
  /// nothing is overwritten until [verifyBackupRestoreOtp] succeeds.
  Future<void> startBackupRestore({required String phone});

  /// Verifies the code from [startBackupRestore], fetches the
  /// encrypted backup (POST /v1/backup/fetch), decrypts it with
  /// [encryptionId], and installs it as this device's identity
  /// (wrapped locally under [localPassword]) — restoring the exact
  /// same account/contacts, not a fresh one. Returns the real backend
  /// [Failure] on error (wrong code, wrong Encryption ID, or no
  /// backup ever set up for this number).
  Future<Result<Failure, void>> verifyBackupRestoreOtp(
    String code, {
    required String encryptionId,
    required String localPassword,
  });

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
