import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import 'notification_router.dart';
import 'notification_service.dart';

final notificationServiceProvider =
    Provider<NotificationService>((Ref ref) => NotificationService());

final notificationRouterProvider = Provider<NotificationRouter>((Ref ref) {
  return NotificationRouter(
    ref.watch(pushSocketProvider),
    ref.watch(notificationServiceProvider),
  );
});
