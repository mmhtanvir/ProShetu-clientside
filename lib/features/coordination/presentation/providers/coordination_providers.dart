import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../panic/domain/sos_alert.dart';
import '../../domain/crisis_alert.dart';
import '../../domain/map_marker.dart';

/// MOCK active alerts until the coordination backend is wired.
final activeAlertsProvider = Provider<List<CrisisAlert>>((_) => const [
      CrisisAlert(
        id: 'a1',
        title: 'Flash Flood Warning — Downtown Area',
        body:
            'Avoid Dhanmondi Rd, Gulshan Ave. Shelters are available at Dhaka Community Center camp; National Museum.',
        ageLabel: '15m ago',
      ),
      CrisisAlert(
        id: 'a2',
        title: 'Road Closure — Mirpur Rd',
        body: 'Mirpur Rd closed near Science Lab. Use Panthapath as detour.',
        ageLabel: '32m ago',
      ),
      CrisisAlert(
        id: 'a3',
        title: 'Medical Camp Open — Ramna Park',
        body: 'Free medical support at Ramna Park north gate until 6 PM.',
        ageLabel: '1h ago',
      ),
    ]);

/// MOCK published SOS pins until the coordination backend is wired.
/// Reuses the same mock phone/location the SOS compose form
/// pre-fills, so map and compose stay consistent.
final mapMarkersProvider = Provider<List<MapMarker>>((_) => const [
      MapMarker(
        id: 'm1',
        type: SosType.naturalDisaster,
        reporterName: 'Mahamudul Hasan Tanvir',
        number: '+88 01600-000000',
        location: 'Dhanmondi Rd, Gulshan Ave',
        latitude: 22.2520,
        longitude: 91.7940,
        ageLabel: '15m ago',
        description: 'Earthquake',
      ),
      MapMarker(
        id: 'm2',
        type: SosType.inNeed,
        reporterName: 'Mahamudul Hasan Tanvir',
        number: '+88 01600-000000',
        location: 'Chittagong Medical College Hospital',
        latitude: 22.2465,
        longitude: 91.7970,
        ageLabel: '32m ago',
        lookingFor: 'B+ Blood',
        description: 'As soon as possible',
      ),
      MapMarker(
        id: 'm3',
        type: SosType.protestDistress,
        reporterName: 'Rashadujjaman Rabbi',
        number: '+88 01600-000000',
        location: 'Dakhin Patenga',
        latitude: 22.2190,
        longitude: 91.7910,
        ageLabel: '16 hr ago',
      ),
    ]);
