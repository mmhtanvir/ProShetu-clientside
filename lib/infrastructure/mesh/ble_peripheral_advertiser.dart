import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

import 'ble_mesh_types.dart';

/// Thin wrapper over `flutter_ble_peripheral`'s advertising role.
///
/// Deliberately advertises nothing beyond [kMeshServiceUuid] — no
/// manufacturer data, no service data, no local name. That's not a
/// simplification of a richer design, it's the ceiling of what this
/// plugin can broadcast on iOS at all: per its own README, iOS
/// supports "Advertise UUID" only, not manufacturer/service data. A
/// design that needed those on iOS would need a different plugin (or
/// a custom native one); see README.md for why identity resolution is
/// deferred rather than approximated cross-platform.
class BlePeripheralAdvertiser {
  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();

  Future<bool> get isSupported => _peripheral.isSupported;

  Future<void> start() => _peripheral.start(
        advertiseData: AdvertiseData(serviceUuids: [kMeshServiceUuid]),
      );

  Future<void> stop() => _peripheral.stop().then((_) {});
}
