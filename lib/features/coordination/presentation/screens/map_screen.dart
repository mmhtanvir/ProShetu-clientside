import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Full-screen crisis map (Map tab).
///
/// Live Google Map centered on Dhaka with an alert marker; alert and
/// shelter layers arrive with the coordination backend. Note for
/// later: online tiles conflict with the offline-first requirement —
/// an offline tile strategy is tracked as an infrastructure decision.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with AutomaticKeepAliveClientMixin {
  static const CameraPosition _initial = CameraPosition(
    target: LatLng(23.7465, 90.3760),
    zoom: 13,
  );

  // Keep the map alive across tab switches: recreating the GL
  // surface on every switch costs far more than retaining it.
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: GoogleMap(
        initialCameraPosition: _initial,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        myLocationButtonEnabled: false,
        markers: <Marker>{
          Marker(
            markerId: const MarkerId('alert'),
            position: const LatLng(23.7465, 90.3760),
          ),
        },
      ),
    );
  }
}
