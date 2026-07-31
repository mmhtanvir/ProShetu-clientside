import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/error/failure.dart';
import '../../core/typedefs/typedefs.dart';
import '../../core/utils/result.dart';
import '../transport/api_client.dart';

/// Uploads/downloads one fragment of a chunked payload (media, panic
/// vault, voice notes — apps/sync/blob_views.py). Handles both
/// backend modes transparently:
///   - **S3 (prod)**: register -> PUT the bytes straight to the
///     presigned `upload_url` -> complete.
///   - **local (dev)**: register returns no `upload_url`; PUT the
///     bytes through the app's own proxy endpoint instead.
///
/// This is pure transport/chunking plumbing — it moves whatever
/// bytes it's given. Producing real ciphertext for those bytes is
/// still gated on infrastructure/crypto/e2e_placeholder.dart.
class BlobTransport {
  BlobTransport(this._api);

  final ApiClient _api;
  final Dio _rawDio = Dio(); // for presigned S3 URLs, outside our baseUrl

  Future<void> uploadFragment({
    required String transferId,
    required int idx,
    required int count,
    required String recipientMailboxId,
    required List<int> ciphertext,
    int priority = 3,
    int ttlSeconds = 72 * 3600,
  }) async {
    final Result<Failure, JsonMap> registered = await _api.postJson(
      '/v1/blobs/$transferId/$idx/register',
      signed: true,
      body: {
        'count': count,
        'recipient_mailbox': recipientMailboxId,
        'size': ciphertext.length,
        'priority': priority,
        'ttl_seconds': ttlSeconds,
      },
    );
    if (registered is Err<Failure, JsonMap>) {
      throw StateError(registered.value.message);
    }
    final JsonMap reg = (registered as Ok<Failure, JsonMap>).value;
    final String? uploadUrl = reg['upload_url'] as String?;

    if (uploadUrl != null) {
      // Prod: PUT straight to S3, then tell the backend it's done.
      await _rawDio.put<void>(
        uploadUrl,
        data: Stream.fromIterable([ciphertext]),
        options: Options(headers: {
          Headers.contentLengthHeader: ciphertext.length,
        }),
      );
      final Result<Failure, JsonMap> completed = await _api.postJson(
        '/v1/blobs/$transferId/$idx/complete',
        signed: true,
      );
      if (completed is Err<Failure, JsonMap>) {
        throw StateError(completed.value.message);
      }
    } else {
      // Dev/local: proxy the bytes through our own app.
      final Result<Failure, JsonMap> uploaded = await _api.putBytes(
        '/v1/blobs/$transferId/$idx/upload',
        bytes: ciphertext,
        signed: true,
      );
      if (uploaded is Err<Failure, JsonMap>) {
        throw StateError(uploaded.value.message);
      }
    }
  }

  /// Which fragment indices of [transferId] are currently available.
  Future<({int count, List<int> have, bool complete})> manifest(
    String transferId,
  ) async {
    final Result<Failure, JsonMap> res =
        await _api.getJson('/v1/blobs/$transferId', signed: true);
    return res.fold(
      (Failure f) => throw StateError(f.message),
      (JsonMap json) => (
        count: json['count'] as int,
        have: (json['have'] as List<dynamic>).cast<int>(),
        complete: json['complete'] as bool,
      ),
    );
  }

  /// The backend returns either `{"download_url": ...}` (S3 mode) or
  /// raw `application/octet-stream` bytes (local/dev mode) for the
  /// same GET. Fetch as bytes and inspect the response's
  /// content-type to decide how to interpret it.
  Future<List<int>> downloadFragment(String transferId, int idx) async {
    final Result<Failure, Response<List<int>>> res =
        await _api.getBytesWithHeaders('/v1/blobs/$transferId/$idx', signed: true);
    if (res is Err<Failure, Response<List<int>>>) {
      throw StateError(res.value.message);
    }
    final Response<List<int>> response = (res as Ok<Failure, Response<List<int>>>).value;
    final List<int> bytes = response.data ?? const [];
    final String contentType =
        response.headers.value(Headers.contentTypeHeader) ?? '';

    if (!contentType.contains('json')) {
      return bytes; // local/dev mode: raw ciphertext already
    }

    final JsonMap json = jsonDecode(utf8.decode(bytes)) as JsonMap;
    final String? url = json['download_url'] as String?;
    if (url == null) {
      throw StateError('Blob download response missing download_url');
    }
    final Response<List<int>> presigned = await _rawDio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    return presigned.data ?? const [];
  }
}
