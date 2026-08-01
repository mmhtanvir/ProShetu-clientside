import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'ble_mesh_types.dart';

/// One raw sighting of a nearby device advertising [kMeshServiceUuid].
class BleSighting {
  const BleSighting({
    required this.deviceId,
    required this.rssi,
    required this.timestamp,
  });

  final String deviceId;
  final int rssi;
  final DateTime timestamp;
}

/// Thin wrapper over `flutter_blue_plus`'s central (scanning) role.
/// Isolated here so [BleMeshRepository] doesn't talk to the plugin
/// directly and so this one plugin dependency can be swapped without
/// touching anything above it.
class BleCentralScanner {
  final Guid _serviceGuid = Guid(kMeshServiceUuid);

  Stream<BleSighting> sightings() {
    return FlutterBluePlus.scanResults
        .expand((List<ScanResult> results) => results)
        .map(
          (ScanResult r) => BleSighting(
            deviceId: r.device.remoteId.str,
            rssi: r.rssi,
            timestamp: r.timeStamp,
          ),
        );
  }

  Future<bool> get isSupported => FlutterBluePlus.isSupported;

  Stream<BluetoothAdapterState> get adapterState => FlutterBluePlus.adapterState;

  Future<void> start() => FlutterBluePlus.startScan(
        withServices: [_serviceGuid],
        continuousUpdates: true,
        removeIfGone: const Duration(seconds: 15),
        androidScanMode: AndroidScanMode.lowLatency,
      );

  Future<void> stop() async {
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }
  }
}
