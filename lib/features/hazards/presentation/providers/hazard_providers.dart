import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../infrastructure/location/location_providers.dart';
import '../../../coordination/domain/crisis_alert.dart';
import '../../data/google_flood_client.dart';
import '../../data/usgs_earthquake_client.dart';
import '../../domain/hazard_event.dart';

/// Alerting threshold — floods have no magnitude field, so this only
/// ever filters HazardType.earthquake.
const double kMinAlertMagnitude = 4.0;

/// How close a hazard needs to be to the user's current position to
/// count as "nearby" for alerting. A judgment call, not a spec'd
/// value: wide enough that a quake/flood felt across a country the
/// size of Bangladesh still alerts, narrow enough that the other side
/// of the world doesn't.
const double kNearbyRadiusMeters = 300 * 1000;

final usgsEarthquakeClientProvider =
    Provider<UsgsEarthquakeClient>((_) => UsgsEarthquakeClient());

final googleFloodClientProvider =
    Provider<GoogleFloodClient>((_) => GoogleFloodClient());

/// '2.5_week' (not the default 'significant_week'): USGS's own
/// "significant" classification factors more than magnitude (e.g.
/// population exposure), so it can omit a real M4+ event in a
/// sparsely-populated area. Fetching the lower, magnitude-based
/// threshold and filtering client-side (see [hazardAlertsProvider])
/// is the only way to guarantee every M4+ quake is actually considered.
final earthquakeEventsProvider = FutureProvider<List<HazardEvent>>(
  (Ref ref) =>
      ref.watch(usgsEarthquakeClientProvider).fetch(feed: '2.5_week'),
);

/// Defaults to Bangladesh ("BD", CLDR region code) — matching the
/// rest of this app's mock data locations (Dhaka, Chittagong).
final floodEventsProvider =
    FutureProvider.family<List<HazardEvent>, String>((Ref ref, String regionCode) {
  return ref.watch(googleFloodClientProvider).fetchByRegion(regionCode);
});

/// Combined feed for the map layer. Flood failures (e.g. key not
/// configured, pilot access not yet approved for a region) don't
/// take down the earthquake layer — each source degrades
/// independently rather than one bad source blanking the whole map.
final hazardEventsProvider =
    FutureProvider.family<List<HazardEvent>, String>((Ref ref, String floodRegionCode) async {
  final List<HazardEvent> combined = [];

  try {
    combined.addAll(
      await ref.watch(usgsEarthquakeClientProvider).fetch(feed: '2.5_week'),
    );
  } catch (_) {
    // Earthquake feed down — still show flood data below.
  }

  try {
    combined.addAll(
      await ref.watch(googleFloodClientProvider).fetchByRegion(floodRegionCode),
    );
  } catch (_) {
    // Flood API unavailable (key missing, region not covered, pilot
    // access pending) — still show earthquake data above.
  }

  return combined;
});

/// [hazardEventsProvider] reshaped into [CrisisAlert] — lets the
/// dashboard's existing AlertCarousel widget show real hazard data
/// without changing its type contract. Real data replaces the mock
/// list in coordination_providers.dart's activeAlertsProvider, which
/// stays defined for reference/fallback.
///
/// Only alerts for earthquakes >= [kMinAlertMagnitude] and events
/// within [kNearbyRadiusMeters] of the user's current position (both
/// types) — a global feed of every M2 tremor and every flood gauge on
/// Earth is noise, not an alert. If the user's position can't be
/// determined (permission denied, GPS off), the distance filter is
/// skipped rather than hiding every alert — magnitude filtering still
/// applies.
final hazardAlertsProvider =
    FutureProvider.family<List<CrisisAlert>, String>((Ref ref, String floodRegionCode) async {
  final List<HazardEvent> events =
      await ref.watch(hazardEventsProvider(floodRegionCode).future);
  final Position? position =
      await ref.watch(currentPositionProvider.future);

  final List<HazardEvent> filtered = events.where((HazardEvent e) {
    if (e.type == HazardType.earthquake &&
        (e.magnitude == null || e.magnitude! < kMinAlertMagnitude)) {
      return false;
    }
    if (position == null) return true;
    final double meters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      e.latitude,
      e.longitude,
    );
    return meters <= kNearbyRadiusMeters;
  }).toList();

  return filtered
      .map((HazardEvent e) => CrisisAlert(
            id: e.id,
            title: '${e.type == HazardType.earthquake ? 'Earthquake' : 'Flood'}'
                ' — ${e.title}',
            body: e.severityLabel,
            ageLabel: _ageLabel(e.time),
          ))
      .toList();
});

String _ageLabel(DateTime t) {
  final Duration d = DateTime.now().toUtc().difference(t.toUtc());
  if (d.inDays > 0) return '${d.inDays}d ago';
  if (d.inHours > 0) return '${d.inHours}h ago';
  if (d.inMinutes > 0) return '${d.inMinutes}m ago';
  return 'just now';
}
