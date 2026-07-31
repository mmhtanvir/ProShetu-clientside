import 'package:equatable/equatable.dart';

class ChatSummary extends Equatable {
  const ChatSummary({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.ageLabel,
    this.online = true,
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

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.direction,
    required this.timestampLabel,
    this.encrypted = true,
    this.audioPath,
    this.audioDuration,
    this.replyToPreview,
  });

  final String id;
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

  bool get isVoiceNote => audioPath != null;
  bool get isReply => replyToPreview != null;

  @override
  List<Object?> get props => [
        id,
        text,
        direction,
        timestampLabel,
        encrypted,
        audioPath,
        audioDuration,
        replyToPreview,
      ];
}
