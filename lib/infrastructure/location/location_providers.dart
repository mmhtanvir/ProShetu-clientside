import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// This device's current GPS fix, or null if location isn't available
/// (permission denied, service disabled, or the fix itself failed).
///
/// Callers that must not proceed without a real location (SOS — see
/// features/panic/data/panic_repository_impl.dart's doc comment on
/// why a location failure there must surface plainly, not degrade
/// silently) call Geolocator directly instead of this provider. This
/// one is for "nice to have" uses like nearby-hazard filtering, where
/// falling back to "unfiltered" on a denied/failed fix is the right
/// behaviour, not a bug to hide.
final currentPositionProvider = FutureProvider<Position?>((Ref ref) async {
  try {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    return await Geolocator.getCurrentPosition();
  } catch (_) {
    return null;
  }
});

/// ISO 3166-1 alpha-2 country (e.g. "BD", "US") for the device's
/// current GPS fix, reverse-geocoded on-device (no Maps/Google API
/// key involved). Used to preselect a phone number's dial code —
/// null on any failure (permission denied, no fix, geocoder
/// unavailable), same "degrade to unfiltered/unset" policy as
/// [currentPositionProvider] this depends on.
final currentCountryIsoProvider = FutureProvider<String?>((Ref ref) async {
  final Position? position = await ref.watch(currentPositionProvider.future);
  if (position == null) return null;
  try {
    final List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    return placemarks.isEmpty ? null : placemarks.first.isoCountryCode;
  } catch (_) {
    return null;
  }
});

/// Human-readable label for the device's current GPS fix (e.g.
/// "Dhanmondi, Dhaka"), reverse-geocoded on-device — used anywhere
/// the UI wants to show a real place name rather than raw
/// coordinates (nearby-mesh screen). Null on any failure; callers
/// should fall back to raw lat/lng or an honest "unavailable" state,
/// never a placeholder city name.
final currentPlaceLabelProvider = FutureProvider<String?>((Ref ref) async {
  final Position? position = await ref.watch(currentPositionProvider.future);
  if (position == null) return null;
  try {
    final List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (placemarks.isEmpty) return null;
    final Placemark p = placemarks.first;
    final List<String> parts = [
      if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
      if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
        p.administrativeArea!,
    ];
    return parts.isEmpty ? null : parts.join(', ');
  } catch (_) {
    return null;
  }
});
