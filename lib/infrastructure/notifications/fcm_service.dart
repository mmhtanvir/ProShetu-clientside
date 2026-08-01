import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../../features/onboarding/data/directory_client.dart';

/// Registers this device for FCM push and keeps the backend's copy of
/// its token current. Only ever called when [firebaseReadyProvider]
/// (app/di.dart) is true — every method here assumes Firebase is
/// already initialized.
///
/// This is the wake-up path only: it never decides what a
/// notification looks like (NotificationService/
/// firebase_background_handler.dart own that) and never touches
/// message/call content — FCM messages are data-only by contract, see
/// apps/common/fcm.py's doc comment on the backend.
class FcmService {
  FcmService(this._directory);

  final DirectoryClient _directory;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  /// Fetches the current FCM token and pushes it to the backend
  /// (POST /v1/fcm/token). Silently gives up on failure — a missed
  /// registration just means this device falls back to the existing
  /// live-socket/poll path, same as if FCM were never configured.
  Future<void> registerToken() async {
    final String? token = await _messaging.getToken();
    if (token == null) return;
    await _directory.updateFcmToken(token); // Result folded away — see doc comment
  }

  /// FCM occasionally rotates the token (app reinstall, restore,
  /// token expiry) — without re-registering here the backend would
  /// keep sending to a dead token indefinitely.
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  /// A data message arrived while the app was already in the
  /// foreground — FCM does NOT auto-show anything in that case (only
  /// background/killed delivery does, via
  /// firebase_background_handler.dart), so the caller must decide
  /// what to do (e.g. show the same local notification
  /// NotificationRouter would for the equivalent /ws/push hint).
  StreamSubscription<RemoteMessage> listenForegroundMessages(
    void Function(RemoteMessage message) onMessage,
  ) =>
      FirebaseMessaging.onMessage.listen(onMessage);
}
