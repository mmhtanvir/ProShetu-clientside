import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/map_marker.dart';
import '../providers/coordination_providers.dart';
import '../widgets/map_details_sheet.dart';
import '../widgets/marker_bitmap.dart';
import '../widgets/marker_callout_card.dart';
import '../widgets/sos_type_style.dart';

/// Full-screen crisis map (Map tab).
///
/// Each published SOS report is a pin: a reporter-identity avatar with
/// a category badge, sitting on a soft geo-anchored "pulse" circle.
/// Tapping a pin surfaces a floating preview card; tapping that opens
/// the full [MapDetailsSheet].
///
/// Note for later: online tiles conflict with the offline-first
/// requirement — an offline tile strategy is tracked as an
/// infrastructure decision.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with AutomaticKeepAliveClientMixin {
  static const CameraPosition _initial = CameraPosition(
    target: LatLng(22.2350, 91.7950),
    zoom: 14,
  );

  // Keep the map alive across tab switches: recreating the GL
  // surface on every switch costs far more than retaining it.
  @override
  bool get wantKeepAlive => true;

  GoogleMapController? _controller;
  Map<String, BitmapDescriptor> _icons = {};
  MapMarker? _selected;
  Offset? _selectedScreenPos;

  // onCameraMove fires on every animation frame during a pan/pinch;
  // this guard stops overlapping getScreenCoordinate round-trips from
  // piling up on the platform channel while the callout tracks the pin.
  bool _isTrackingCallout = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadIcons();
  }

  Future<void> _loadIcons() async {
    final List<MapMarker> markers = ref.read(mapMarkersProvider);
    final double dpr = MediaQuery.devicePixelRatioOf(context);
    final Map<String, BitmapDescriptor> icons = {};
    for (final MapMarker marker in markers) {
      icons[marker.id] = await SosMarkerBitmap.forReport(
        reporterName: marker.reporterName,
        type: marker.type,
        devicePixelRatio: dpr,
      );
    }
    if (mounted) setState(() => _icons = icons);
  }

  Future<void> _selectMarker(MapMarker marker) async {
    final GoogleMapController? controller = _controller;
    if (controller == null || _isTrackingCallout) return;
    _isTrackingCallout = true;
    try {
      final double dpr = MediaQuery.devicePixelRatioOf(context);
      final ScreenCoordinate point = await controller.getScreenCoordinate(
        LatLng(marker.latitude, marker.longitude),
      );
      if (!mounted) return;
      setState(() {
        _selected = marker;
        _selectedScreenPos = Offset(point.x / dpr, point.y / dpr);
      });
    } finally {
      _isTrackingCallout = false;
    }
  }

  void _dismissCallout() {
    if (_selected != null) setState(() => _selected = null);
  }

  Future<void> _openDetails(MapMarker marker) async {
    _dismissCallout();
    await showMapDetailsCard(context, marker);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final List<MapMarker> markers = ref.watch(mapMarkersProvider);

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initial,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
            },
            onTap: (_) => _dismissCallout(),
            onCameraMove: (_) {
              final MapMarker? selected = _selected;
              if (selected != null) _selectMarker(selected);
            },
            circles: {
              for (final MapMarker marker in markers)
                Circle(
                  circleId: CircleId('pulse-${marker.id}'),
                  center: LatLng(marker.latitude, marker.longitude),
                  radius: 160,
                  fillColor: SosTypeStyle.color(marker.type)
                      .withValues(alpha: 0.16),
                  strokeWidth: 0,
                ),
            },
            markers: {
              for (final MapMarker marker in markers)
                if (_icons[marker.id] != null)
                  Marker(
                    markerId: MarkerId(marker.id),
                    position: LatLng(marker.latitude, marker.longitude),
                    icon: _icons[marker.id]!,
                    anchor: SosMarkerBitmap.anchor,
                    onTap: () => _selectMarker(marker),
                  ),
            },
          ),
          if (_selected != null && _selectedScreenPos != null)
            Positioned(
              left: (_selectedScreenPos!.dx - 130).clamp(
                AppSpacing.sm,
                MediaQuery.sizeOf(context).width - 260 - AppSpacing.sm,
              ),
              top: (_selectedScreenPos!.dy - 96)
                  .clamp(AppSpacing.sm, double.infinity),
              child: MarkerCalloutCard(
                marker: _selected!,
                onTap: () => _openDetails(_selected!),
              ),
            ),
        ],
      ),
    );
  }
}
