import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/chat_repository_impl.dart';
import '../../domain/chat_models.dart';
import '../../domain/chat_repository.dart';

final chatRepositoryProvider =
    Provider<ChatRepository>((_) => ChatRepositoryImpl());

final chatsProvider = FutureProvider<List<ChatSummary>>(
  (Ref ref) => ref.watch(chatRepositoryProvider).chats(),
);
