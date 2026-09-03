import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Runs in a separate background isolate when a data message arrives
/// while the app is backgrounded/killed — there is no Riverpod
/// container, no DI graph, nothing from the rest of the app here, so
/// this stays deliberately minimal: initialize Firebase for this
/// isolate, then show the exact same generic, content-free
/// notification NotificationService.showNewMessage()/showIncomingCall()
/// would, on the SAME channel ids, so they land identically regardless
/// of which path fired.
///
/// Must be a top-level function (not a method) annotated exactly like
/// this — that's a hard Flutter/FCM requirement, not a style choice.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ),
  );

  final String type = message.data['type'] as String? ?? '';
  switch (type) {
    case 'call_signal':
      if (message.data['kind'] != 'offer') return;
      await plugin.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
        title: 'Incoming call',
        body: null,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'calls',
            'Calls',
            channelDescription: 'Incoming call — content is never shown here.',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(presentBadge: true),
        ),
      );
    case 'event':
      await plugin.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
        title: 'New message',
        body: null,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'messages',
            'Messages',
            channelDescription: 'New message arrived — content is never shown here.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(presentBadge: true),
        ),
      );
    default:
      // Unknown data type — ignore rather than notify on a best-guess.
      break;
  }
}
