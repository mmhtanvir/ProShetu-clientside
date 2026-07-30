import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/crisis_alert.dart';

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
