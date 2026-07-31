import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di.dart';
import '../../data/calling_repository_impl.dart';
import '../../domain/calling_repository.dart';

final callingRepositoryProvider = Provider<CallingRepository>(
  (Ref ref) => CallingRepositoryImpl(ref.watch(apiClientProvider)),
);
