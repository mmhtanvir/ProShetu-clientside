import 'package:equatable/equatable.dart';

class ChatSummary extends Equatable {
  const ChatSummary({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.ageLabel,
    // No presence/online system exists (backend intentionally keeps
    // no such state) — false is the honest default, matching the one
    // real repository, which always passes it explicitly anyway.
    this.online = false,
  });

  final String id;
  final String name;
  final String lastMessage;
  final String ageLabel;
  final bool online;

  @override
  List<Object?> get props => [id, name, lastMessage, ageLabel, online];
}

enum MessageDirection { incoming, outgoing }

enum MessageDeliveryState { pending, sent, failed }

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.text,
    required this.direction,
    required this.timestampLabel,
    this.encrypted = true,
    this.audioPath,
    this.audioDuration,
    this.replyToPreview,
    this.eventId,
    this.deliveryState = MessageDeliveryState.sent,
  });

  final String id;

  /// The peer's mailbox_id this message belongs to — needed now that
  /// history is real, persistent, cross-chat storage (MessageStore),
  /// not an in-memory Map already partitioned by chat.
  final String chatId;
  final String text;
  final MessageDirection direction;
  final String timestampLabel;
  final bool encrypted;

  /// Local file path of a recorded voice note, if this message is
  /// one. Playback-only today — sending it to a peer needs the same
  /// mailbox-directory + E2E pieces every other outbound message
  /// does (see ChatRepositoryImpl's doc comment).
  final String? audioPath;
  final Duration? audioDuration;

  /// Short quoted snippet of the message this one replies to (set by
  /// swiping a bubble in the composer) — its text, or "Voice note"
  /// for an audio message. Null if this message isn't a reply.
  final String? replyToPreview;

  /// BLAKE2b-128 content hash once known (server-confirmed for an
  /// outgoing message once sync() accepts it; always known for an
  /// incoming message). Null only for an outgoing message still
  /// `pending`. The extension point a future delivery-receipt
  /// implementation would need.
  final String? eventId;
  final MessageDeliveryState deliveryState;

  bool get isVoiceNote => audioPath != null;
  bool get isReply => replyToPreview != null;

  @override
  List<Object?> get props => [
        id,
        chatId,
        text,
        direction,
        timestampLabel,
        encrypted,
        audioPath,
        audioDuration,
        replyToPreview,
        eventId,
        deliveryState,
      ];
}
