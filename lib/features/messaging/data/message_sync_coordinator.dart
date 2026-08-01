import 'dart:convert';
import 'dart:typed_data';

import '../../../infrastructure/crypto/content_id.dart';
import '../../../infrastructure/crypto/e2e_crypto_service.dart';
import '../../../infrastructure/crypto/hex.dart';
import '../../../infrastructure/storage/message_store.dart';
import '../domain/sync_repository.dart';

/// Owns both directions of real message delivery: retries any
/// outbound message still `pending` (never lost across a restart,
/// unlike the old in-memory-only repository), and pulls + decrypts +
/// acks whatever the server has for us. This is the missing wire
/// behind "messages aren't received" — NotificationRouter used to
/// only fire a local notification on a push hint and never actually
/// call anything like this.
///
/// TTL/priority match ChatRepositoryImpl's outbound send — see that
/// file for why (7-day ceiling, so an offline recipient still gets
/// the message).
class MessageSyncCoordinator {
  MessageSyncCoordinator(this._sync, this._e2e, this._messages);

  final SyncRepository _sync;
  final E2eCryptoService _e2e;
  final MessageStore _messages;

  static const int _priority = 2;
  static const int _ttlSeconds = 7 * 24 * 3600;

  Future<void> pullAndProcess() async {
    // 1. Re-attempt any outbound message still pending. A Double
    //    Ratchet message key is single-use, so "retry" means
    //    re-encrypting the same content fresh (a new envelope/event_id,
    //    not resending old bytes) — cryptographically correct, since
    //    the ratchet only ever advances forward.
    final List<StoredMessage> pendingList = await _messages.pendingOutgoing();
    final List<OutgoingEvent> retryBatch = [];
    final Map<String, StoredMessage> attemptedBy = {};
    for (final StoredMessage p in pendingList) {
      try {
        final List<int> envelope = await _e2e.encryptForRecipient(
          recipientMailboxId: p.chatId,
          plaintext: utf8.encode(jsonEncode(p.content)),
        );
        final String eventId =
            await ContentId.ofBytes(Uint8List.fromList(envelope));
        retryBatch.add(OutgoingEvent(
          eventId: eventId,
          recipientMailboxId: p.chatId,
          priority: _priority,
          ttlSeconds: _ttlSeconds,
          ciphertext: envelope,
        ));
        attemptedBy[eventId] = p;
      } catch (_) {
        continue; // try again on the next pullAndProcess() call
      }
    }

    final SyncResult result;
    try {
      result = await _sync.sync(carrying: retryBatch);
    } catch (_) {
      return; // offline/transient — next trigger retries everything
    }

    for (final String eventId in result.accepted) {
      final StoredMessage? original = attemptedBy[eventId];
      if (original != null) {
        await _messages.markSent(original.localId, eventId);
      }
    }

    // 2. Decrypt + store incoming events, collecting ids to ack.
    final List<String> toAck = [];
    for (final DeliveredEvent event in result.delivered) {
      if (await _messages.hasEvent(event.eventId)) {
        toAck.add(event.eventId); // already have it — safe to re-ack
        continue;
      }
      try {
        final List<int> decrypted =
            await _e2e.decryptFromSender(event.ciphertext);
        if (decrypted.isEmpty || decrypted[0] != 0x01) continue;
        final String senderMailboxId = _bytesToUuid(decrypted.sublist(1, 17));
        final Map<String, dynamic> content =
            jsonDecode(utf8.decode(decrypted.sublist(17)))
                as Map<String, dynamic>;
        await _messages.insert(StoredMessage(
          localId: '${DateTime.now().microsecondsSinceEpoch}-in',
          chatId: senderMailboxId,
          eventId: event.eventId,
          direction: MessageDirection.incoming,
          timestamp: DateTime.now(),
          deliveryState: DeliveryState.sent,
          content: content,
        ));
        toAck.add(event.eventId);
      } catch (_) {
        // Couldn't decrypt against any known session — don't ack,
        // let it retry on the next sync / expire via TTL rather than
        // silently dropping it.
      }
    }

    if (toAck.isNotEmpty) {
      try {
        await _sync.ack(toAck);
      } catch (_) {
        // Next pullAndProcess() will just re-see these as delivered
        // and re-attempt the ack — hasEvent() above already makes
        // that a cheap no-op decrypt-wise.
      }
    }
  }

  static String _bytesToUuid(List<int> bytes) {
    final String hex = Hex.encode(bytes);
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }
}
