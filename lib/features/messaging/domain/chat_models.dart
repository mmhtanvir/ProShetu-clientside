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
  });

  final String id;
  final String text;
  final MessageDirection direction;
  final String timestampLabel;
  final bool encrypted;

  @override
  List<Object?> get props => [id, text, direction, timestampLabel, encrypted];
}
