import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di.dart';
import '../../data/auth_repository_impl.dart';
import '../../data/onboarding_repository_impl.dart';
import '../../domain/auth_repository.dart';
import '../../domain/onboarding_repository.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (Ref ref) => OnboardingRepositoryImpl(ref.watch(secureStorageProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (Ref ref) => AuthRepositoryImpl(ref.watch(secureStorageProvider)),
);
