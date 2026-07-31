import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Live OS-level network state — Wi-Fi, mobile data, or none — for
/// the dashboard's Internet status tile. Distinct from
/// [MeshRepository.networkStatus]'s `internetOnline` bit (still mock,
/// see mesh_repository_impl.dart): this is real, backed by the
/// platform's actual connectivity APIs, and updates live as the
/// device's network changes rather than being read once.
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
