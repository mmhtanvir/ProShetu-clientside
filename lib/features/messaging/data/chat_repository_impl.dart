import 'package:intl/intl.dart';

import '../../../infrastructure/storage/contact_directory_store.dart';
import '../domain/chat_models.dart';
import '../domain/chat_repository.dart';

/// Chat list is real: it's sourced from [ContactDirectoryStore], the
/// contacts a device has actually QR-paired with (see
/// features/messaging/presentation/screens/{my_qr,scan_qr}_screen.dart).
///
/// Message SEND/RECEIVE is still local-only, and that remains a
/// GENUINE GAP, not an oversight: the real backend's `/v1/sync` is a
/// flat event/mailbox store-and-forward protocol, and any message
/// content sent through it needs the encryption this app's E2E seam
/// deliberately leaves unimplemented (see
/// infrastructure/crypto/e2e_placeholder.dart). The real, correct
/// `/v1/sync` + `/v1/ack` HTTP layer DOES exist now —
/// domain/sync_repository.dart + data/sync_repository_impl.dart —
/// ready to be wired in once real encryption exists; contacts are no
/// longer the blocker now that ContactDirectoryStore is populated.
final class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._contacts);

  final ContactDirectoryStore _contacts;

  final Map<String, List<ChatMessage>> _messages = {};

  static String _now() =>
      DateFormat('dd-MM-yyyy  HH:mm:ss').format(DateTime.now());

  @override
  Future<List<ChatSummary>> chats() async {
    final List<DirectoryContact> contacts = await _contacts.all();
    return [
      for (final DirectoryContact contact in contacts)
        ChatSummary(
          id: contact.mailboxId,
          name: contact.displayName,
          lastMessage: _lastMessagePreview(contact.mailboxId),
          ageLabel: _messages[contact.mailboxId]?.isNotEmpty ?? false
              ? _messages[contact.mailboxId]!.last.timestampLabel
              : '',
          // No presence/online system exists (backend intentionally
          // keeps no such state — see apps/directory/models.py). False
          // is the honest default rather than faking activity.
          online: false,
        ),
    ];
  }

  String _lastMessagePreview(String chatId) {
    final List<ChatMessage>? msgs = _messages[chatId];
    if (msgs == null || msgs.isEmpty) return 'Say hello — no messages yet';
    final ChatMessage last = msgs.last;
    return last.isVoiceNote ? '🎤 Voice note' : last.text;
  }

  @override
  Future<List<ChatMessage>> messages(String chatId) async =>
      _messages.putIfAbsent(chatId, () => []);

  @override
  Future<ChatMessage> send(
    String chatId,
    String text, {
    String? replyToPreview,
  }) async {
    final ChatMessage msg = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      direction: MessageDirection.outgoing,
      timestampLabel: _now(),
      replyToPreview: replyToPreview,
    );
    _messages.putIfAbsent(chatId, () => []).add(msg);
    return msg;
  }

  @override
  Future<ChatMessage> sendVoiceNote(
    String chatId,
    String audioPath,
    Duration duration, {
    String? replyToPreview,
  }) async {
    final ChatMessage msg = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: '',
      direction: MessageDirection.outgoing,
      timestampLabel: _now(),
      audioPath: audioPath,
      audioDuration: duration,
      replyToPreview: replyToPreview,
    );
    _messages.putIfAbsent(chatId, () => []).add(msg);
    return msg;
  }
}
