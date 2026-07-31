import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di.dart';
import '../../../../infrastructure/storage/storage_providers.dart';
import '../../../onboarding/domain/auth_repository.dart';
import '../../../onboarding/presentation/providers/onboarding_providers.dart';
import '../../data/chat_repository_impl.dart';
import '../../data/sync_repository_impl.dart';
import '../../domain/chat_models.dart';
import '../../domain/chat_repository.dart';
import '../../domain/sync_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>(
  (Ref ref) => ChatRepositoryImpl(ref.watch(contactDirectoryStoreProvider)),
);

/// Real /v1/sync + /v1/ack transport — not yet wired into
/// [chatRepositoryProvider]; see the gap documented in
/// ChatRepositoryImpl's doc comment.
final syncRepositoryProvider = Provider<SyncRepository>(
  (Ref ref) => SyncRepositoryImpl(ref.watch(apiClientProvider)),
);

final chatsProvider = FutureProvider<List<ChatSummary>>(
  (Ref ref) => ref.watch(chatRepositoryProvider).chats(),
);

/// This device's own display name + mailbox_id, for the "My QR code"
/// pairing screen. A provider (not an inline Future built in
/// MyQrScreen.build()) so it's fetched exactly once and cached, not
/// re-fetched on every rebuild.
final myPairingInfoProvider =
    FutureProvider<({String? name, String? mailboxId})>((Ref ref) async {
  final AuthRepository repo = ref.watch(authRepositoryProvider);
  final String? name = await repo.myDisplayName();
  final String? mailboxId = await repo.myMailboxId();
  return (name: name, mailboxId: mailboxId);
});
