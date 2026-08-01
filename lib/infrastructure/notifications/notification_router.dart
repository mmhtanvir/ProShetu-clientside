import 'dart:async';

import '../../features/messaging/data/message_sync_coordinator.dart';
import '../transport/push_socket.dart';
import 'notification_service.dart';

/// Subscribes to [PushSocket.hints] and decides which ones become a
/// notification. On an 'event' hint, this now ALSO actually pulls the
/// new message (this used to only fire a local notification and
/// never call anything like [MessageSyncCoordinator.pullAndProcess]
/// — the literal missing wire behind "messages aren't received").
class NotificationRouter {
  NotificationRouter(this._pushSocket, this._notifications, this._sync);

  final PushSocket _pushSocket;
  final NotificationService _notifications;
  final MessageSyncCoordinator _sync;
  StreamSubscription<PushHint>? _sub;

  void start() {
    _sub?.cancel();
    _sub = _pushSocket.hints.listen(handleHint);
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  /// Exposed for testing/direct use.
  void handleHint(PushHint hint) {
    switch (hint.type) {
      case 'event':
        // A new /v1/sync event is waiting: pull + decrypt + store it,
        // then notify. Order matters for a future "show a real
        // preview" decision, though NotificationService deliberately
        // shows no content today (see its own doc comment) — pulling
        // first just means the message is already on-screen the
        // instant the user taps the notification.
        unawaited(_sync.pullAndProcess());
        unawaited(_notifications.showNewMessage());
      case 'call_signal':
        // Only a fresh call invite notifies. Mid-call signals
        // (candidate/answer/ringing/hangup/busy) only happen once the
        // call screen is already open and polling/listening directly
        // — a notification for those would be redundant at best.
        if (hint.raw['kind'] == 'offer') {
          unawaited(_notifications.showIncomingCall());
        }
      default:
        // Unknown hint type — ignore rather than notify on a
        // best-guess. Coordination/SOS never reaches here at all:
        // apps/coordination never calls push_to_mailbox().
        break;
    }
  }
}
