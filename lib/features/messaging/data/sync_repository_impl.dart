import 'dart:convert';

import '../../../core/error/failure.dart';
import '../../../core/typedefs/typedefs.dart';
import '../../../core/utils/result.dart';
import '../../../infrastructure/sync/bloom_filter.dart';
import '../../../infrastructure/transport/api_client.dart';
import '../domain/sync_repository.dart';

final class SyncRepositoryImpl implements SyncRepository {
  SyncRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<SyncResult> sync({
    List<OutgoingEvent> carrying = const [],
    List<String> knownEventIds = const [],
  }) async {
    final BloomFilter bloom =
        BloomFilter.defaultSized(expectedElements: knownEventIds.length + 1);
    for (final String id in knownEventIds) {
      bloom.add(id);
    }

    final Result<Failure, JsonMap> res = await _api.postJson(
      '/v1/sync',
      signed: true,
      body: {
        'carrying': carrying
            .map((OutgoingEvent e) => {
                  'event_id': e.eventId,
                  'recipient_mailbox': e.recipientMailboxId,
                  'priority': e.priority,
                  'ttl_seconds': e.ttlSeconds,
                  'ciphertext': base64Encode(e.ciphertext),
                })
            .toList(),
        'bloom_m': bloom.m,
        'bloom_k': bloom.k,
        'bloom_bits': bloom.bitsHex,
        'want': const <String>[],
      },
    );

    return res.fold(
      (Failure f) => throw StateError(f.message),
      (JsonMap json) {
        final List<dynamic> deliverRaw =
            json['deliver'] as List<dynamic>? ?? const [];
        return SyncResult(
          accepted: (json['accepted'] as List<dynamic>? ?? const [])
              .cast<String>(),
          delivered: deliverRaw.cast<Map<String, dynamic>>().map(
            (Map<String, dynamic> d) {
              return DeliveredEvent(
                eventId: d['event_id'] as String,
                priority: d['priority'] as int,
                ciphertext: base64Decode(d['ciphertext'] as String),
                ttlExpiresAt: DateTime.parse(d['ttl_expires_at'] as String),
              );
            },
          ).toList(),
          wanted:
              (json['want'] as List<dynamic>? ?? const []).cast<String>(),
        );
      },
    );
  }

  @override
  Future<void> ack(List<String> eventIds) async {
    final Result<Failure, JsonMap> res = await _api.postJson(
      '/v1/ack',
      signed: true,
      body: {'event_ids': eventIds},
    );
    if (res is Err<Failure, JsonMap>) {
      throw StateError(res.value.message);
    }
  }
}
