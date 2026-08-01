import 'package:cryptography/cryptography.dart';

import '../../../core/error/failure.dart';
import '../../../core/typedefs/typedefs.dart';
import '../../../core/utils/result.dart';
import '../../../infrastructure/crypto/device_keys.dart';
import '../../../infrastructure/crypto/hex.dart';
import '../../../infrastructure/transport/api_client.dart';

/// A peer's fetched prekey bundle — the raw material
/// infrastructure/crypto/x3dh.dart needs to bootstrap a session.
/// [oneTimePrekey] may be null if the server's pool was exhausted;
/// X3DH still works without one (see x3dh.dart), just slightly
/// weaker.
class PreKeyBundle {
  const PreKeyBundle({
    required this.mailboxId,
    required this.ed25519Pub,
    required this.x25519Pub,
    required this.signedPrekey,
    required this.signedPrekeySig,
    this.oneTimePrekey,
  });

  final String mailboxId;
  final String ed25519Pub;
  final String x25519Pub;
  final String signedPrekey;
  final String signedPrekeySig;
  final String? oneTimePrekey;

  static PreKeyBundle fromJson(JsonMap json) => PreKeyBundle(
        mailboxId: json['mailbox_id'] as String,
        ed25519Pub: json['ed25519_pub'] as String,
        x25519Pub: json['x25519_pub'] as String,
        signedPrekey: json['signed_prekey'] as String,
        signedPrekeySig: json['signed_prekey_sig'] as String,
        oneTimePrekey: json['one_time_prekey'] as String?,
      );
}

/// Talks to apps/directory: create/return this device's directory
/// identity, and publish/fetch X3DH prekey bundles.
class DirectoryClient {
  DirectoryClient(this._api);

  final ApiClient _api;
  static final X25519 _x25519 = X25519();

  /// POST /v1/register — unauthenticated; identity is proven later
  /// via signature, not at registration time.
  ///
  /// [displayName] is optional (crisis users must still be able to
  /// sign up without sharing one — apps/directory/views.py's doc
  /// comment). When SMS verification is on and it IS given, the
  /// backend links it to the verified phone number's hash in
  /// PhoneDirectoryEntry, so a contact search
  /// (SmsVerifyClient.lookupByPhone) can find this account by number.
  Future<Result<Failure, String>> register({
    String? registrationToken,
    String? displayName,
  }) async {
    final String ed = await DeviceKeys.ed25519PublicHex();
    final String x = await DeviceKeys.x25519PublicHex();
    final Result<Failure, JsonMap> res = await _api.postJson(
      '/v1/register',
      body: {
        'ed25519_pub': ed,
        'x25519_pub': x,
        if (registrationToken != null) 'registration_token': registrationToken,
        if (displayName != null) 'display_name': displayName,
      },
    );
    return res.fold(
      Err.new,
      (JsonMap json) => Ok(json['mailbox_id'] as String),
    );
  }

  /// POST /v1/recover — unauthenticated, same shape as [register] but
  /// requires a registration_token issued for purpose="recovery"
  /// (apps/directory/views.py::recover). Mints a fresh directory
  /// identity for an already-registered phone, replacing the mailbox
  /// PhoneDirectoryEntry resolves that number to going forward. The
  /// caller must have already generated a NEW local keypair (see
  /// AuthRepositoryImpl.startRecovery) before calling this — the
  /// ed25519/x25519 keys sent here come from whatever DeviceKeys is
  /// currently unlocked with.
  Future<Result<Failure, String>> recover({
    required String registrationToken,
    String? displayName,
  }) async {
    final String ed = await DeviceKeys.ed25519PublicHex();
    final String x = await DeviceKeys.x25519PublicHex();
    final Result<Failure, JsonMap> res = await _api.postJson(
      '/v1/recover',
      body: {
        'ed25519_pub': ed,
        'x25519_pub': x,
        'registration_token': registrationToken,
        if (displayName != null) 'display_name': displayName,
      },
    );
    return res.fold(
      Err.new,
      (JsonMap json) => Ok(json['mailbox_id'] as String),
    );
  }

  /// POST /v1/fcm/token — signed. Registers/updates this device's FCM
  /// registration token so apps/common/fcm.py can wake it when no
  /// live /ws/push socket is connected. Silently a no-op contract for
  /// the caller on failure (FcmService.registerToken() doesn't
  /// surface this to the UI) — a missed registration just means this
  /// device falls back to the existing poll path.
  Future<Result<Failure, void>> updateFcmToken(String token) async {
    final Result<Failure, JsonMap> res = await _api.postJson(
      '/v1/fcm/token',
      signed: true,
      body: {'fcm_token': token},
    );
    return res.fold(Err.new, (_) => const Ok(null));
  }

  /// POST /v1/prekeys — signed. Generates and uploads a fresh
  /// signed-prekey + a pool of one-time prekeys; their private
  /// halves are handed back so the caller can persist them via
  /// PrekeyStore (infrastructure/crypto/prekey_store.dart) — without
  /// that, this device could never complete X3DH when a peer starts
  /// a session against this bundle.
  Future<Result<Failure, List<SimpleKeyPair>>> uploadPrekeys({
    int oneTimeCount = 20,
  }) async {
    final SimpleKeyPair signedPrekeyPair = await _x25519.newKeyPair();
    final SimplePublicKey signedPrekeyPub =
        await signedPrekeyPair.extractPublicKey();
    final String signedPrekeyHex = Hex.encode(signedPrekeyPub.bytes);
    final String signedPrekeySigHex =
        await DeviceKeys.signNonceHex(signedPrekeyHex);

    final List<SimpleKeyPair> oneTimeKeyPairs = [];
    final List<String> oneTimePubHex = [];
    for (int i = 0; i < oneTimeCount; i++) {
      final SimpleKeyPair kp = await _x25519.newKeyPair();
      oneTimeKeyPairs.add(kp);
      oneTimePubHex.add(Hex.encode((await kp.extractPublicKey()).bytes));
    }

    final Result<Failure, JsonMap> res = await _api.postJson(
      '/v1/prekeys',
      signed: true,
      body: {
        'signed_prekey': signedPrekeyHex,
        'signed_prekey_sig': signedPrekeySigHex,
        'one_time_prekeys': oneTimePubHex,
      },
    );
    return res.fold(Err.new, (_) => Ok([signedPrekeyPair, ...oneTimeKeyPairs]));
  }

  /// GET /v1/prekeys/{mailboxId} — signed. Pops one one-time prekey
  /// server-side (single-use — gone from the server after this call,
  /// use it immediately or lose it).
  Future<Result<Failure, PreKeyBundle>> fetchPrekeys(String mailboxId) async {
    final Result<Failure, JsonMap> res =
        await _api.getJson('/v1/prekeys/$mailboxId', signed: true);
    return res.fold(Err.new, (JsonMap json) => Ok(PreKeyBundle.fromJson(json)));
  }
}
