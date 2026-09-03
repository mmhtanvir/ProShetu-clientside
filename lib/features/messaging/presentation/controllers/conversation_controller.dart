import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/chat_models.dart';
import '../providers/messaging_providers.dart';

/// Messages for one chat; sending appends optimistically.
class ConversationController extends AsyncNotifier<List<ChatMessage>> {
  ConversationController(this.chatId);

  final String chatId;

  @override
  Future<List<ChatMessage>> build() =>
      ref.watch(chatRepositoryProvider).messages(chatId);

  Future<void> send(String text, {String? replyToPreview}) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final ChatMessage msg = await ref
        .read(chatRepositoryProvider)
        .send(chatId, trimmed, replyToPreview: replyToPreview);
    state = AsyncData([...state.value ?? const [], msg]);
  }

  Future<void> sendVoiceNote(
    String audioPath,
    Duration duration, {
    String? replyToPreview,
  }) async {
    final ChatMessage msg = await ref.read(chatRepositoryProvider).sendVoiceNote(
          chatId,
          audioPath,
          duration,
          replyToPreview: replyToPreview,
        );
    state = AsyncData([...state.value ?? const [], msg]);
  }
}

final conversationControllerProvider = AsyncNotifierProvider.family<
    ConversationController, List<ChatMessage>, String>(
  ConversationController.new,
);
