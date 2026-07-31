import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import 'blob_transport.dart';
import 'voice_player.dart';
import 'voice_recorder.dart';

final blobTransportProvider = Provider<BlobTransport>(
  (Ref ref) => BlobTransport(ref.watch(apiClientProvider)),
);

/// One recorder per app instance is enough — only one recording can
/// be in progress at a time. Kept alive for the app's lifetime rather
/// than autoDispose so an in-progress recording survives a rebuild.
final voiceRecorderProvider = Provider<VoiceRecorder>((Ref ref) {
  final VoiceRecorder recorder = VoiceRecorder();
  ref.onDispose(recorder.dispose);
  return recorder;
});

/// Shared across message bubbles — only one voice note can play at
/// once, which a single player instance gives for free.
final voicePlayerProvider = Provider<VoicePlayer>((Ref ref) {
  final VoicePlayer player = VoicePlayer();
  ref.onDispose(player.dispose);
  return player;
});
