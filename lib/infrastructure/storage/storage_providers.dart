import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../crypto/prekey_store.dart';
import '../crypto/session_store.dart';
import 'contact_directory_store.dart';
import 'message_store.dart';

final contactDirectoryStoreProvider = Provider<ContactDirectoryStore>(
  (Ref ref) => ContactDirectoryStore(ref.watch(secureStorageProvider)),
);

final prekeyStoreProvider = Provider<PrekeyStore>(
  (Ref ref) => PrekeyStore(ref.watch(secureStorageProvider)),
);

final sessionStoreProvider = Provider<SessionStore>(
  (Ref ref) => SessionStore(ref.watch(secureStorageProvider)),
);

final messageStoreProvider = Provider<MessageStore>((Ref ref) => MessageStore());
