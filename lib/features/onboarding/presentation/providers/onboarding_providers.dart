import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di.dart';
import '../../../../infrastructure/storage/storage_providers.dart';
import '../../data/auth_repository_impl.dart';
import '../../data/directory_client.dart';
import '../../data/id_verify_client.dart';
import '../../data/onboarding_repository_impl.dart';
import '../../data/sms_verify_client.dart';
import '../../domain/auth_repository.dart';
import '../../domain/onboarding_repository.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (Ref ref) => OnboardingRepositoryImpl(ref.watch(secureStorageProvider)),
);

final directoryClientProvider = Provider<DirectoryClient>(
  (Ref ref) => DirectoryClient(ref.watch(apiClientProvider)),
);

final smsVerifyClientProvider = Provider<SmsVerifyClient>(
  (Ref ref) => SmsVerifyClient(ref.watch(apiClientProvider)),
);

/// Real and complete, but not yet called from any screen — see
/// IdVerifyClient's doc comment for why.
final idVerifyClientProvider = Provider<IdVerifyClient>(
  (Ref ref) => IdVerifyClient(ref.watch(apiClientProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (Ref ref) => AuthRepositoryImpl(
    ref.watch(secureStorageProvider),
    ref.watch(directoryClientProvider),
    ref.watch(smsVerifyClientProvider),
    ref.watch(prekeyStoreProvider),
    ref.watch(sessionStoreProvider),
    ref.watch(messageStoreProvider),
  ),
);

/// This device's own real registered phone number — never a
/// placeholder. Feeds the profile screen.
final myPhoneProvider = FutureProvider<String>(
  (Ref ref) async => await ref.watch(authRepositoryProvider).myPhone() ?? '',
);
