import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di.dart';
import '../../data/onboarding_repository_impl.dart';
import '../../domain/onboarding_repository.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (Ref ref) => OnboardingRepositoryImpl(ref.watch(secureStorageProvider)),
);
