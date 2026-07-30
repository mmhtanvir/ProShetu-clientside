import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../app/theme/app_theme.dart';

/// Live Google Map preview on the dashboard.
///
/// Lite mode (Android) renders a static snapshot instead of a full
/// GL surface — a deliberate low-end battery/GPU choice. Tapping
/// forwards to the Map tab. Requires a Maps API key configured in
/// the platform projects.
class MapPreview extends StatelessWidget {
  const MapPreview({this.onTap, super.key});

  final VoidCallback? onTap;

  /// Dhaka fallback center until live GPS wiring lands.
  static const CameraPosition _initial = CameraPosition(
    target: LatLng(23.7465, 90.3760),
    zoom: 13.5,
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.lgAll,
      child: SizedBox(
        height: 140,
        child: Stack(
          children: [
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: _initial,
                liteModeEnabled: true,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
                compassEnabled: false,
                markers: <Marker>{
                  Marker(
                    markerId: const MarkerId('alert'),
                    position: const LatLng(23.7465, 90.3760),
                  ),
                },
              ),
            ),
            // Full-surface tap target above the (inert) lite map.
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: onTap),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
