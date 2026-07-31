import 'package:dio/dio.dart';

import '../../core/error/failure.dart';
import 'signing_interceptor.dart';

/// Converts a caught exception (typically from Dio) into the app's
/// existing [Failure] hierarchy so every repository reports errors
/// the same way regardless of transport.
abstract final class ApiFailureMapper {
  static Failure map(Object error) {
    if (error is DioException) {
      if (error.error is IdentityNotUnlockedException) {
        return CryptoFailure(
          message: 'Please log in again to continue.',
          cause: error,
        );
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return NetworkFailure(message: 'Network unavailable', cause: error);
        case DioExceptionType.badResponse:
          final int? code = error.response?.statusCode;
          final dynamic body = error.response?.data;
          return NetworkFailure(
            message: _detailFrom(body) ??
                'Server error ($code): ${_shortBody(body)}',
            cause: error,
          );
        case DioExceptionType.cancel:
          return NetworkFailure(message: 'Request cancelled', cause: error);
        case DioExceptionType.badCertificate:
          return NetworkFailure(message: 'Certificate rejected', cause: error);
        // Deliberately not enumerated case-by-case: DioExceptionType has
        // gained new values between dio releases before (e.g.
        // transformTimeout) and a fully-enumerated switch breaks the
        // build the moment a newer dio version adds one — as just
        // happened. Anything not handled above (including `unknown`)
        // is a generic network error.
        default:
          return NetworkFailure(message: 'Network error', cause: error);
      }
    }
    return UnknownFailure(message: error.toString(), cause: error);
  }

  static String _shortBody(dynamic body) {
    if (body == null) return 'no body';
    final String s = body.toString();
    return s.length > 200 ? '${s.substring(0, 200)}…' : s;
  }

  /// Every error response in this backend is `{"detail": "..."}` (DRF
  /// convention) — surface that message directly instead of the raw body
  /// when present, so callers can show it to the user as-is.
  static String? _detailFrom(dynamic body) {
    if (body is Map && body['detail'] is String) return body['detail'] as String;
    return null;
  }
}
