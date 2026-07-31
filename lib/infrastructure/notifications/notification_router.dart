import 'dart:async';

import '../transport/push_socket.dart';
import 'notification_service.dart';

/// Subscribes to [PushSocket.hints] and decides which ones become a
/// notification. Currently that's exactly one case — see
/// [NotificationService]'s doc comment for why.
class NotificationRouter {
  NotificationRouter(this._pushSocket, this._notifications);

  final PushSocket _pushSocket;
  final NotificationService _notifications;
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
        // A new /v1/sync event is waiting — this is the one and only
        // case that notifies.
        unawaited(_notifications.showNewMessage());
      case 'call_signal':
        // Explicit product decision: no notification for calls. The
        // call screen (when open) polls/listens for these directly.
        break;
      default:
        // Unknown hint type — ignore rather than notify on a
        // best-guess. Coordination/SOS never reaches here at all:
        // apps/coordination never calls push_to_mailbox().
        break;
    }
  }
}
