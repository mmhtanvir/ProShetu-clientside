import 'package:intl/intl.dart';

import '../domain/chat_models.dart';
import '../domain/chat_repository.dart';

/// MOCK chat data until transport/crypto land.
final class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl();

  static const List<ChatSummary> _chats = [
    ChatSummary(id: 'p1', name: 'Emily Tran', lastMessage: 'Hey, are we still on for the meeting later?', ageLabel: '15m ago'),
    ChatSummary(id: 'p2', name: 'Michael Lee', lastMessage: 'Just checking in to see if you received my last…', ageLabel: '15m ago'),
    ChatSummary(id: 'p3', name: 'Ava Patel', lastMessage: 'Looking forward to our chat! Let me know when…', ageLabel: '15m ago'),
    ChatSummary(id: 'p4', name: 'James Kim', lastMessage: 'I found that article you mentioned. It was really…', ageLabel: '15m ago'),
    ChatSummary(id: 'p5', name: 'Olivia Wong', lastMessage: 'Can you send me the details for the project dea…', ageLabel: '15m ago'),
    ChatSummary(id: 'p6', name: 'Liam Johnson', lastMessage: 'Thanks for your help earlier! I really appreciate it.', ageLabel: '15m ago'),
  ];

  final Map<String, List<ChatMessage>> _messages = {};

  static String _now() =>
      DateFormat('dd-MM-yyyy  HH:mm:ss').format(DateTime.now());

  List<ChatMessage> _seed(String chatId) => [
        ChatMessage(id: '${chatId}m1', direction: MessageDirection.incoming, timestampLabel: _now(), text: 'Est amet diam imperdiet ultrices adipiscing mauris lorem.'),
        ChatMessage(id: '${chatId}m2', direction: MessageDirection.outgoing, timestampLabel: _now(), text: 'Lorem ipsum dolor sit amet consectetur. Est amet diam imperdiet ultrices adipiscing mauris lorem.'),
        ChatMessage(id: '${chatId}m3', direction: MessageDirection.incoming, timestampLabel: _now(), text: 'Est amet diam imperdiet ultrices adipiscing mauris lorem.'),
      ];

  @override
  Future<List<ChatSummary>> chats() async => _chats;

  @override
  Future<List<ChatMessage>> messages(String chatId) async =>
      _messages.putIfAbsent(chatId, () => _seed(chatId));

  @override
  Future<ChatMessage> send(String chatId, String text) async {
    final ChatMessage msg = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      direction: MessageDirection.outgoing,
      timestampLabel: _now(),
    );
    _messages.putIfAbsent(chatId, () => _seed(chatId)).add(msg);
    return msg;
  }
}
