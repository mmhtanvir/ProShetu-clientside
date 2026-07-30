import 'sos_alert.dart';

/// Contract for broadcasting SOS alerts (mesh + backend later).
abstract interface class PanicRepository {
  Future<void> createSosAlert(SosDraft draft);
}
