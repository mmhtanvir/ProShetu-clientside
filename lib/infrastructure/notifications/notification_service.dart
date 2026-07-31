import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local notifications for this app, restricted to exactly one case:
/// a new message arrived. This is a product decision, not a technical
/// limitation:
///
///   - Coordination (map/SOS/natural-disaster) updates are pull-only.
///     The user checks the Map tab to see them. This matches the
///     backend architecture exactly: apps/coordination never calls
///     push_to_mailbox() (grep the backend — only apps/sync and
///     apps/calling do), so there is nothing to notify on even if we
///     wanted to.
///   - Call signals (`type: "call_signal"` push hints) also do NOT
///     produce a notification here, by explicit product choice — see
///     [NotificationRouter.handleHint].
///
/// Content stays generic ("New message") — no sender name, no
/// preview — matching the design spec's requirement that nothing
/// sensitive appears in a notification, which an observer could see
/// on a lock screen.
class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const AndroidNotificationChannel _messageChannel =
      AndroidNotificationChannel(
    'messages',
    'Messages',
    description: 'New message arrived — content is never shown here.',
    importance: Importance.high,
  );

  Future<void> init() async {
    if (_initialized) return;
    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings ios = DarwinInitializationSettings(
      requestAlertPermission: false, // ask explicitly via requestPermission()
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_messageChannel);
    _initialized = true;
  }

  /// Call once, e.g. right after login/signup — not at every app
  /// start, so the OS permission prompt has a clear trigger.
  Future<bool> requestPermission() async {
    final bool? android = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    final bool? ios = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return (android ?? true) && (ios ?? true);
  }

  /// The ONLY notification this app ever shows.
  Future<void> showNewMessage() async {
    await init();
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      'New message',
      null, // no body — nothing sensitive on a lock screen, ever
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'messages',
          'Messages',
          channelDescription: _messageChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: DefaultStyleInformation(true, true),
        ),
        iOS: DarwinNotificationDetails(presentBadge: true),
      ),
    );
  }
}
