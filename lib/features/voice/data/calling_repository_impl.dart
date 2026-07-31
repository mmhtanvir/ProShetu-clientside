import 'dart:convert';

import '../../../core/error/failure.dart';
import '../../../core/typedefs/typedefs.dart';
import '../../../core/utils/result.dart';
import '../../../infrastructure/transport/api_client.dart';
import '../domain/calling_repository.dart';

final class CallingRepositoryImpl implements CallingRepository {
  CallingRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<void> sendSignal({
    required String callId,
    required String recipientMailboxId,
    required CallSignalKind kind,
    required int seq,
    required List<int> ciphertext,
    int ttlSeconds = 90,
  }) async {
    final Result<Failure, JsonMap> res = await _api.postJson(
      '/v1/call/signal',
      signed: true,
      body: {
        'call_id': callId,
        'recipient_mailbox': recipientMailboxId,
        'kind': kind.name,
        'seq': seq,
        'ttl_seconds': ttlSeconds,
        'ciphertext': base64Encode(ciphertext),
      },
    );
    if (res is Err<Failure, JsonMap>) {
      throw StateError(res.value.message);
    }
  }

  @override
  Future<List<CallSignal>> pollSignals() async {
    final Result<Failure, JsonMap> res =
        await _api.getJson('/v1/call/poll', signed: true);
    return res.fold(
      (Failure f) => throw StateError(f.message),
      (JsonMap json) {
        final List<dynamic> raw =
            json['signals'] as List<dynamic>? ?? const [];
        return raw.cast<Map<String, dynamic>>().map((Map<String, dynamic> s) {
          return CallSignal(
            callId: s['call_id'] as String,
            kind: CallSignalKind.values.byName(s['kind'] as String),
            seq: s['seq'] as int,
            ciphertext: base64Decode(s['ciphertext'] as String),
            createdAt: DateTime.parse(s['created_at'] as String),
            expiresAt: DateTime.parse(s['expires_at'] as String),
          );
        }).toList();
      },
    );
  }
}
