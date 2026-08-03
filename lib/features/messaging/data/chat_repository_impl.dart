import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';

import '../../../core/demo/demo_mesh_data.dart';
import '../../../infrastructure/crypto/content_id.dart';
import '../../../infrastructure/crypto/e2e_crypto_service.dart';
import '../../../infrastructure/storage/contact_directory_store.dart';
import '../../../infrastructure/storage/message_store.dart' as store;
import '../domain/chat_models.dart';
import '../domain/chat_repository.dart';
import '../domain/sync_repository.dart';

/// Real send/receive, wired to the backend: encrypt via
/// [E2eCryptoService] (X3DH + Double Ratchet), persist via
/// [store.MessageStore] (survives app restart, unlike the old
/// in-memory Map), and deliver via [SyncRepository]'s `/v1/sync` +
/// `/v1/ack`. Incoming messages are inserted by
/// MessageSyncCoordinator (features/messaging/data/
/// message_sync_coordinator.dart), not by this class directly — this
/// class only owns the outbound path plus reading whatever
/// MessageStore already has for display.
final class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._contacts, this._e2e, this._messages, this._sync);

  final ContactDirectoryStore _contacts;
  final E2eCryptoService _e2e;
  final store.MessageStore _messages;
  final SyncRepository _sync;

  /// TTL for a chat message: the longest ceiling this priority class
  /// allows server-side (config/settings.py's PLATFORM["TTL_MAX"]),
  /// so a recipient who's offline for days still receives it.
  static const int _priority = 2;
  static const int _ttlSeconds = 7 * 24 * 3600;

  static String _timestampLabel(DateTime t) =>
      DateFormat('dd-MM-yyyy  HH:mm:ss').format(t);

  static String _ageLabel(DateTime t) {
    final Duration d = DateTime.now().toUtc().difference(t.toUtc());
    if (d.inDays > 0) return '${d.inDays}d ago';
    if (d.inHours > 0) return '${d.inHours}h ago';
    if (d.inMinutes > 0) return '${d.inMinutes}m ago';
    return 'just now';
  }

  @override
  Future<List<ChatSummary>> chats() async {
    final List<DirectoryContact> contacts = await _contacts.all();
    final List<ChatSummary> out = [];
    for (final DirectoryContact contact in contacts) {
      final List<store.StoredMessage> msgs =
          await _messages.messagesFor(contact.mailboxId);
      out.add(ChatSummary(
        id: contact.mailboxId,
        name: contact.displayName,
        lastMessage: _lastMessagePreview(msgs),
        ageLabel: msgs.isEmpty ? '' : _ageLabel(msgs.last.timestamp),
      ));
    }
    return out;
  }

  String _lastMessagePreview(List<store.StoredMessage> msgs) {
    if (msgs.isEmpty) return 'Say hello — no messages yet';
    final Map<String, dynamic> content = msgs.last.content;
    return content['audioPath'] != null
        ? '🎤 Voice note'
        : (content['text'] as String? ?? '');
  }

  @override
  Future<List<ChatMessage>> messages(String chatId) async {
    List<store.StoredMessage> stored = await _messages.messagesFor(chatId);
    // Hackathon demo: nearby-mesh peers are fake identities (see
    // core/demo/demo_mesh_data.dart) with no one to actually reply —
    // seed one incoming line so opening the chat doesn't look dead.
    final String? greeting = demoMeshGreetings[chatId];
    if (stored.isEmpty && greeting != null) {
      await _messages.insert(store.StoredMessage(
        localId: 'demo-greeting-$chatId',
        chatId: chatId,
        direction: store.MessageDirection.incoming,
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        deliveryState: store.DeliveryState.sent,
        content: {'text': greeting},
      ));
      stored = await _messages.messagesFor(chatId);
    }
    return stored.map(_toChatMessage).toList();
  }

  ChatMessage _toChatMessage(store.StoredMessage m) => ChatMessage(
        id: m.localId,
        chatId: m.chatId,
        text: m.content['text'] as String? ?? '',
        direction: m.direction == store.MessageDirection.outgoing
            ? MessageDirection.outgoing
            : MessageDirection.incoming,
        timestampLabel: _timestampLabel(m.timestamp),
        audioPath: m.content['audioPath'] as String?,
        audioDuration: m.content['audioDurationMs'] != null
            ? Duration(milliseconds: m.content['audioDurationMs'] as int)
            : null,
        replyToPreview: m.content['replyToPreview'] as String?,
        eventId: m.eventId,
        deliveryState: switch (m.deliveryState) {
          store.DeliveryState.pending => MessageDeliveryState.pending,
          store.DeliveryState.sent => MessageDeliveryState.sent,
          store.DeliveryState.failed => MessageDeliveryState.failed,
        },
      );

  @override
  Future<ChatMessage> send(
    String chatId,
    String text, {
    String? replyToPreview,
  }) =>
      _sendContent(
        chatId,
        <String, dynamic>{
          'text': text,
          if (replyToPreview != null) 'replyToPreview': replyToPreview,
        },
        displayText: text,
        replyToPreview: replyToPreview,
      );

  @override
  Future<ChatMessage> sendVoiceNote(
    String chatId,
    String audioPath,
    Duration duration, {
    String? replyToPreview,
  }) =>
      _sendContent(
        chatId,
        <String, dynamic>{
          'text': '',
          'audioPath': audioPath,
          'audioDurationMs': duration.inMilliseconds,
          if (replyToPreview != null) 'replyToPreview': replyToPreview,
        },
        displayText: '',
        audioPath: audioPath,
        audioDuration: duration,
        replyToPreview: replyToPreview,
      );

  /// Encrypts+sends inline (awaited) rather than firing-and-forgetting
  /// in the background: simpler than threading a separate
  /// pending->sent UI update mechanism through ConversationController
  /// for this pass. A failed attempt still gets persisted as
  /// `pending` (not lost) and picked up by MessageSyncCoordinator's
  /// next retry — see that file.
  Future<ChatMessage> _sendContent(
    String chatId,
    Map<String, dynamic> content, {
    required String displayText,
    String? audioPath,
    Duration? audioDuration,
    String? replyToPreview,
  }) async {
    final String localId = DateTime.now().microsecondsSinceEpoch.toString();
    final DateTime now = DateTime.now();
    String? eventId;
    store.DeliveryState state = store.DeliveryState.pending;

    if (demoMeshGreetings.containsKey(chatId)) {
      // Demo mesh peer (core/demo/demo_mesh_data.dart) — no real
      // identity behind this mailboxId to encrypt/sync to, so a real
      // send would just sit `pending` forever. Local-only "sent".
      state = store.DeliveryState.sent;
    } else {
      try {
        final List<int> plaintext = utf8.encode(jsonEncode(content));
        final List<int> envelope = await _e2e.encryptForRecipient(
          recipientMailboxId: chatId,
          plaintext: plaintext,
        );
        final String computedEventId =
            await ContentId.ofBytes(Uint8List.fromList(envelope));
        final SyncResult result = await _sync.sync(carrying: [
          OutgoingEvent(
            eventId: computedEventId,
            recipientMailboxId: chatId,
            priority: _priority,
            ttlSeconds: _ttlSeconds,
            ciphertext: envelope,
          ),
        ]);
        if (result.accepted.contains(computedEventId)) {
          eventId = computedEventId;
          state = store.DeliveryState.sent;
        }
      } catch (_) {
        // Stays `pending` — MessageSyncCoordinator retries on the next
        // sync cycle rather than this send() throwing and losing the
        // message entirely.
      }
    }

    await _messages.insert(store.StoredMessage(
      localId: localId,
      chatId: chatId,
      eventId: eventId,
      direction: store.MessageDirection.outgoing,
      timestamp: now,
      deliveryState: state,
      content: content,
    ));

    return ChatMessage(
      id: localId,
      chatId: chatId,
      text: displayText,
      direction: MessageDirection.outgoing,
      timestampLabel: _timestampLabel(now),
      audioPath: audioPath,
      audioDuration: audioDuration,
      replyToPreview: replyToPreview,
      eventId: eventId,
      deliveryState: state == store.DeliveryState.sent
          ? MessageDeliveryState.sent
          : MessageDeliveryState.pending,
    );
  }
}
