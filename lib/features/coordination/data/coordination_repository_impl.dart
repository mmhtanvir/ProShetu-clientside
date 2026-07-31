import 'dart:convert';

import '../../../core/error/failure.dart';
import '../../../core/typedefs/typedefs.dart';
import '../../../core/utils/result.dart';
import '../../../infrastructure/transport/api_client.dart';
import '../domain/coordination_repository.dart';

final class CoordinationRepositoryImpl implements CoordinationRepository {
  CoordinationRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<String> publishDelta({
    required String geohash,
    required int ttlSeconds,
    required List<int> ciphertext,
  }) async {
    final Result<Failure, JsonMap> res = await _api.postJson(
      '/v1/coord/$geohash/publish',
      signed: true,
      body: {
        'ttl_seconds': ttlSeconds,
        'ciphertext': base64Encode(ciphertext),
      },
    );
    return res.fold(
      (Failure f) => throw StateError(f.message),
      (JsonMap json) => json['delta_id'] as String,
    );
  }

  @override
  Future<List<CoordDelta>> fetchDeltas({
    required String geohash,
    DateTime? since,
  }) async {
    final Result<Failure, JsonMap> res = await _api.getJson(
      '/v1/coord/$geohash',
      signed: true,
      query: since == null ? null : {'since': since.toIso8601String()},
    );
    return res.fold(
      (Failure f) => throw StateError(f.message),
      (JsonMap json) {
        final List<dynamic> raw = json['deltas'] as List<dynamic>? ?? const [];
        return raw
            .cast<Map<String, dynamic>>()
            .map((Map<String, dynamic> d) => CoordDelta(
                  deltaId: d['delta_id'] as String,
                  geohash: d['geohash'] as String,
                  ciphertext: base64Decode(d['ciphertext'] as String),
                  createdAt: DateTime.parse(d['created_at'] as String),
                  expiresAt: DateTime.parse(d['expires_at'] as String),
                ))
            .toList();
      },
    );
  }
}
