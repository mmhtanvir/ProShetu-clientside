import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Records one voice note at a time to a local file. Playback is
/// [VoicePlayer]'s job; sending it to a peer still needs the same
/// mailbox-directory + E2E-encryption pieces documented elsewhere in
/// this codebase (infrastructure/crypto/e2e_placeholder.dart,
/// infrastructure/storage/contact_directory_store.dart) — this class
/// only gets a playable local recording onto disk.
class VoiceRecorder {
  final AudioRecorder _recorder = AudioRecorder();
  DateTime? _startedAt;

  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Live input level while recording, normalised to 0..1 for a UI
  /// meter. `Amplitude.current` is dBFS (roughly -45 quiet to 0 loud
  /// for speech) — the -45..0 floor below is a practical heuristic,
  /// not a calibrated measurement.
  Stream<double> get onAmplitudeChanged => _recorder
      .onAmplitudeChanged(const Duration(milliseconds: 150))
      .map((Amplitude a) => ((a.current + 45) / 45).clamp(0.0, 1.0));

  Future<void> start() async {
    final Directory dir = await getTemporaryDirectory();
    final String path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: path);
    _startedAt = DateTime.now();
  }

  /// Returns the recorded file path and its duration, or null if
  /// nothing was recording.
  Future<({String path, Duration duration})?> stop() async {
    final String? path = await _recorder.stop();
    final DateTime? started = _startedAt;
    _startedAt = null;
    if (path == null || started == null) return null;
    return (path: path, duration: DateTime.now().difference(started));
  }

  Future<void> cancel() async {
    await _recorder.cancel();
    _startedAt = null;
  }

  Future<bool> isRecording() => _recorder.isRecording();

  void dispose() => _recorder.dispose();
}
