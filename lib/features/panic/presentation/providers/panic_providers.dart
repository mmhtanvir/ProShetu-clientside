import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/panic_repository_impl.dart';
import '../../domain/panic_repository.dart';

final panicRepositoryProvider =
    Provider<PanicRepository>((_) => const PanicRepositoryImpl());
