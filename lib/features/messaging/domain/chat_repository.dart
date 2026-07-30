import 'chat_models.dart';

/// Contract for chat data. Real transport goes through
/// infrastructure/{transport,mesh,crypto} later.
abstract interface class ChatRepository {
  Future<List<ChatSummary>> chats();
  Future<List<ChatMessage>> messages(String chatId);
  Future<ChatMessage> send(String chatId, String text);
}
