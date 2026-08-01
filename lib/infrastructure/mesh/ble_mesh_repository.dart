import 'dart:async';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart' show BluetoothAdapterState;
import 'package:permission_handler/permission_handler.dart';

import 'ble_central_scanner.dart';
import 'ble_mesh_types.dart';
import 'ble_peripheral_advertiser.dart';
import 'proximity_estimator.dart';

/// The one place BLE-plugin code is actually called from — everything
/// in `features/connectivity` talks to this through the domain
/// `MeshRepository` interface, never to `flutter_blue_plus` or
/// `flutter_ble_peripheral` directly, matching this repo's existing
/// "features never import platform code directly" convention.
///
/// Owns both roles at once: scans for other ProShetu devices AND
/// advertises this device to them, so any two nearby phones running
/// the app discover each other symmetrically.
class BleMeshRepository {
  BleMeshRepository({
    BleCentralScanner? scanner,
    BlePeripheralAdvertiser? advertiser,
  })  : _scanner = scanner ?? BleCentralScanner(),
        _advertiser = advertiser ?? BlePeripheralAdvertiser();

  final BleCentralScanner _scanner;
  final BlePeripheralAdvertiser _advertiser;
  final ProximityEstimator _estimator = ProximityEstimator();
  final Map<String, DiscoveredMeshPeer> _peers = {};

  StreamSubscription<BleSighting>? _sightingSub;
  Timer? _pruneTimer;
  final StreamController<List<DiscoveredMeshPeer>> _peersController =
      StreamController<List<DiscoveredMeshPeer>>.broadcast();
  final StreamController<MeshAvailability> _availabilityController =
      StreamController<MeshAvailability>.broadcast();

  /// Sorted (closest-first) snapshot of currently-visible peers,
  /// re-emitted on every new sighting and every stale-peer sweep.
  Stream<List<DiscoveredMeshPeer>> get peers => _peersController.stream;

  Stream<MeshAvailability> get availability => _availabilityController.stream;

  /// Multiple independent Riverpod providers (nearby peers, network
  /// status, availability) each own a start/stop lifecycle over this
  /// one shared repository — reference-counting means the radio keeps
  /// running as long as any one of them is still active, and only
  /// actually stops once the last one does.
  int _refCount = 0;

  Future<void> start() async {
    _refCount++;
    if (_refCount > 1) return;

    // Seed an immediate value on both streams before anything async
    // happens below (permission prompts, adapter-state lookups can
    // all take a moment). Without this, a listener sees nothing at
    // all until the first real sighting arrives — indistinguishable
    // from "still loading" even in the completely ordinary case of
    // "Bluetooth is on, permission granted, genuinely zero peers
    // nearby right now." Real "0 peers" must render immediately, not
    // hang forever waiting for a sighting that may never come.
    _emit();

    final MeshAvailability initial = await _checkAvailability();
    if (!_availabilityController.isClosed) {
      _availabilityController.add(initial);
    }
    if (initial != MeshAvailability.ready) return;

    _sightingSub = _scanner.sightings().listen(_onSighting);
    await _scanner.start();
    try {
      await _advertiser.start();
    } catch (_) {
      // Advertising can fail on hardware without a usable peripheral
      // role even when scanning works fine — that shouldn't stop this
      // device from still discovering others.
    }
    _pruneTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _pruneStale(),
    );
  }

  Future<void> stop() async {
    if (_refCount == 0) return;
    _refCount--;
    if (_refCount > 0) return;
    await _teardown();
  }

  Future<void> _teardown() async {
    _pruneTimer?.cancel();
    _pruneTimer = null;
    await _sightingSub?.cancel();
    _sightingSub = null;
    await _scanner.stop();
    try {
      await _advertiser.stop();
    } catch (_) {
      // Best-effort — nothing to recover if the OS already tore it
      // down (e.g. Bluetooth was turned off mid-session).
    }
    _peers.clear();
    if (!_peersController.isClosed) _peersController.add(const []);
  }

  Future<void> dispose() async {
    _refCount = 0;
    await _teardown();
    await _peersController.close();
    await _availabilityController.close();
  }

  Future<MeshAvailability> _checkAvailability() async {
    if (!await _scanner.isSupported) return MeshAvailability.unsupported;

    if (Platform.isAndroid) {
      final Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
      ].request();
      if (statuses.values.any((PermissionStatus s) => !s.isGranted)) {
        return MeshAvailability.permissionDenied;
      }
    }

    final BluetoothAdapterState state = await _scanner.adapterState.first;
    if (state != BluetoothAdapterState.on) return MeshAvailability.bluetoothOff;

    return MeshAvailability.ready;
  }

  void _onSighting(BleSighting sighting) {
    final (double smoothed, ProximityBucket bucket) =
        _estimator.sample(sighting.deviceId, sighting.rssi);
    _peers[sighting.deviceId] = DiscoveredMeshPeer(
      bleDeviceId: sighting.deviceId,
      smoothedRssi: smoothed,
      proximity: bucket,
      lastSeenAt: sighting.timestamp,
    );
    _emit();
  }

  void _pruneStale() {
    final DateTime cutoff = DateTime.now().subtract(const Duration(seconds: 20));
    final int before = _peers.length;
    _peers.removeWhere((String id, DiscoveredMeshPeer peer) {
      final bool stale = peer.lastSeenAt.isBefore(cutoff);
      if (stale) _estimator.forget(id);
      return stale;
    });
    if (_peers.length != before) _emit();
  }

  void _emit() {
    if (_peersController.isClosed) return;
    final List<DiscoveredMeshPeer> sorted = _peers.values.toList()
      ..sort((DiscoveredMeshPeer a, DiscoveredMeshPeer b) =>
          b.smoothedRssi.compareTo(a.smoothedRssi));
    _peersController.add(sorted);
  }
}
