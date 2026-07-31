import 'package:dio/dio.dart';

import '../domain/hazard_event.dart';

/// USGS's public earthquake GeoJSON feeds
/// (earthquake.usgs.gov/earthquakes/feed/v1.0/summary/) — this is the
/// real, standard, free, no-key-required source everyone actually
/// uses for earthquake data. Google's own "Android Earthquake Alerts
/// System" has NO public third-party API (confirmed: an open,
/// unresolved request for one exists on Google's own issue tracker),
/// so this is the correct substitute, not a downgrade.
class UsgsEarthquakeClient {
  UsgsEarthquakeClient() : _dio = Dio();

  final Dio _dio;

  /// [feed] is one of USGS's standard combinations of magnitude
  /// threshold + time window, e.g. "significant_week" (major events,
  /// past 7 days — a sane default so the map isn't flooded with
  /// minor tremors), "4.5_day", "2.5_week", "all_month". Full list:
  /// https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/
  Future<List<HazardEvent>> fetch({String feed = 'significant_week'}) async {
    final Response<Map<String, dynamic>> response =
        await _dio.get<Map<String, dynamic>>(
      'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/$feed.geojson',
    );
    final List<dynamic> features =
        response.data?['features'] as List<dynamic>? ?? const [];
    return features.cast<Map<String, dynamic>>().map(_toHazardEvent).toList();
  }

  HazardEvent _toHazardEvent(Map<String, dynamic> feature) {
    final Map<String, dynamic> props =
        feature['properties'] as Map<String, dynamic>;
    final Map<String, dynamic> geometry =
        feature['geometry'] as Map<String, dynamic>;
    final List<dynamic> coords = geometry['coordinates'] as List<dynamic>;
    final double? mag = (props['mag'] as num?)?.toDouble();

    return HazardEvent(
      id: feature['id'] as String,
      type: HazardType.earthquake,
      title: props['place'] as String? ?? 'Earthquake',
      // GeoJSON order is [lng, lat, depth] — easy to transpose by
      // accident, so this is spelled out rather than indexed inline.
      longitude: (coords[0] as num).toDouble(),
      latitude: (coords[1] as num).toDouble(),
      time: DateTime.fromMillisecondsSinceEpoch(props['time'] as int),
      magnitude: mag,
      severityLabel: _severityLabel(mag),
      detailUrl: props['url'] as String?,
    );
  }

  /// USGS reports a raw magnitude, not a severity enum — this is a
  /// UI-facing bucketing on top of it, not a value from the API.
  String _severityLabel(double? mag) {
    if (mag == null) return 'Unknown magnitude';
    if (mag >= 7) return 'Major (M$mag)';
    if (mag >= 5.5) return 'Strong (M$mag)';
    if (mag >= 4) return 'Moderate (M$mag)';
    return 'Minor (M$mag)';
  }
}
