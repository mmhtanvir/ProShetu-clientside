import 'package:flutter_riverpod/flutter_riverpod.dart';
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
