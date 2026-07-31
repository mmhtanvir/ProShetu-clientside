import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import 'contact_directory_store.dart';

final contactDirectoryStoreProvider = Provider<ContactDirectoryStore>(
  (Ref ref) => ContactDirectoryStore(ref.watch(secureStorageProvider)),
);
