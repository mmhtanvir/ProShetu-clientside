import 'package:dio/dio.dart';

import '../../core/error/failure.dart';
import '../../core/typedefs/typedefs.dart';
import '../../core/utils/result.dart';
import 'api_failure_mapper.dart';

/// Thin wrapper over [Dio] so repositories don't touch Dio directly
/// (infrastructure/README: "features never import platform/plugin
/// code directly"). Every call returns the app's existing
/// [Result]/[Failure] convention instead of throwing.
///
/// Pass `signed: true` for any endpoint apps/common/auth.py protects
/// (everything except /v1/challenge, /v1/register, /v1/sms/*) — the
/// attached [SigningInterceptor] does the challenge/sign dance for
/// those requests only.
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  FutureResult<JsonMap> getJson(
    String path, {
    Map<String, dynamic>? query,
    bool signed = false,
  }) =>
      _run(() => _dio.get<dynamic>(
            path,
            queryParameters: query,
            options: Options(extra: {'signed': signed}),
          ));

  FutureResult<JsonMap> postJson(
    String path, {
    Object? body,
    bool signed = false,
  }) =>
      _run(() => _dio.post<dynamic>(
            path,
            data: body,
            options: Options(extra: {'signed': signed}),
          ));

  FutureResult<JsonMap> putBytes(
    String path, {
    required List<int> bytes,
    bool signed = false,
  }) =>
      _run(() => _dio.put<dynamic>(
            path,
            data: Stream.fromIterable([bytes]),
            options: Options(
              extra: {'signed': signed},
              headers: {
                Headers.contentLengthHeader: bytes.length,
                Headers.contentTypeHeader: 'application/octet-stream',
              },
            ),
          ));

  Future<Result<Failure, List<int>>> getBytes(
    String path, {
    bool signed = false,
  }) async {
    try {
      final Response<List<int>> response = await _dio.get<List<int>>(
        path,
        options: Options(
          extra: {'signed': signed},
          responseType: ResponseType.bytes,
        ),
      );
      return Ok(response.data ?? const []);
    } catch (e) {
      return Err(ApiFailureMapper.map(e));
    }
  }

  /// Like [getBytes] but also exposes response headers, so callers
  /// can distinguish a JSON body (presigned-URL indirection) from raw
  /// binary content by content-type without a fragile parse-and-catch.
  Future<Result<Failure, Response<List<int>>>> getBytesWithHeaders(
    String path, {
    bool signed = false,
  }) async {
    try {
      final Response<List<int>> response = await _dio.get<List<int>>(
        path,
        options: Options(
          extra: {'signed': signed},
          responseType: ResponseType.bytes,
        ),
      );
      return Ok(response);
    } catch (e) {
      return Err(ApiFailureMapper.map(e));
    }
  }

  FutureResult<JsonMap> _run(
    Future<Response<dynamic>> Function() call,
  ) async {
    try {
      final Response<dynamic> response = await call();
      final dynamic data = response.data;
      if (data == null) return const Ok(<String, dynamic>{});
      if (data is Map<String, dynamic>) return Ok(data);
      // Some endpoints (e.g. 204 No Content) return non-map bodies.
      return Ok(<String, dynamic>{'_raw': data});
    } catch (e) {
      return Err(ApiFailureMapper.map(e));
    }
  }
}
