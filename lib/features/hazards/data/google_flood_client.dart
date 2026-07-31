import 'package:dio/dio.dart';

import '../../../core/constants/app_config.dart';
import '../domain/hazard_event.dart';

/// Google's Flood Forecasting API (floodforecasting.googleapis.com) —
/// real, public, pilot-access-gated (needs an approved API key, set
/// via GOOGLE_FLOOD_API_KEY at build time, never hardcoded).
///
/// Auth is the standard Google API key pattern (`?key=` query param) —
/// this is NOT the app's own signed backend, so it does not go
/// through ApiClient/SigningInterceptor at all.
class GoogleFloodClient {
  GoogleFloodClient() : _dio = Dio();

  final Dio _dio;
  static const String _base = 'https://floodforecasting.googleapis.com/v1';

  /// [regionCode] is a CLDR region code, e.g. "BD" for Bangladesh.
  Future<List<HazardEvent>> fetchByRegion(String regionCode) async {
    if (!AppConfig.isFloodApiConfigured) {
      throw StateError(
        'GOOGLE_FLOOD_API_KEY not set — pass it via --dart-define, '
        'same as API_BASE_URL.',
      );
    }
    final Response<Map<String, dynamic>> response =
        await _dio.post<Map<String, dynamic>>(
      '$_base/floodStatus:searchLatestFloodStatusByArea',
      queryParameters: {'key': AppConfig.googleFloodApiKey},
      data: {'regionCode': regionCode},
    );
    final List<dynamic> statuses =
        response.data?['floodStatuses'] as List<dynamic>? ?? const [];
    return statuses.cast<Map<String, dynamic>>().map(_toHazardEvent).toList();
  }

  HazardEvent _toHazardEvent(Map<String, dynamic> status) {
    final Map<String, dynamic> loc =
        status['gaugeLocation'] as Map<String, dynamic>? ?? const {};
    // Deliberately NOT an exhaustive switch over `severity` — it's a
    // server-defined enum that can gain new values without warning
    // (exactly what broke api_failure_mapper.dart's DioExceptionType
    // switch earlier in this build). Known values get a friendly
    // label; anything else falls back to the raw string rather than
    // crashing or silently dropping the event.
    final String rawSeverity = status['severity'] as String? ?? 'UNKNOWN';
    final String severityLabel = switch (rawSeverity) {
      'WARNING' => 'Flood warning',
      'DANGER' => 'Flood danger',
      'EXTREME_DANGER' => 'Extreme flood danger',
      'NO_FLOODING' => 'No flooding',
      _ => rawSeverity.replaceAll('_', ' ').toLowerCase(),
    };

    return HazardEvent(
      id: status['gaugeId'] as String? ?? status.hashCode.toString(),
      type: HazardType.flood,
      title: 'Flood forecast — ${status['source'] as String? ?? 'gauge'}',
      latitude: (loc['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (loc['longitude'] as num?)?.toDouble() ?? 0,
      time: DateTime.tryParse(status['issuedTime'] as String? ?? '') ??
          DateTime.now(),
      severityLabel: severityLabel,
    );
  }
}
