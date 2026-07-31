import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../coordination/presentation/providers/coordination_providers.dart';
import '../../data/panic_repository_impl.dart';
import '../../domain/panic_repository.dart';

final panicRepositoryProvider = Provider<PanicRepository>(
  (Ref ref) => PanicRepositoryImpl(ref.watch(coordinationRepositoryProvider)),
);
