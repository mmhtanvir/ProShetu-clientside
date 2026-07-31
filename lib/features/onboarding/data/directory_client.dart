import 'package:cryptography/cryptography.dart';

import '../../../core/error/failure.dart';
import '../../../core/typedefs/typedefs.dart';
import '../../../core/utils/result.dart';
import '../../../infrastructure/crypto/device_keys.dart';
import '../../../infrastructure/crypto/hex.dart';
import '../../../infrastructure/transport/api_client.dart';

/// Talks to apps/directory: create/return this device's directory
/// identity, and publish/fetch X3DH prekey bundles.
///
/// Publishing a signed prekey bundle is fully specified and safe to
/// implement for real (standard prekey-publishing crypto). What
/// still can't be done for real is USING a fetched bundle to derive
/// an actual session key — that's the unimplemented E2E seam
/// (infrastructure/crypto/e2e_placeholder.dart).
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

  /// POST /v1/prekeys — signed. Generates and uploads a fresh
  /// signed-prekey + a pool of one-time prekeys; their private
  /// halves are handed back so the caller can persist them (needed
  /// later to actually consume an X3DH session — still gated on the
  /// E2E seam for now).
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
  /// server-side; returns the raw bundle fields (still needs a real
  /// X3DH derivation to become a usable session — see
  /// infrastructure/crypto/e2e_placeholder.dart).
  Future<Result<Failure, JsonMap>> fetchPrekeys(String mailboxId) =>
      _api.getJson('/v1/prekeys/$mailboxId', signed: true);
}
