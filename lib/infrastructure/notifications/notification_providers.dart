import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../features/messaging/presentation/providers/messaging_providers.dart';
import '../../features/onboarding/presentation/providers/onboarding_providers.dart';
import 'fcm_service.dart';
import 'notification_router.dart';
import 'notification_service.dart';

final notificationServiceProvider =
    Provider<NotificationService>((Ref ref) => NotificationService());

final notificationRouterProvider = Provider<NotificationRouter>((Ref ref) {
  return NotificationRouter(
    ref.watch(pushSocketProvider),
    ref.watch(notificationServiceProvider),
    ref.watch(messageSyncCoordinatorProvider),
  );
});

final fcmServiceProvider = Provider<FcmService>((Ref ref) {
  return FcmService(ref.watch(directoryClientProvider));
});
