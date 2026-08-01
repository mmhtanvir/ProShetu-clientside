import '../../../core/error/failure.dart';
import '../../../core/typedefs/typedefs.dart';
import '../../../core/utils/result.dart';
import '../../../infrastructure/transport/api_client.dart';

/// Talks to apps/smsverify. Plaintext request/response — no E2E
/// crypto involved, so this is a real, complete implementation (not
/// gated on the encryption seam).
class SmsVerifyClient {
  SmsVerifyClient(this._api);

  final ApiClient _api;

  /// POST /v1/sms/request -> verification_id. [purpose] is 'signup'
  /// (default — number must NOT already be registered) or 'recovery'
  /// (number MUST already be registered); the backend enforces the
  /// opposite RegisteredNumber check for each and carries it onto the
  /// registration_token verifyCode() returns, so /v1/register and
  /// /v1/recover each reject the other's tokens.
  Future<Result<Failure, int>> requestCode(
    String msisdn, {
    String purpose = 'signup',
  }) async {
    final Result<Failure, JsonMap> res = await _api.postJson(
      '/v1/sms/request',
      body: {'msisdn': msisdn, 'purpose': purpose},
    );
    return res.fold(Err.new, (JsonMap json) => Ok(json['verification_id'] as int));
  }

  /// POST /v1/sms/verify -> single-use registration_token
  Future<Result<Failure, String>> verifyCode({
    required int verificationId,
    required String code,
  }) async {
    final Result<Failure, JsonMap> res = await _api.postJson(
      '/v1/sms/verify',
      body: {'verification_id': verificationId, 'code': code},
    );
    return res.fold(
      Err.new,
      (JsonMap json) => Ok(json['registration_token'] as String),
    );
  }

  /// POST /v1/sms/lookup — signed (unlike request/verify above: this
  /// is a search a signed-in user performs, not part of the
  /// pre-identity signup flow). Finds a registered contact by phone
  /// number, WhatsApp/Telegram-style — only accounts that gave a
  /// display name at signup are findable (apps/directory/views.py's
  /// register()). Fails with a NetworkFailure(message: "no account
  /// found for this number") on a 404, same as any other API error.
  Future<Result<Failure, ({String mailboxId, String displayName})>>
      lookupByPhone(String msisdn) async {
    final Result<Failure, JsonMap> res = await _api.postJson(
      '/v1/sms/lookup',
      signed: true,
      body: {'msisdn': msisdn},
    );
    return res.fold(
      Err.new,
      (JsonMap json) => Ok((
        mailboxId: json['mailbox_id'] as String,
        displayName: json['display_name'] as String,
      )),
    );
  }
}
