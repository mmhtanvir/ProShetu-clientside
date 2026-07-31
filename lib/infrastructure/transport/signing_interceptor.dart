import 'package:dio/dio.dart';

import '../crypto/device_keys.dart';

/// Attaches `X-Identity` / `X-Nonce` / `X-Signature` to every request
/// marked `options.extra['signed'] = true`, matching
/// apps/common/auth.py exactly:
///
///   1. GET /v1/challenge?pub=<ed25519_hex> -> {"nonce": "..."}
///   2. sign the nonce's raw UTF-8 bytes with the device's Ed25519 key
///   3. attach the three headers on the real request
///
/// The nonce is single-use and burned by the server on first use, so
/// a fresh one is fetched for every signed request — no caching here.
///
/// IMPORTANT: the challenge fetch itself must NOT go through this
/// interceptor (it would recurse forever trying to sign the request
/// that gets the thing it needs to sign). It uses [_bareDio], a
/// separate Dio sharing the same base options but with no
/// interceptors attached.
class SigningInterceptor extends Interceptor {
  SigningInterceptor(this._bareDio);

  /// A Dio instance with the same baseUrl/timeouts but no
  /// interceptors — used only to fetch challenges.
  final Dio _bareDio;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['signed'] != true) {
      return handler.next(options);
    }
    if (!DeviceKeys.isUnlocked) {
      return handler.reject(
        DioException(
          requestOptions: options,
          error: StateError(
              'Signed request attempted before identity was unlocked'),
          type: DioExceptionType.unknown,
        ),
      );
    }
    try {
      final String pub = await DeviceKeys.ed25519PublicHex();
      final Response<dynamic> challengeResponse = await _bareDio.get<dynamic>(
        '/v1/challenge',
        queryParameters: {'pub': pub},
      );
      final String nonce =
          (challengeResponse.data as Map<String, dynamic>)['nonce'] as String;
      final String signature = await DeviceKeys.signNonceHex(nonce);

      options.headers['X-Identity'] = pub;
      options.headers['X-Nonce'] = nonce;
      options.headers['X-Signature'] = signature;
      handler.next(options);
    } catch (e, st) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: e,
          stackTrace: st,
          type: DioExceptionType.unknown,
          message: 'Failed to obtain/sign auth challenge',
        ),
      );
    }
  }
}
