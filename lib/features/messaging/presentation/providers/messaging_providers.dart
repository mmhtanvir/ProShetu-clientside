import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di.dart';
import '../../../../infrastructure/crypto/device_keys.dart';
import '../../../../infrastructure/crypto/e2e_crypto_service.dart';
import '../../../../infrastructure/storage/storage_providers.dart';
import '../../../onboarding/domain/auth_repository.dart';
import '../../../onboarding/presentation/providers/onboarding_providers.dart';
import '../../data/chat_repository_impl.dart';
import '../../data/message_sync_coordinator.dart';
import '../../data/sync_repository_impl.dart';
import '../../domain/chat_models.dart';
import '../../domain/chat_repository.dart';
import '../../domain/sync_repository.dart';

/// Real implementation of the 1:1 E2E encryption seam (replaces
/// e2e_placeholder.dart) — shared by messaging and voice calling
/// (features/voice/presentation/controllers/call_controller.dart),
/// since both need to encrypt/decrypt for a peer's mailbox_id.
final e2eCryptoServiceProvider = Provider<E2eCryptoService>(
  (Ref ref) => E2eCryptoService(
    ref.watch(directoryClientProvider),
    ref.watch(contactDirectoryStoreProvider),
    ref.watch(prekeyStoreProvider),
    ref.watch(sessionStoreProvider),
  ),
);

/// Real /v1/sync + /v1/ack transport.
final syncRepositoryProvider = Provider<SyncRepository>(
  (Ref ref) => SyncRepositoryImpl(ref.watch(apiClientProvider)),
);

final chatRepositoryProvider = Provider<ChatRepository>(
  (Ref ref) => ChatRepositoryImpl(
    ref.watch(contactDirectoryStoreProvider),
    ref.watch(e2eCryptoServiceProvider),
    ref.watch(messageStoreProvider),
    ref.watch(syncRepositoryProvider),
  ),
);

/// Drives both the outbound-retry and inbound pull/decrypt/ack
/// halves of real message delivery — see that class's doc comment.
/// Used by NotificationRouter (on a push hint) and by
/// connectivity/foreground triggers wired in app/app.dart.
final messageSyncCoordinatorProvider = Provider<MessageSyncCoordinator>(
  (Ref ref) => MessageSyncCoordinator(
    ref.watch(syncRepositoryProvider),
    ref.watch(e2eCryptoServiceProvider),
    ref.watch(messageStoreProvider),
  ),
);

final chatsProvider = FutureProvider<List<ChatSummary>>(
  (Ref ref) => ref.watch(chatRepositoryProvider).chats(),
);

/// This device's own display name + mailbox_id + identity public
/// keys, for the "My QR code" pairing screen. The identity keys are
/// included so the peer scanning this code can pin them locally
/// (ContactDirectoryStore) — without that, there's no way to later
/// resolve who sent a sealed-sender E2E message, since the envelope
/// never carries a mailbox_id, only identity public keys. A provider
/// (not an inline Future built in MyQrScreen.build()) so it's fetched
/// exactly once and cached, not re-fetched on every rebuild.
final myPairingInfoProvider = FutureProvider<
    ({String? name, String? mailboxId, String? ed25519Pub, String? x25519Pub})>(
  (Ref ref) async {
    final AuthRepository repo = ref.watch(authRepositoryProvider);
    final String? name = await repo.myDisplayName();
    final String? mailboxId = await repo.myMailboxId();
    final String? ed25519Pub =
        DeviceKeys.isUnlocked ? await DeviceKeys.ed25519PublicHex() : null;
    final String? x25519Pub =
        DeviceKeys.isUnlocked ? await DeviceKeys.x25519PublicHex() : null;
    return (
      name: name,
      mailboxId: mailboxId,
      ed25519Pub: ed25519Pub,
      x25519Pub: x25519Pub,
    );
  },
);
