import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Live OS-level network state — Wi-Fi, mobile data, or none — for
/// the dashboard's Internet status tile. `MeshRepository.networkStatus`
/// (see mesh_repository_impl.dart) independently checks the same
/// underlying connectivity_plus state for its own `internetOnline`
/// bit; this provider is the one the dashboard's Internet tile
/// actually watches, since it updates live as the network changes
/// rather than only re-checking each time the mesh peer count ticks.
final connectivityProvider = StreamProvider<List<ConnectivityResult>>(
  (Ref ref) async* {
    yield await Connectivity().checkConnectivity();
    yield* Connectivity().onConnectivityChanged;
  },
);

enum ConnectionKind { wifi, mobile, offline, other }

ConnectionKind connectionKindOf(List<ConnectivityResult> results) {
  if (results.contains(ConnectivityResult.wifi) ||
      results.contains(ConnectivityResult.ethernet)) {
    return ConnectionKind.wifi;
  }
  if (results.contains(ConnectivityResult.mobile)) {
    return ConnectionKind.mobile;
  }
  if (results.isEmpty || results.contains(ConnectivityResult.none)) {
    return ConnectionKind.offline;
  }
  return ConnectionKind.other;
}
