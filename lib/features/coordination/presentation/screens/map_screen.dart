import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/geohash.dart';
import '../../../hazards/domain/hazard_event.dart';
import '../../../hazards/presentation/providers/hazard_providers.dart';
import '../providers/coordination_providers.dart';

/// Full-screen crisis map (Map tab). Two independent layers:
///
///  - Hazard layer (earthquake/flood): real, public, third-party data
///    (USGS + Google Flood Forecasting API) — working today.
///  - Community/SOS layer: real round-trip to this app's own backend
///    (/v1/coord/{geohash}), but will show ZERO pins until end-to-end
///    encryption is implemented — every delta is currently
///    undecryptable by design (see E2ePlaceholder's doc comment) and
///    is skipped rather than shown broken. This is surfaced honestly
///    via the banner below, not hidden.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with AutomaticKeepAliveClientMixin {
  static const LatLng _center = LatLng(23.7465, 90.3760); // Dhaka
  static const CameraPosition _initial = CameraPosition(
    target: _center,
    zoom: 11,
  );

  /// Coarse shard for the default map center — matches what
  /// publishDelta() would use for an SOS filed near here.
  static final String _defaultGeohash =
      Geohash.encode(_center.latitude, _center.longitude, precision: 5);

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final AsyncValue<List<HazardEvent>> hazards =
        ref.watch(hazardEventsProvider('BD'));
    final AsyncValue<List<Map<String, dynamic>>> coordination =
        ref.watch(liveCoordinationDeltasProvider(_defaultGeohash));

    final Set<Marker> markers = {
      ...hazards.maybeWhen(
        data: (List<HazardEvent> events) =>
            events.map(_hazardMarker).toSet(),
        orElse: () => const <Marker>{},
      ),
    };

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initial,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false,
            markers: markers,
          ),
          Positioned(
            left: AppSpacing.sm,
            right: AppSpacing.sm,
            top: AppSpacing.sm,
            child: _StatusBanner(
              hazards: hazards,
              coordinationCount: coordination.value?.length ?? 0,
            ),
          ),
        ],
      ),
    );
  }

  Marker _hazardMarker(HazardEvent e) {
    final double hue = e.type == HazardType.earthquake
        ? BitmapDescriptor.hueOrange
        : BitmapDescriptor.hueAzure;
    return Marker(
      markerId: MarkerId('hazard-${e.id}'),
      position: LatLng(e.latitude, e.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(hue),
      infoWindow: InfoWindow(
        title: e.title,
        snippet: '${e.severityLabel} · ${_timeAgo(e.time)}',
      ),
    );
  }

  String _timeAgo(DateTime t) {
    final Duration d = DateTime.now().toUtc().difference(t.toUtc());
    if (d.inDays > 0) return '${d.inDays}d ago';
    if (d.inHours > 0) return '${d.inHours}h ago';
    if (d.inMinutes > 0) return '${d.inMinutes}m ago';
    return 'just now';
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.hazards, required this.coordinationCount});

  final AsyncValue<List<HazardEvent>> hazards;
  final int coordinationCount;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int hazardCount = hazards.value?.length ?? 0;
    final bool hazardsLoading = hazards.isLoading;
    final bool hazardsError = hazards.hasError;

    return Material(
      color: theme.colorScheme.surface.withValues(alpha: 0.95),
      borderRadius: AppRadius.mdAll,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hazardsLoading
                  ? 'Loading earthquake/flood alerts…'
                  : hazardsError
                      ? "Couldn't load earthquake/flood alerts"
                      : '$hazardCount earthquake/flood alert(s) shown',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              coordinationCount == 0
                  ? 'Community/SOS reports: none decryptable yet '
                      '(end-to-end encryption not implemented — see '
                      'E2ePlaceholder)'
                  : '$coordinationCount community/SOS report(s)',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
