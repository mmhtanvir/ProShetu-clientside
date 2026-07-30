import '../domain/panic_repository.dart';
import '../domain/sos_alert.dart';

/// MOCK: succeeds after a realistic delay.
/// TODO(backend/mesh): broadcast over transport + mesh.
final class PanicRepositoryImpl implements PanicRepository {
  const PanicRepositoryImpl();

  @override
  Future<void> createSosAlert(SosDraft draft) =>
      Future<void>.delayed(const Duration(milliseconds: 700));
}
