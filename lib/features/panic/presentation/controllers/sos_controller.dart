import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/panic_repository.dart';
import '../../domain/sos_alert.dart';
import '../providers/panic_providers.dart';

/// Carries the chosen SOS type from the type screen to the form.
/// Kept alive across the flow; reset when a new flow starts.
class SosTypeSelection extends Notifier<SosType?> {
  @override
  SosType? build() => null;
  void select(SosType type) => state = type;
  void reset() => state = null;
}

final sosTypeProvider =
    NotifierProvider<SosTypeSelection, SosType?>(SosTypeSelection.new);

/// Submits the composed SOS alert.
class SosSubmitController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> submit(SosDraft draft) async {
    state = const AsyncLoading();
    try {
      final PanicRepository repo = ref.read(panicRepositoryProvider);
      await repo.createSosAlert(draft);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final sosSubmitControllerProvider =
    AutoDisposeAsyncNotifierProvider<SosSubmitController, void>(
  SosSubmitController.new,
);
