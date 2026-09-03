import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local notifications for this app, covering exactly two cases: a
/// new message arrived, or an incoming call offer arrived. This is a
/// product decision, not a technical limitation:
///
///   - Coordination (map/SOS/natural-disaster) updates are pull-only.
///     The user checks the Map tab to see them. This matches the
///     backend architecture exactly: apps/coordination never calls
///     push_to_mailbox() (grep the backend — only apps/sync and
///     apps/calling do), so there is nothing to notify on even if we
///     wanted to.
///   - Only a fresh call *offer* notifies (see
///     [NotificationRouter.handleHint]) — mid-call signals
///     (candidate/answer/ringing/hangup/busy) only happen once the
///     app is already live, so a notification for those would be
///     redundant at best.
///
/// Content stays generic ("New message" / "Incoming call") — no
/// sender/caller name, no preview — matching the design spec's
/// requirement that nothing sensitive appears in a notification,
/// which an observer could see on a lock screen.
class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // A plain const String, not _messageChannel.description — accessing
  // a field of a const object isn't itself a constant expression in
  // this version of the plugin, which broke release-mode compilation
  // (dead-code elimination requires showNewMessage's NotificationDetails
  // to be fully const).
  static const String _messageChannelDescription =
      'New message arrived — content is never shown here.';

  static const AndroidNotificationChannel _messageChannel =
      AndroidNotificationChannel(
    'messages',
    'Messages',
    description: _messageChannelDescription,
    importance: Importance.high,
  );

  static const String _callChannelDescription =
      'Incoming call — content is never shown here.';

  static const AndroidNotificationChannel _callChannel =
      AndroidNotificationChannel(
    'calls',
    'Calls',
    description: _callChannelDescription,
    importance: Importance.max,
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
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_messageChannel);
    await androidPlugin?.createNotificationChannel(_callChannel);
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
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: 'New message',
      body: null, // no body — nothing sensitive on a lock screen, ever
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'messages',
          'Messages',
          channelDescription: _messageChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: DefaultStyleInformation(true, true),
        ),
        iOS: DarwinNotificationDetails(presentBadge: true),
      ),
    );
  }

  /// Fires only for a fresh call offer — see this class's doc comment.
  Future<void> showIncomingCall() async {
    await init();
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: 'Incoming call',
      body: null, // no caller name — same policy as showNewMessage()
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'calls',
          'Calls',
          channelDescription: _callChannelDescription,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentBadge: true),
      ),
    );
  }
}
