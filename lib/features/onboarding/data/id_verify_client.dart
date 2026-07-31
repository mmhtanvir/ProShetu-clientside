import '../../../core/error/failure.dart';
import '../../../core/typedefs/typedefs.dart';
import '../../../core/utils/result.dart';
import '../../../infrastructure/transport/api_client.dart';
import '../domain/identity_doc_type.dart';

class IdvFieldMatch {
  const IdvFieldMatch({required this.matched, required this.fields});

  final bool matched;

  /// Per-field result: true/false/null (field not on the stored doc).
  final Map<String, bool?> fields;
}

/// Talks to apps/idverify's user-facing endpoints only. Matches TYPED
/// field values against a record an authorised operator already
/// ingested via the separately-gated /v1/idv/document (operator key
/// required — not callable from this app).
///
/// This client is real and complete, but nothing calls it yet: the
/// existing identity_capture_screen.dart captures PHOTOS, not the
/// typed fields (full_name, date_of_birth, document number, ...)
/// this endpoint needs. Wiring it into the UI needs that screen
/// redesigned to collect typed fields, or a new screen — not done
/// here since it's a UI change beyond "connect to backend", not an
/// API-shape gap. Call [verify] directly once such a form exists.
class IdVerifyClient {
  IdVerifyClient(this._api);

  final ApiClient _api;

  /// POST /v1/idv/verify — signed.
  Future<Result<Failure, IdvFieldMatch>> verify({
    required IdentityDocType docType,
    required Map<String, String> fields,
  }) async {
    final Result<Failure, JsonMap> res = await _api.postJson(
      '/v1/idv/verify',
      signed: true,
      body: {
        'doc_type': _wireDocType(docType),
        'fields': fields,
      },
    );
    return res.fold(
      Err.new,
      (JsonMap json) => Ok(IdvFieldMatch(
        matched: json['matched'] as bool,
        fields: (json['fields'] as Map<String, dynamic>)
            .map((String k, dynamic v) => MapEntry(k, v as bool?)),
      )),
    );
  }

  /// GET /v1/idv/status — signed.
  Future<Result<Failure, bool>> status() async {
    final Result<Failure, JsonMap> res =
        await _api.getJson('/v1/idv/status', signed: true);
    return res.fold(Err.new, (JsonMap json) => Ok(json['verified'] as bool));
  }

  String _wireDocType(IdentityDocType docType) => switch (docType) {
        IdentityDocType.nid => 'nid',
        IdentityDocType.birthCertificate => 'birth_certificate',
      };
}
